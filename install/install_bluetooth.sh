#!/usr/bin/env bash
# Bluetooth helper script installation
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/bluetooth/conectar_bluetooth.sh"
DEST="$HOME/.local/bin/conectar_bluetooth.sh"

log "Installing Bluetooth dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Installing Bluetooth helper script"
copy_item "$SRC" "$DEST"
make_executable "$DEST"

if [[ -f "$HOME/.config/systemd/user/bluetooth-autoconnect.service" ]]; then
  enable_user_service bluetooth-autoconnect.service
fi

log "Bluetooth utilities configured"
