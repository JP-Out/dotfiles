#!/usr/bin/env bash
# Install dotfiles assets
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/assets-dotfiles"
DEST="$HOME/.local/share/dotfiles-assets"

log "Installing assets dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying assets"
copy_item "$SRC" "$DEST"

log "Assets installed"
