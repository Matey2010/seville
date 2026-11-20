#!/bin/bash
# Seville Neo4j backups: encrypted offline dumps of the Compose neo4j volume.
#
#   backup.sh setup            create the age key and backup folder
#   backup.sh backup           dump, encrypt to the backup folder, prune
#   backup.sh verify [FILE]    restore FILE (default: newest) into a throwaway
#                              container and report Node counts; live data is
#                              never touched
#   backup.sh restore FILE     replace the live database with FILE (asks first)
#   backup.sh schedule         build the "Seville Backup" app and a daily
#                              launchd job that opens it
#   backup.sh unschedule       remove that job
#
# Configuration (environment, or the SEVILLE_BACKUP_* / SEVILLE_NEO4J_DATABASE
# lines of the repository .env, read without shell evaluation):
#   SEVILLE_BACKUP_DIR       destination folder (an external drive)
#   SEVILLE_BACKUP_AGE_KEY   age identity file; never store it on the drive
#   SEVILLE_BACKUP_KEEP      newest backups to keep (default 14); the first
#                            backup of each of the last 12 months is also kept
#   SEVILLE_BACKUP_HOUR      daily run hour for `schedule` (default 4)
#   SEVILLE_NEO4J_DATABASE   database to dump (default neo4j)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Scheduled runs start from an app with a minimal PATH.
PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin"

# Fill unset backup settings from .env. Only plain KEY=VALUE lines for these
# keys are read; nothing is evaluated, so other secrets in .env stay untouched.
if [ -f "$ROOT/.env" ]; then
  while IFS='=' read -r key value; do
    case "$key" in
      SEVILLE_BACKUP_DIR | SEVILLE_BACKUP_AGE_KEY | SEVILLE_BACKUP_KEEP | SEVILLE_BACKUP_HOUR | SEVILLE_NEO4J_DATABASE)
        if [ -z "${!key:-}" ]; then
          value="${value%\"}" && value="${value#\"}"
          export "$key=$value"
        fi ;;
    esac
  done < <(grep -E '^SEVILLE_(BACKUP_[A-Z_]+|NEO4J_DATABASE)=' "$ROOT/.env" || true)
fi

BACKUP_DIR="${SEVILLE_BACKUP_DIR:-/Volumes/Memoria/Backups/seville}"
AGE_KEY="${SEVILLE_BACKUP_AGE_KEY:-$HOME/.config/seville/backup-age-key.txt}"
KEEP="${SEVILLE_BACKUP_KEEP:-14}"
DATABASE="${SEVILLE_NEO4J_DATABASE:-neo4j}"
STATE_FILE="$(dirname "$AGE_KEY")/last-backup"
HOUR="${SEVILLE_BACKUP_HOUR:-4}"
AGENT_LABEL="io.github.matey2010.seville.backup"
AGENT_PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"
AGENT_LOG="$HOME/Library/Logs/seville-backup.log"
# macOS grants removable-volume access per app; this app is what you allow.
AGENT_APP="$HOME/Applications/Seville Backup.app"
STALE_DAYS=3
PREFIX="seville-neo4j-"
SUFFIX=".dump.age"

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
notify() {
  osascript -e "display notification \"$1\" with title \"Seville backup\"" >/dev/null 2>&1 || true
}
fail() { log "ERROR: $*"; notify "Failed: $*"; exit 1; }

compose() { docker compose --project-directory "$ROOT" -f "$ROOT/compose.yaml" "$@"; }

require_tools() {
  command -v age >/dev/null || fail "age is not installed (brew install age)"
  command -v docker >/dev/null || fail "docker is not on PATH"
  docker info >/dev/null 2>&1 || fail "Docker is not running"
}

recipient() {
  [ -f "$AGE_KEY" ] || fail "age key missing at $AGE_KEY; run: make -C scripts backup-setup"
  age-keygen -y "$AGE_KEY"
}

list_backups() {
  find "$BACKUP_DIR" -maxdepth 1 -type f -name "$PREFIX*$SUFFIX" 2>/dev/null | sort || true
}

newest_backup() {
  list_backups | tail -n 1
}

# True when BACKUP_DIR is not on /Volumes, or its volume is mounted.
drive_connected() {
  case "$BACKUP_DIR" in
    /Volumes/*)
      local mount_point
      mount_point="/Volumes/$(printf '%s' "${BACKUP_DIR#/Volumes/}" | cut -d/ -f1)"
      mount | grep -qF " on $mount_point (" ;;
    *) return 0 ;;
  esac
}

# Warn when the last successful backup (recorded locally) is too old.
check_staleness() {
  if [ ! -f "$STATE_FILE" ]; then
    notify "No Seville backup has run yet. Connect the backup drive."
  elif [ -n "$(find "$STATE_FILE" -mtime +"$STALE_DAYS" 2>/dev/null)" ]; then
    notify "Last Seville backup is over $STALE_DAYS days old. Connect the backup drive."
  fi
}

# Neo4j container, its image, and its data volume.
inspect_neo4j() {
  CONTAINER="$(compose ps -aq neo4j)"
  [ -n "$CONTAINER" ] || fail "no neo4j container; start Seville once first"
  IMAGE="$(docker inspect -f '{{.Config.Image}}' "$CONTAINER")"
  VOLUME="$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Name}}{{end}}{{end}}' "$CONTAINER")"
  [ -n "$VOLUME" ] || fail "neo4j container has no /data volume"
  WAS_RUNNING="$(docker inspect -f '{{.State.Running}}' "$CONTAINER")"
}

# Everything that must be undone on any exit lives in globals, so the EXIT
# trap still sees it after the function that created it has returned.
WORK=""             # private temp folder; may hold a plaintext dump
PARTIAL=""          # half-written encrypted file on the backup drive
THROWAWAY=""        # verify container and volume name
RESTART_NEO4J=false # live Neo4j was stopped and must be started again

cleanup() {
  if [ "$RESTART_NEO4J" = "true" ]; then
    compose start neo4j >/dev/null 2>&1 || log "WARNING: could not restart neo4j"
  fi
  if [ -n "$THROWAWAY" ]; then
    docker rm -f "$THROWAWAY" >/dev/null 2>&1 || true
    docker volume rm "$THROWAWAY" >/dev/null 2>&1 || true
  fi
  if [ -n "$PARTIAL" ]; then rm -f "$PARTIAL"; fi
  remove_work
}
trap cleanup EXIT

remove_work() {
  if [ -n "$WORK" ] && [ -d "$WORK" ]; then
    rm -f "$WORK/$DATABASE.dump" "$WORK/dump.log"
    rmdir "$WORK" 2>/dev/null || true
  fi
  WORK=""
}

stop_neo4j() {
  if [ "$WAS_RUNNING" = "true" ]; then
    RESTART_NEO4J=true
    compose stop neo4j >/dev/null
  fi
}

start_neo4j() {
  if [ "$RESTART_NEO4J" = "true" ]; then
    compose start neo4j >/dev/null
    RESTART_NEO4J=false
  fi
}

# Sets WORK to a new private temp folder (call directly, not in $(...)).
make_work() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/seville-backup.XXXXXX")"
  chmod 700 "$WORK"
}

cmd_setup() {
  command -v age-keygen >/dev/null || fail "age is not installed (brew install age)"
  if [ -f "$AGE_KEY" ]; then
    log "age key already exists: $AGE_KEY"
  else
    mkdir -p "$(dirname "$AGE_KEY")"
    chmod 700 "$(dirname "$AGE_KEY")"
    (umask 077 && age-keygen -o "$AGE_KEY" 2>/dev/null)
    log "created age key: $AGE_KEY"
    log "SAVE A COPY OF THIS FILE IN YOUR PASSWORD MANAGER. Without it, backups cannot be restored."
  fi
  log "public recipient: $(recipient)"
  if mkdir -p "$BACKUP_DIR" 2>/dev/null; then
    log "backup folder ready: $BACKUP_DIR"
  else
    log "backup folder not writable yet: $BACKUP_DIR (is the drive connected?)"
  fi
}

prune() {
  local all keep_recent keep_monthly
  all="$(list_backups)"
  [ -n "$all" ] || return 0
  keep_recent="$(printf '%s\n' "$all" | tail -n "$KEEP")"
  # First backup of each month (name: PREFIX + YYYYMMDD-HHMMSS), last 12 months.
  keep_monthly="$(printf '%s\n' "$all" | awk -v p="$PREFIX" '{
      n = $0; sub(/.*\//, "", n); m = substr(n, length(p) + 1, 6)
      if (!(m in seen)) { seen[m] = 1; print }
    }' | tail -n 12)"
  printf '%s\n' "$all" | while IFS= read -r file; do
    if ! printf '%s\n%s\n' "$keep_recent" "$keep_monthly" | grep -qxF "$file"; then
      rm -f "$file"
      log "pruned $(basename "$file")"
    fi
  done
}

cmd_backup() {
  if ! drive_connected; then
    log "backup drive not connected ($BACKUP_DIR); skipped"
    check_staleness
    exit 0
  fi
  require_tools
  local rcpt name probe
  rcpt="$(recipient)"
  mkdir -p "$BACKUP_DIR" 2>/dev/null || true
  # Probe before stopping Neo4j: under launchd, macOS privacy rules can refuse
  # writes to removable volumes without showing a prompt.
  probe="$BACKUP_DIR/.write-test.$$"
  if ! { : >"$probe" && rm -f "$probe"; } 2>/dev/null; then
    fail "cannot write to $BACKUP_DIR. Grant Full Disk Access to /usr/bin/make (System Settings > Privacy & Security)"
  fi
  inspect_neo4j
  make_work
  name="$PREFIX$(date '+%Y%m%d-%H%M%S')$SUFFIX"

  log "stopping neo4j (running: $WAS_RUNNING) to dump $DATABASE from $VOLUME"
  stop_neo4j
  if ! docker run --rm -v "$VOLUME:/data" -v "$WORK:/backups" "$IMAGE" \
      neo4j-admin database dump "$DATABASE" --to-path=/backups >"$WORK/dump.log" 2>&1; then
    cat "$WORK/dump.log"
    fail "neo4j-admin dump failed"
  fi
  start_neo4j
  log "neo4j restarted; encrypting"

  PARTIAL="$BACKUP_DIR/.$name.partial"
  age -r "$rcpt" -o "$PARTIAL" "$WORK/$DATABASE.dump"
  mv "$PARTIAL" "$BACKUP_DIR/$name"
  PARTIAL=""
  remove_work
  log "wrote $BACKUP_DIR/$name ($(du -h "$BACKUP_DIR/$name" | cut -f1))"
  date '+%Y-%m-%d %H:%M:%S' >"$STATE_FILE"
  prune
}

# Decrypts FILE into a new WORK folder as $DATABASE.dump.
decrypt_to_work() {
  [ -f "$AGE_KEY" ] || fail "age key missing at $AGE_KEY"
  make_work
  age -d -i "$AGE_KEY" -o "$WORK/$DATABASE.dump" "$1" || fail "decryption failed"
}

# Loads WORK/$DATABASE.dump into volume $1; prints neo4j-admin output only on failure.
load_dump() {
  local output
  if ! output="$(docker run --rm -v "$1:/data" -v "$WORK:/backups" "$IMAGE" \
      neo4j-admin database load "$DATABASE" --from-path=/backups --overwrite-destination=true 2>&1)"; then
    printf '%s\n' "$output" | tail -n 20
    fail "neo4j-admin load failed"
  fi
}

cmd_verify() {
  require_tools
  local file="${1:-$(newest_backup || true)}"
  [ -n "$file" ] && [ -f "$file" ] || fail "no backup file to verify"
  inspect_neo4j
  local counts
  decrypt_to_work "$file"
  THROWAWAY="seville-backup-verify-$$"

  log "loading $(basename "$file") into throwaway volume $THROWAWAY"
  docker volume create "$THROWAWAY" >/dev/null
  load_dump "$THROWAWAY"
  remove_work
  docker run -d --name "$THROWAWAY" -e NEO4J_AUTH=none -v "$THROWAWAY:/data" "$IMAGE" >/dev/null

  local tries=0
  until docker exec "$THROWAWAY" cypher-shell -d "$DATABASE" "RETURN 1" >/dev/null 2>&1; do
    tries=$((tries + 1))
    [ "$tries" -lt 60 ] || fail "restored database did not start"
    sleep 2
  done
  counts="$(docker exec "$THROWAWAY" cypher-shell -d "$DATABASE" --format plain \
    "MATCH (n:Node) WITH count(n) AS nodes
     OPTIONAL MATCH ()-[r:LINKS_TO]->() WITH nodes, count(r) AS links
     OPTIONAL MATCH (rule:ObsivilianColorRule) RETURN nodes, links, count(rule) AS color_rules")"
  log "restore OK: $(printf '%s' "$counts" | tail -n 1) (nodes, links, color_rules)"
}

cmd_restore() {
  require_tools
  local file="${1:-}"
  [ -n "$file" ] && [ -f "$file" ] || fail "usage: backup.sh restore FILE"
  printf 'This REPLACES the live Seville database with %s.\nA fresh backup is taken first. Type "restore" to continue: ' "$(basename "$file")"
  local answer
  read -r answer
  [ "$answer" = "restore" ] || { log "cancelled"; exit 1; }
  drive_connected || fail "backup drive not connected; the safety backup needs it"
  cmd_backup
  inspect_neo4j
  decrypt_to_work "$file"
  stop_neo4j
  load_dump "$VOLUME"
  remove_work
  start_neo4j
  log "restored $(basename "$file"); restart the Go API: make -C scripts restart"
}

# launchd runs a missed calendar slot once the Mac wakes.
# Builds a background AppleScript app that runs `backup.sh backup`. Processes
# it starts inherit its privacy permissions, so one "Allow" covers bash, mv,
# rm, and age. The app is rebuilt only when its source changes, because a
# rebuild changes its signature and macOS would ask again.
build_app() {
  local source marker
  source="try
  do shell script \"/bin/bash \" & quoted form of \"$ROOT/scripts/backup.sh\" & \" backup >> \" & quoted form of \"$AGENT_LOG\" & \" 2>&1\"
end try"
  marker="$AGENT_APP/Contents/Resources/seville-source.applescript"
  if [ -f "$marker" ] && [ "$(cat "$marker")" = "$source" ]; then
    log "app unchanged: $AGENT_APP"
    return
  fi
  case "$AGENT_APP" in */"Seville Backup.app") ;; *) fail "unexpected app path $AGENT_APP" ;; esac
  [ ! -d "$AGENT_APP" ] || rm -rf "$AGENT_APP"
  mkdir -p "$(dirname "$AGENT_APP")"
  osacompile -o "$AGENT_APP" -e "$source"
  printf '%s' "$source" >"$marker"
  local info="$AGENT_APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $AGENT_LABEL.app" "$info" 2>/dev/null ||
    /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $AGENT_LABEL.app" "$info"
  /usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$info" 2>/dev/null || true
  codesign --force --sign - "$AGENT_APP" 2>/dev/null
  log "built $AGENT_APP"
}

cmd_schedule() {
  case "$HOUR" in [0-9] | 1[0-9] | 2[0-3]) ;; *) fail "SEVILLE_BACKUP_HOUR must be 0-23" ;; esac
  mkdir -p "$(dirname "$AGENT_PLIST")" "$(dirname "$AGENT_LOG")"
  build_app
  cat >"$AGENT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$AGENT_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/open</string><string>-W</string><string>-g</string><string>-j</string><string>$AGENT_APP</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>$AGENT_LOG</string>
  <key>StandardErrorPath</key><string>$AGENT_LOG</string>
</dict>
</plist>
PLIST
  plutil -lint "$AGENT_PLIST" >/dev/null
  launchctl bootout "gui/$(id -u)/$AGENT_LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$AGENT_PLIST"
  log "daily backup scheduled at $HOUR:00; log: $AGENT_LOG"
  log "run it now: launchctl kickstart gui/$(id -u)/$AGENT_LABEL"
  log "on the first run, allow \"Seville Backup\" to access removable volumes"
}

cmd_unschedule() {
  launchctl bootout "gui/$(id -u)/$AGENT_LABEL" 2>/dev/null || true
  [ ! -f "$AGENT_PLIST" ] || mv "$AGENT_PLIST" "$AGENT_PLIST.disabled"
  log "daily backup unscheduled"
}

case "${1:-}" in
  setup) cmd_setup ;;
  backup) cmd_backup ;;
  verify) shift; cmd_verify "${1:-}" ;;
  restore) shift; cmd_restore "${1:-}" ;;
  schedule) cmd_schedule ;;
  unschedule) cmd_unschedule ;;
  *) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
