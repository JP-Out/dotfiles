#!/usr/bin/env bash
# Main installation script
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

scripts=(
  "00-deps.sh"
  "install_galendae_ptbr.sh"
  "install_copyq.sh"
  "install_fastfetch.sh"
  "install_bluetooth.sh"
  "install_grim.sh"
  "install_kitty.sh"
  "install_nvim.sh"
  "install_nwg-bar.sh"
  "install_rofi.sh"
  "install_swaync.sh"
  "install_hypr.sh"
  "install_waybar.sh"
  "install_systemd_user.sh"
  "install_kdeglobals.sh"
  "install_assets_dotfiles.sh"
  "install_zsh.sh"
)

for script in "${scripts[@]}"; do
  echo "==> Running $script"
  "$REPO_DIR/$script" "$@"
done

echo "==> All components installed"
