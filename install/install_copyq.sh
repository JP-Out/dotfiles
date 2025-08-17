#!/usr/bin/env bash
# CopyQ installation and configuration
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/copyq"
DEST="$HOME/.config/copyq"

log "Installing CopyQ dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying CopyQ configuration"
copy_item "$SRC/copyq.conf" "$DEST/copyq.conf"
copy_item "$SRC/themes" "$DEST/themes"

log "CopyQ configured"
