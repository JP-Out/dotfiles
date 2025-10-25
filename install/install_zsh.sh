#!/usr/bin/env bash
# Zsh installation and configuration
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/zsh"

log "Installing Zsh dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying Zsh configuration"
copy_item "$SRC/zprofile" "$HOME/.zprofile"
copy_item "$SRC/zshenv" "$HOME/.zshenv"
copy_item "$SRC/zshrc" "$HOME/.zshrc"

log "Zsh configured"
