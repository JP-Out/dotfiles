#!/usr/bin/env bash
# Rofi installation and configuration
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/rofi"
DEST="$HOME/.config/rofi"

log "Installing Rofi dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying Rofi configuration"
copy_item "$SRC/config.rasi" "$DEST/config.rasi"
copy_item "$SRC/launchers" "$DEST/launchers"
copy_item "$SRC/themes" "$DEST/themes"

log "Rofi configured"
