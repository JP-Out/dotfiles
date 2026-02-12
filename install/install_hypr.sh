#!/usr/bin/env bash
# Hyprland and related tools installation
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/hypr"
DEST="$HOME/.config/hypr"

log "Installing Hyprland dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying Hyprland configuration"
copy_item "$SRC/hyprland.conf" "$DEST/hyprland.conf"
copy_item "$SRC/hyprlock.conf" "$DEST/hyprlock.conf"
copy_item "$SRC/hyprpaper.conf" "$DEST/hyprpaper.conf"
copy_item "$SRC/scripts" "$DEST/scripts"
make_executable "$DEST/scripts/"*.sh

if [[ -f "$HOME/.config/systemd/user/hyprpaper-change.service" ]]; then
  enable_user_service hyprpaper-change.service
  enable_user_service hyprpaper-change.timer
fi

log "Hyprland configured"
