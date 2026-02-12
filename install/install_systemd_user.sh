#!/usr/bin/env bash
# Install systemd user services
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/systemd/user"
DEST="$HOME/.config/systemd/user"

log "Installing systemd user service dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying systemd user services"
mkdir -p "$DEST"
for unit in "$SRC"/*.service "$SRC"/*.timer; do
  [[ -e "$unit" ]] || continue
  copy_item "$unit" "$DEST/$(basename "$unit")"
  enable_user_service "$(basename "$unit")"
done

log "Systemd user services configured"
