#!/usr/bin/env bash
# KDE globals configuration
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/kdeglobals"
DEST="$HOME/.config/kdeglobals"

log "Installing KDE globals dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying kdeglobals"
copy_item "$SRC" "$DEST"

log "KDE globals configured"
