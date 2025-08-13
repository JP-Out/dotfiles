#!/usr/bin/env bash
# =============================================================================
#  Waybar setup script
#  - Instala dependências (via 00-deps.sh)
#  - Copia arquivos de configuração
#  - Garante execução junto ao Hyprland
#  - Destaca pacotes opcionais (Nerd Fonts, Papirus)
# =============================================================================

set -euo pipefail

# Diretórios
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAYBAR_SRC="$REPO_DIR/config/waybar"
WAYBAR_DEST="$HOME/.config/waybar"

#------------------------------------------------------------------------------
# Dependências
#------------------------------------------------------------------------------
echo "==> Instalando dependências via 00-deps.sh"
"$REPO_DIR/install/00-deps.sh" "$@"

# Galendae (para o relógio customizado)
if ! command -v galendae >/dev/null 2>&1; then
  echo "==> Instalando galendae (clock)"
  "$REPO_DIR/install/install_galendae_ptbr.sh"
fi

#------------------------------------------------------------------------------
# Copiando arquivos de configuração
#------------------------------------------------------------------------------
echo "==> Copiando configuração do Waybar"
mkdir -p "$WAYBAR_DEST/scripts"
cp "$WAYBAR_SRC/config.jsonc" "$WAYBAR_DEST/"
cp "$WAYBAR_SRC/style.css" "$WAYBAR_DEST/"
cp "$WAYBAR_SRC/scripts"/*.sh "$WAYBAR_DEST/scripts/"
chmod +x "$WAYBAR_DEST/scripts"/*.sh

#------------------------------------------------------------------------------
# Integrando com Hyprland
#------------------------------------------------------------------------------
HYPR_CFG="$HOME/.config/hypr/hyprland.conf"
mkdir -p "$(dirname "$HYPR_CFG")"
if [[ -f "$HYPR_CFG" ]]; then
  if ! grep -q 'exec-once *= *waybar' "$HYPR_CFG"; then
    echo 'exec-once = waybar &' >> "$HYPR_CFG"
  fi
else
  echo 'exec-once = waybar &' > "$HYPR_CFG"
fi

#------------------------------------------------------------------------------
# Finalização
#------------------------------------------------------------------------------
echo "==> Waybar configurado com sucesso"
echo "Pacotes opcionais: ttf-jetbrains-mono-nerd (Nerd Font), papirus-icon-theme"