#!/usr/bin/env bash
# Neovim installation and configuration
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/install/helpers.sh"

SRC="$REPO_DIR/config/nvim"
DEST="$HOME/.config/nvim"
PLUG="$HOME/.local/share/nvim/site/autoload/plug.vim"

log "Installing Neovim dependencies"
"$REPO_DIR/install/00-deps.sh" "$@"

log "Copying Neovim configuration"
mkdir -p "$DEST"
cp "$SRC"/*.vim "$DEST/"

if [[ ! -f "$PLUG" ]]; then
  log "Installing vim-plug"
  curl -fLo "$PLUG" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if command -v nvim >/dev/null 2>&1; then
  log "Installing Neovim plugins"
  nvim --headless +PlugInstall +qall || true
fi

log "Neovim configured"
