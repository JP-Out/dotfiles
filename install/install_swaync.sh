#!/usr/bin/env bash
# Swaync installation and configuration
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/swaync"
DEST="$HOME/.config/swaync"

log "Installing Swaync dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying Swaync configuration"
copy_item "$SRC/config.json" "$DEST/config.json"
copy_item "$SRC/style.css" "$DEST/style.css"
copy_item "$SRC/buttons-grid" "$DEST/buttons-grid"
copy_item "$SRC/test" "$DEST/test"
make_executable "$DEST/test/"*.sh

log "Swaync configured"
