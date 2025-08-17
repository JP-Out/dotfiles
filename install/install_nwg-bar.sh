#!/usr/bin/env bash
# NWG-Bar installation and configuration
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/nwg-bar"
DEST="$HOME/.config/nwg-bar"

log "Installing NWG-Bar dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying NWG-Bar configuration"
copy_item "$SRC/bar.json" "$DEST/bar.json"
copy_item "$SRC/style.css" "$DEST/style.css"
copy_item "$SRC/icons" "$DEST/icons"

log "NWG-Bar configured"
