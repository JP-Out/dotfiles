#!/usr/bin/env bash
# Shared helper functions for install scripts
set -euo pipefail

log() {
  echo "[install] $*"
}

copy_item() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp -rT "$src" "$dest"
}

make_executable() {
  chmod +x "$1"
}

enable_user_service() {
  local service="$1"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user enable --now "$service" >/dev/null 2>&1 || \
      log "Could not enable $service"
  else
    log "systemctl not available; skipped enabling $service"
  fi
}
