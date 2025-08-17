#!/usr/bin/env bash
# Grim and Slurp installation
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/grim/screenshot.sh"
DEST="$HOME/.local/bin/screenshot.sh"

log "Installing Grim/Slurp dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Installing screenshot script"
copy_item "$SRC" "$DEST"
make_executable "$DEST"

log "Grim and Slurp configured"
