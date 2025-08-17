#!/usr/bin/env bash
# Kitty terminal installation
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/kitty"
DEST="$HOME/.config/kitty"

log "Installing Kitty dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying Kitty configuration"
copy_item "$SRC/kitty.conf" "$DEST/kitty.conf"
copy_item "$SRC/current-theme.conf" "$DEST/current-theme.conf"

log "Kitty configured"
