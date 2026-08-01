SHELL := /bin/sh

ROOT := $(abspath $(CURDIR)/..)
LOCAL_DIR := $(ROOT)/.local
PID_FILE := $(LOCAL_DIR)/seville.pid
LOG_FILE := $(LOCAL_DIR)/seville.log
BACKEND_BINARY := $(LOCAL_DIR)/seville-backend
FLUTTER_DIR := $(ROOT)/frontend/flutter

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
.PHONY: proto migrate-obsidian

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
			$(MAKE) --no-print-directory stop; \
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
	$(MAKE) --no-print-directory build; \
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
	@$(MAKE) --no-print-directory stop
	@$(MAKE) --no-print-directory start

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
	@set -eu; \
	tail_pid=''; \
	cleanup() { if [ -n "$$tail_pid" ]; then kill "$$tail_pid" 2>/dev/null || true; fi; }; \
	trap cleanup EXIT HUP INT TERM; \
	if [ "$(SEVILLE_NEO4J_QUERY_LOG)" = true ]; then \
		tail -n 0 -f "$(LOG_FILE)" & \
		tail_pid=$$!; \
	fi; \
	cd "$(FLUTTER_DIR)"; \
	expected_bundle_id='io.github.matey2010.seville'; \
	stale_macos_bundle=false; \
	for built_info_plist in \
		build/macos/Build/Products/Debug/seville.app/Contents/Info.plist \
		build/macos/Build/Products/Release/seville.app/Contents/Info.plist; do \
		if [ -f "$$built_info_plist" ] && \
			[ "$$(plutil -extract CFBundleIdentifier raw -o - "$$built_info_plist")" != "$$expected_bundle_id" ]; then \
			stale_macos_bundle=true; \
		fi; \
	done; \
	if [ "$$stale_macos_bundle" = true ]; then flutter clean; fi; \
	icon_config='flutter_launcher_icons.yaml'; \
	icon_source='assets/icons/macos/first-seville-icon.png'; \
	icon_output='macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png'; \
	if [ ! -f "$$icon_output" ] || [ "$$icon_config" -nt "$$icon_output" ] || [ "$$icon_source" -nt "$$icon_output" ]; then \
		dart run flutter_launcher_icons -f "$$icon_config"; \
	fi; \
	flutter run -d macos \
		--dart-define="SEVILLE_BASE_URL=$(SEVILLE_BASE_URL)" \
		--dart-define="SEVILLE_TOKEN=$(SEVILLE_TOKEN)" \
		--dart-define="SEVILLE_PLAYER_SLUG=$(SEVILLE_PLAYER_SLUG)"

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
