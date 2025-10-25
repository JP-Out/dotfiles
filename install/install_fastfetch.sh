#!/usr/bin/env bash
# Fastfetch installation and configuration
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/fastfetch"
DEST="$HOME/.config/fastfetch"

log "Installing Fastfetch dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying Fastfetch configuration"
copy_item "$SRC/config.jsonc" "$DEST/config.jsonc"
copy_item "$SRC/logo" "$DEST/logo"

log "Fastfetch configured"
