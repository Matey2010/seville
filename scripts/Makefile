SHELL := /bin/sh

SCRIPTS_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
ROOT := $(abspath $(SCRIPTS_DIR)/..)
LOCAL_DIR := $(ROOT)/.local
PID_FILE := $(LOCAL_DIR)/seville.pid
LOG_FILE := $(LOCAL_DIR)/seville.log
BACKEND_BINARY := $(LOCAL_DIR)/seville-backend
FLUTTER_DIR := $(ROOT)/frontend/seville7

SEVILLE_ADDR ?= 127.0.0.1:8787
SEVILLE_BASE_URL ?= http://127.0.0.1:8787
SEVILLE_TOKEN ?= local-seville-token
SEVILLE_PLAYER_SLUG ?=
SEVILLE_NEO4J_URI ?= bolt://127.0.0.1:7687
SEVILLE_NEO4J_USERNAME ?= neo4j
SEVILLE_NEO4J_PASSWORD ?= seville-local-password
SEVILLE_NEO4J_DATABASE ?= neo4j
SEVILLE_NEO4J_QUERY_LOG ?= false

-include $(ROOT)/.env

export SEVILLE_ADDR SEVILLE_BASE_URL SEVILLE_TOKEN SEVILLE_PLAYER_SLUG
export SEVILLE_NEO4J_URI SEVILLE_NEO4J_USERNAME SEVILLE_NEO4J_PASSWORD
export SEVILLE_NEO4J_DATABASE SEVILLE_NEO4J_QUERY_LOG
export SEVILLE_SOURCE SEVILLE_VAULT_PATH SEVILLE_GIT_REPOSITORY_PATH
export SEVILLE_GIT_VAULT_SUBPATH

.DEFAULT_GOAL := help

.PHONY: help interface start build serve serve-built stop restart status logs
.PHONY: proto migrate-obsidian set-default-icon setDefaultIcon
.PHONY: build-font buildFont check-font checkFont
.PHONY: set-app-name setAppName generate-macos-app-names
.PHONY: generate-macos-icons generate-platform-icons

help:
	@echo "Seville commands"
	@echo "  make -C scripts interface          Start the complete macOS application"
	@echo "  make -C scripts start              Start Neo4j and the Go API"
	@echo "  make -C scripts status             Check the API and save its status"
	@echo "  make -C scripts stop               Stop the Go API"
	@echo "  make -C scripts restart            Restart the Go API"
	@echo "  make -C scripts logs               Follow the API log"
	@echo "  make -C scripts proto              Regenerate protobuf code"
	@echo "  make -C scripts migrate-obsidian   Run the manual vault migration"
	@echo "  make -C scripts buildFont          Build Sevifont from its SVG manifest"
	@echo "  make -C scripts checkFont          Validate Sevifont without writing output"
	@echo "  make -C scripts setDefaultIcon path=PATH"
	@echo "                                      Set Debug and production macOS icons"
	@echo "    or: debug_path=PATH production_path=PATH"
	@echo "                                      Set distinct macOS build icons"
	@echo "  make -C scripts setAppName name='Seville 7'"
	@echo "                                      Set Debug and production macOS names"
	@echo "    or: debug_name=NAME production_name=NAME"
	@echo "                                      Set distinct macOS build names"
	@echo "  make -C scripts generate-platform-icons"
	@echo "                                      Refresh future Android and iOS icons"

build:
	@mkdir -p "$(LOCAL_DIR)"
	@cd "$(ROOT)" && go build -o "$(BACKEND_BINARY)" ./backend/cmd/seville

start:
	@set -eu; \
	mkdir -p "$(LOCAL_DIR)"; \
	if [ -f "$(PID_FILE)" ] && kill -0 "$$(cat "$(PID_FILE)")" 2>/dev/null && \
		curl --fail --silent --max-time 1 "http://$(SEVILLE_ADDR)/healthz" >/dev/null 2>&1; then \
		if [ ! -x "$(BACKEND_BINARY)" ] || \
			find "$(ROOT)/backend" "$(ROOT)/proto/gen/go" \
				-type f \( -name '*.go' -o -name 'go.mod' -o -name 'go.sum' \) \
				-newer "$(BACKEND_BINARY)" -print -quit | grep -q .; then \
			echo "Backend sources changed; rebuilding Seville."; \
			$(MAKE) --no-print-directory -C "$(SCRIPTS_DIR)" stop; \
		else \
			echo "Seville is already running (PID $$(cat "$(PID_FILE)"))."; \
			exit 0; \
		fi; \
	fi; \
	if [ -f "$(PID_FILE)" ] && kill -0 "$$(cat "$(PID_FILE)")" 2>/dev/null; then \
		echo "Seville PID file exists, but the API is unhealthy; refusing to replace an unknown process." >&2; \
		echo "Inspect $(PID_FILE) and $(LOG_FILE), then run 'make -C scripts stop' if appropriate." >&2; \
		exit 1; \
	fi; \
	rm -f "$(PID_FILE)"; \
	case "$(SEVILLE_NEO4J_URI)" in \
		neo4j://127.0.0.1:*|neo4j://localhost:*|bolt://127.0.0.1:*|bolt://localhost:*) \
			if ! command -v docker >/dev/null 2>&1; then \
				echo "Local Neo4j is configured, but Docker is unavailable." >&2; \
				echo "Install/start Docker Desktop or set SEVILLE_NEO4J_URI to the remote database." >&2; \
				exit 1; \
			fi; \
			attempts=0; \
			while ! docker info >/dev/null 2>&1; do \
				attempts=$$((attempts + 1)); \
				if [ "$$attempts" -ge 30 ]; then \
					echo "Docker Desktop is installed, but its engine did not become ready within 30 seconds." >&2; \
					docker info >&2 || true; \
					exit 1; \
				fi; \
				if [ "$$attempts" -eq 1 ]; then echo "Waiting for the Docker Desktop engine..."; fi; \
				sleep 1; \
			done; \
			cd "$(ROOT)" && docker compose up --detach neo4j; \
			;; \
	esac; \
	$(MAKE) --no-print-directory -C "$(SCRIPTS_DIR)" build; \
	nohup "$(BACKEND_BINARY)" >>"$(LOG_FILE)" 2>&1 & \
	echo $$! >"$(PID_FILE)"; \
	attempts=0; \
	while [ "$$attempts" -lt 45 ]; do \
		if curl --fail --silent --max-time 1 "http://$(SEVILLE_ADDR)/healthz" >/dev/null 2>&1; then \
			echo "Seville started at http://$(SEVILLE_ADDR)"; \
			echo "Log: $(LOG_FILE)"; \
			exit 0; \
		fi; \
		if ! kill -0 "$$(cat "$(PID_FILE)")" 2>/dev/null; then \
			rm -f "$(PID_FILE)"; \
			echo "Seville did not start. Check $(LOG_FILE)" >&2; \
			exit 1; \
		fi; \
		attempts=$$((attempts + 1)); \
		sleep 1; \
	done; \
	echo "Seville API did not become healthy within 45 seconds. Check $(LOG_FILE)" >&2; \
	exit 1

serve: build
	@cd "$(ROOT)" && exec "$(BACKEND_BINARY)"

serve-built:
	@if [ ! -x "$(BACKEND_BINARY)" ]; then \
		echo "Seville backend is not built; run 'make -C scripts build' first." >&2; \
		exit 1; \
	fi
	@cd "$(ROOT)" && exec "$(BACKEND_BINARY)"

stop:
	@set -eu; \
	if [ ! -f "$(PID_FILE)" ] || ! kill -0 "$$(cat "$(PID_FILE)")" 2>/dev/null; then \
		rm -f "$(PID_FILE)"; \
		echo "Seville is not running."; \
		exit 0; \
	fi; \
	pid=$$(cat "$(PID_FILE)"); \
	kill "$$pid"; \
	rm -f "$(PID_FILE)"; \
	echo "Seville stopped."

restart:
	@$(MAKE) --no-print-directory -C "$(SCRIPTS_DIR)" stop
	@$(MAKE) --no-print-directory -C "$(SCRIPTS_DIR)" start

status:
	@set -eu; \
	if [ ! -f "$(PID_FILE)" ] || ! kill -0 "$$(cat "$(PID_FILE)")" 2>/dev/null || \
		! curl --fail --silent --max-time 1 "http://$(SEVILLE_ADDR)/healthz" >/dev/null 2>&1; then \
		echo "Seville API is not running or unhealthy."; \
		exit 1; \
	fi; \
	echo "Seville process is running (PID $$(cat "$(PID_FILE)"))."; \
	curl --fail --silent --show-error \
		-H "Authorization: Bearer $(SEVILLE_TOKEN)" \
		"http://$(SEVILLE_ADDR)/v2/status" \
		--output "$(LOCAL_DIR)/status.pb"; \
	echo "API is healthy. Protobuf status saved to .local/status.pb"

logs:
	@mkdir -p "$(LOCAL_DIR)"
	@touch "$(LOG_FILE)"
	@tail -n 80 -f "$(LOG_FILE)"

interface: start
	@$(MAKE) --no-print-directory -C "$(SCRIPTS_DIR)" generate-macos-icons
	@$(MAKE) --no-print-directory -C "$(SCRIPTS_DIR)" generate-macos-app-names
	@set -eu; \
	tail_pid=''; \
	cleanup() { if [ -n "$$tail_pid" ]; then kill "$$tail_pid" 2>/dev/null || true; fi; }; \
	trap cleanup EXIT HUP INT TERM; \
	if [ "$(SEVILLE_NEO4J_QUERY_LOG)" = true ]; then \
		tail -n 0 -f "$(LOG_FILE)" & \
		tail_pid=$$!; \
	fi; \
	cd "$(FLUTTER_DIR)"; \
	stale_macos_bundle=false; \
	debug_info_plist='build/macos/Build/Products/Debug/seville.app/Contents/Info.plist'; \
	release_info_plist='build/macos/Build/Products/Release/seville.app/Contents/Info.plist'; \
	if [ -f "$$debug_info_plist" ] && \
		[ "$$(plutil -extract CFBundleIdentifier raw -o - "$$debug_info_plist")" != 'io.github.matey2010.seville.debug' ]; then \
		stale_macos_bundle=true; \
	fi; \
	if [ -f "$$release_info_plist" ] && \
		[ "$$(plutil -extract CFBundleIdentifier raw -o - "$$release_info_plist")" != 'io.github.matey2010.seville' ]; then \
		stale_macos_bundle=true; \
	fi; \
	if [ "$$stale_macos_bundle" = true ]; then flutter clean; fi; \
	flutter run -d macos \
		--dart-define="SEVILLE_BASE_URL=$(SEVILLE_BASE_URL)" \
		--dart-define="SEVILLE_TOKEN=$(SEVILLE_TOKEN)" \
		--dart-define="SEVILLE_PLAYER_SLUG=$(SEVILLE_PLAYER_SLUG)"

setDefaultIcon: set-default-icon

set-default-icon:
	@set -eu; \
	icon_path='$(if $(path),$(path),$(ICON_PATH))'; \
	debug_path='$(debug_path)'; \
	production_path='$(production_path)'; \
	if [ -n "$$icon_path" ]; then \
		debug_path="$$icon_path"; \
		production_path="$$icon_path"; \
	elif [ -z "$$debug_path" ] || [ -z "$$production_path" ]; then \
		echo "Usage: make -C scripts setDefaultIcon path=./frontend/seville7/assets/legal/mascot-ska.png" >&2; \
		echo "   or: make -C scripts setDefaultIcon debug_path=PATH production_path=PATH" >&2; \
		exit 64; \
	fi; \
	flutter_root=$$(cd "$(FLUTTER_DIR)" && pwd -P); \
	resolve_source() { \
		requested=$$1; \
		case "$$requested" in \
			*\"*|*\\*) \
				echo "Icon source paths cannot contain quotes or backslashes: $$requested" >&2; \
				return 65; \
				;; \
		esac; \
		case "$$requested" in \
			/*) candidate="$$requested" ;; \
			*) \
				if [ -f "$$flutter_root/$$requested" ]; then \
					candidate="$$flutter_root/$$requested"; \
				else \
					candidate="$(ROOT)/$$requested"; \
				fi \
				;; \
		esac; \
		if [ ! -f "$$candidate" ]; then \
			echo "Icon source does not exist: $$requested" >&2; \
			return 66; \
		fi; \
		resolved_dir=$$(cd "$$(dirname "$$candidate")" && pwd -P); \
		resolved="$$resolved_dir/$$(basename "$$candidate")"; \
		case "$$resolved" in \
			"$$flutter_root"/*) printf '%s\n' "$${resolved#"$$flutter_root"/}" ;; \
			*) \
				echo "Icon source must be inside the Flutter project: $$flutter_root" >&2; \
				return 65; \
				;; \
		esac; \
	}; \
	debug_source=$$(resolve_source "$$debug_path"); \
	production_source=$$(resolve_source "$$production_path"); \
	config="$$flutter_root/macos_launcher_icons.yaml"; \
	config_tmp=$$(mktemp "$$config.tmp.XXXXXX"); \
	trap 'rm -f "$$config_tmp"' EXIT HUP INT TERM; \
	awk -v debug="$$debug_source" -v production="$$production_source" ' \
		/^  debug_image_path:/ { print "  debug_image_path: \"" debug "\""; found_debug = 1; next } \
		/^  production_image_path:/ { print "  production_image_path: \"" production "\""; found_production = 1; next } \
		{ print } \
		END { if (!found_debug || !found_production) exit 65 } \
	' "$$config" >"$$config_tmp"; \
	if cmp -s "$$config_tmp" "$$config"; then \
		rm -f "$$config_tmp"; \
	else \
		mv "$$config_tmp" "$$config"; \
	fi; \
	trap - EXIT HUP INT TERM; \
	echo "Debug macOS icon source: $$debug_source"; \
	echo "Production macOS icon source: $$production_source"
	@$(MAKE) --no-print-directory -C "$(SCRIPTS_DIR)" generate-macos-icons

setAppName: set-app-name

set-app-name:
	@set -eu; \
	app_name='$(if $(name),$(name),$(APP_NAME))'; \
	debug_name='$(debug_name)'; \
	production_name='$(production_name)'; \
	if [ -n "$$app_name" ]; then \
		debug_name="$$app_name"; \
		production_name="$$app_name"; \
	elif [ -z "$$debug_name" ] || [ -z "$$production_name" ]; then \
		echo "Usage: make -C scripts setAppName name='Seville 7'" >&2; \
		echo "   or: make -C scripts setAppName debug_name=NAME production_name=NAME" >&2; \
		exit 64; \
	fi; \
	validate_name() { \
		variant=$$1; \
		candidate=$$2; \
		case "$$candidate" in \
			*\"*|*\\*|*\#*|*'$$'*) \
				echo "$$variant app name cannot contain quotes, backslashes, #, or a dollar sign: $$candidate" >&2; \
				return 65; \
				;; \
		esac; \
	}; \
	validate_name Debug "$$debug_name"; \
	validate_name Production "$$production_name"; \
	config="$(FLUTTER_DIR)/macos_app_names.yaml"; \
	config_tmp=$$(mktemp "$$config.tmp.XXXXXX"); \
	trap 'rm -f "$$config_tmp"' EXIT HUP INT TERM; \
	{ \
		printf '%s\n' 'macos_app_names:'; \
		printf '  debug_name: "%s"\n' "$$debug_name"; \
		printf '  production_name: "%s"\n' "$$production_name"; \
	} >"$$config_tmp"; \
	if cmp -s "$$config_tmp" "$$config"; then \
		rm -f "$$config_tmp"; \
	else \
		mv "$$config_tmp" "$$config"; \
	fi; \
	trap - EXIT HUP INT TERM; \
	cd "$(FLUTTER_DIR)"; \
	dart run rename_app:main "mac=$$debug_name"; \
	if [ "$$production_name" != "$$debug_name" ]; then \
		dart run rename_app:main "mac=$$production_name"; \
	fi; \
	echo "Debug macOS app name: $$debug_name"; \
	echo "Production macOS app name: $$production_name"
	@$(MAKE) --no-print-directory -C "$(SCRIPTS_DIR)" generate-macos-app-names

generate-macos-app-names:
	@set -eu; \
	cd "$(FLUTTER_DIR)"; \
	config='macos_app_names.yaml'; \
	output='macos/Runner/Configs/AppName.xcconfig'; \
	debug_name=$$(awk -F '"' '/^  debug_name:/ { print $$2; exit }' "$$config"); \
	production_name=$$(awk -F '"' '/^  production_name:/ { print $$2; exit }' "$$config"); \
	if [ -z "$$debug_name" ] || [ -z "$$production_name" ]; then \
		echo "macos_app_names.yaml must define non-empty debug_name and production_name values." >&2; \
		exit 65; \
	fi; \
	previous_debug=$$(awk -F ' = ' '/^SEVILLE_DEBUG_APP_NAME =/ { print $$2; exit }' "$$output" 2>/dev/null || true); \
	previous_production=$$(awk -F ' = ' '/^SEVILLE_PRODUCTION_APP_NAME =/ { print $$2; exit }' "$$output" 2>/dev/null || true); \
	output_tmp=$$(mktemp "$$output.tmp.XXXXXX"); \
	trap 'rm -f "$$output_tmp"' EXIT HUP INT TERM; \
	{ \
		printf '%s\n' '// Generated by `make -C scripts generate-macos-app-names`.'; \
		printf '%s\n' '// Change macos_app_names.yaml through `make -C scripts setAppName` instead.'; \
		printf 'SEVILLE_DEBUG_APP_NAME = %s\n' "$$debug_name"; \
		printf 'SEVILLE_PRODUCTION_APP_NAME = %s\n' "$$production_name"; \
		printf '%s\n' 'SEVILLE_APP_NAME = $$(SEVILLE_PRODUCTION_APP_NAME)'; \
		printf '%s\n' 'SEVILLE_APP_NAME[config=Debug] = $$(SEVILLE_DEBUG_APP_NAME)'; \
	} >"$$output_tmp"; \
	if cmp -s "$$output_tmp" "$$output"; then \
		rm -f "$$output_tmp"; \
	else \
		mv "$$output_tmp" "$$output"; \
		if [ "$$previous_debug" != "$$debug_name" ]; then \
			debug_bundle='build/macos/Build/Products/Debug/seville.app'; \
			if [ -d "$$debug_bundle" ]; then \
				rm -R "$$debug_bundle"; \
				echo "Removed stale generated Debug bundle: $$debug_bundle"; \
			fi; \
		fi; \
		if [ "$$previous_production" != "$$production_name" ]; then \
			for production_bundle in \
				build/macos/Build/Products/Profile/seville.app \
				build/macos/Build/Products/Release/seville.app; do \
				if [ -d "$$production_bundle" ]; then \
					rm -R "$$production_bundle"; \
					echo "Removed stale generated production bundle: $$production_bundle"; \
				fi; \
			done; \
		fi; \
	fi; \
	trap - EXIT HUP INT TERM

generate-macos-icons:
	@set -eu; \
	cd "$(FLUTTER_DIR)"; \
	config='macos_launcher_icons.yaml'; \
	tool='tool/generate_macos_icons.swift'; \
	debug_source=$$(awk -F '"' '/^  debug_image_path:/ { print $$2; exit }' "$$config"); \
	production_source=$$(awk -F '"' '/^  production_image_path:/ { print $$2; exit }' "$$config"); \
	if [ -z "$$debug_source" ] || [ ! -f "$$debug_source" ]; then \
		echo "Configured Debug macOS icon does not exist: $$debug_source" >&2; \
		exit 66; \
	fi; \
	if [ -z "$$production_source" ] || [ ! -f "$$production_source" ]; then \
		echo "Configured production macOS icon does not exist: $$production_source" >&2; \
		exit 66; \
	fi; \
	debug_output='macos/Runner/Assets.xcassets/AppIcon-Debug.appiconset'; \
	production_output='macos/Runner/Assets.xcassets/AppIcon.appiconset'; \
	debug_master="$$debug_output/app_icon_1024.png"; \
	production_master="$$production_output/app_icon_1024.png"; \
	debug_changed=false; \
	production_changed=false; \
	if [ ! -f "$$debug_master" ] || [ "$$config" -nt "$$debug_master" ] || [ "$$tool" -nt "$$debug_master" ] || [ "$$debug_source" -nt "$$debug_master" ]; then \
		swift "$$tool" --source "$$debug_source" --output "$$debug_output"; \
		debug_changed=true; \
	fi; \
	if [ ! -f "$$production_master" ] || [ "$$config" -nt "$$production_master" ] || [ "$$tool" -nt "$$production_master" ] || [ "$$production_source" -nt "$$production_master" ]; then \
		swift "$$tool" --source "$$production_source" --output "$$production_output"; \
		production_changed=true; \
	fi; \
	if [ "$$debug_changed" = true ]; then \
		debug_bundle='build/macos/Build/Products/Debug/seville.app'; \
		if [ -d "$$debug_bundle" ]; then \
			rm -R "$$debug_bundle"; \
			echo "Removed stale generated Debug bundle: $$debug_bundle"; \
		fi; \
	fi; \
	if [ "$$production_changed" = true ]; then \
		for production_bundle in \
			build/macos/Build/Products/Profile/seville.app \
			build/macos/Build/Products/Release/seville.app; do \
			if [ -d "$$production_bundle" ]; then \
				rm -R "$$production_bundle"; \
				echo "Removed stale generated production bundle: $$production_bundle"; \
			fi; \
		done; \
	fi

generate-platform-icons: generate-macos-icons
	@set -eu; \
	cd "$(FLUTTER_DIR)"; \
	dart run flutter_launcher_icons -f flutter_launcher_icons.yaml; \
	sed -i.bak 's/ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon;/ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;/g' ios/Runner.xcodeproj/project.pbxproj; \
	rm -f ios/Runner.xcodeproj/project.pbxproj.bak

buildFont: build-font

build-font:
	@set -eu; \
	if ! command -v fontforge >/dev/null 2>&1; then \
		echo "FontForge is required. Install it with: brew install fontforge" >&2; \
		exit 69; \
	fi; \
	font_manifest='$(if $(manifest),$(manifest),$(FLUTTER_DIR)/assets/fonts/sevifont/sevifont.font.json)'; \
	case "$$font_manifest" in /*) ;; *) font_manifest="$(ROOT)/$$font_manifest" ;; esac; \
	fontforge -lang=py -script "$(SCRIPTS_DIR)/fonts/build_font.py" "$$font_manifest"

checkFont: check-font

check-font:
	@set -eu; \
	if ! command -v fontforge >/dev/null 2>&1; then \
		echo "FontForge is required. Install it with: brew install fontforge" >&2; \
		exit 69; \
	fi; \
	font_manifest='$(if $(manifest),$(manifest),$(FLUTTER_DIR)/assets/fonts/sevifont/sevifont.font.json)'; \
	case "$$font_manifest" in /*) ;; *) font_manifest="$(ROOT)/$$font_manifest" ;; esac; \
	fontforge -lang=py -script "$(SCRIPTS_DIR)/fonts/build_font.py" "$$font_manifest" --check

proto:
	@cd "$(ROOT)" && protoc \
		--proto_path=proto \
		--go_out=proto/gen/go \
		--go_opt=paths=source_relative \
		--dart_out=proto/gen/dart/lib/src \
		proto/seville/node/v2/node.proto \
		proto/seville/nodes/v1/tree.proto \
		proto/seville/notification/v1/notification.proto \
		proto/seville/system/v1/system.proto

migrate-obsidian:
	@cd "$(ROOT)" && go run ./backend/cmd/migrate-obsidian-vault
