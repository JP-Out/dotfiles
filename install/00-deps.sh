#!/usr/bin/env bash
# =============================================================================
#  Dotfiles - Instalador de Dependências (Arch/Artix com pacman)
#  - Idempotente, modular e com logs
#  - Instala pacotes base via pacman e AUR via yay (auto-instala yay se faltar)
#  - Só instala o que estiver ausente
# =============================================================================

set -euo pipefail

#------------------------------- Configuração --------------------------------#
# Edite estas listas conforme forem surgindo novas dependências.
PACMAN_PACKAGES=(
  base-devel
  git
  curl
  wget
  bc
  bluez
  bluez-utils       # bluetoothctl
  copyq
  fastfetch
  gawk              # awk
  grim
  hyprland
  hyprlock
  hyprpaper
  iproute2          # ip
  kitty
  libnotify         # notify-send
  neovim
  networkmanager    # inclui nmtui
  nwg-bar
  rofi
  pamixer
  pipewire-pulse    # provê pactl
  playerctl
  procps-ng         # pgrep
  radeontop
  sed
  slurp
  waybar
  zsh
  papirus-icon-theme      # opcional: ícones Papirus
  ttf-jetbrains-mono-nerd # opcional: Nerd Font
  # adicione aqui: 'unzip' 'jq' 'jq' ...
)

AUR_PACKAGES=(
  swaync
)

# Helper AUR padrão
AUR_HELPER="yay"       
AUR_HELPER_PKG="yay"   # para detecção

# Pasta de trabalho temporária p/ builds do AUR
BUILD_DIR="${TMPDIR:-/tmp}/dotfiles-aur-build"

# Log
LOG_FILE="/tmp/dotfiles-install-deps.log"

# Flags
ASSUME_YES=false   # -y instala sem perguntar (para prompts que eventualmente surjam)
QUIET=false        # -q reduz verbosidade

#------------------------------- Utilidades ----------------------------------#
log()   { $QUIET && return 0; printf "[deps] %s\n" "$*" | tee -a "$LOG_FILE"; }
fail()  { printf "[deps][ERRO] %s\n" "$*" | tee -a "$LOG_FILE" >&2; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

need_sudo() {
  if [[ $EUID -ne 0 ]]; then
    if ! sudo -v; then
      fail "Preciso de sudo para continuar."
    fi
  fi
}

check_arch() {
  if ! [[ -f /etc/arch-release || -f /run/artix ]]; then
    fail "Este script é para sistemas baseados em pacman (Arch/Artix)."
  fi
}

pacman_sync() {
  need_sudo
  local args=( -Syu --needed --noconfirm )
  $ASSUME_YES || args=( -Syu --needed )   # permite interação se não usar -y
  log "Atualizando base de pacotes (pacman ${args[*]})..."
  sudo pacman "${args[@]}" || fail "Falha ao atualizar com pacman."
}

pacman_install() {
  need_sudo
  local pkgs_to_install=()
  for p in "$@"; do
    # Skip se já instalado
    if pacman -Qi "$p" >/dev/null 2>&1; then
      log "✓ (pacman) $p já instalado"
    else
      pkgs_to_install+=("$p")
    fi
  done
  [[ ${#pkgs_to_install[@]} -eq 0 ]] && return 0
  local args=( -S --needed --noconfirm )
  $ASSUME_YES || args=( -S --needed )
  log "Instalando via pacman: ${pkgs_to_install[*]}"
  sudo pacman "${args[@]}" "${pkgs_to_install[@]}" || fail "Falha ao instalar pacotes pacman."
}

bootstrap_yay() {
  # Instala git + base-devel (necessários p/ compilar AUR)
  pacman_install git base-devel

  mkdir -p "$BUILD_DIR"
  pushd "$BUILD_DIR" >/dev/null

  # Preferimos `yay` estável do AUR oficial
  if [[ -d yay ]]; then
    rm -rf yay
  fi
  log "Clonando AUR: yay"
  git clone --depth=1 https://aur.archlinux.org/yay.git >>"$LOG_FILE" 2>&1 || fail "Falha ao clonar yay."
  cd yay
  log "Compilando e instalando yay (makepkg)..."
  # --noconfirm se -y foi passado
  local make_args=( -si --needed )
  $ASSUME_YES && make_args+=( --noconfirm )
  makepkg "${make_args[@]}" >>"$LOG_FILE" 2>&1 || fail "Falha ao compilar/instalar yay."
  popd >/dev/null
}

aur_install() {
  [[ $# -gt 0 ]] || return 0

  check_aur

  local pkgs_to_install=()
  for p in "$@"; do
    if pacman -Qi "$p" >/dev/null 2>&1; then
      log "✓ (aur) $p já instalado"
    else
      pkgs_to_install+=("$p")
    fi
  done
  [[ ${#pkgs_to_install[@]} -eq 0 ]] && return 0

  local args=( -S --needed )
  $ASSUME_YES && args+=( --noconfirm )
  log "Instalando via $AUR_HELPER: ${pkgs_to_install[*]}"
  "$AUR_HELPER" "${args[@]}" "${pkgs_to_install[@]}" || fail "Falha ao instalar pacotes AUR."
}

usage() {
  cat <<EOF
Uso: $(basename "$0") [opções]

Instala dependências de base para o repositório de dotfiles no Arch.

Opções:
  -y, --yes       Executa sem prompts (passa --noconfirm quando possível)
  -q, --quiet     Saída reduzida
  -h, --help      Mostra esta ajuda

Como estender:
  • Adicione pacotes do repositório oficial em PACMAN_PACKAGES
  • Adicione pacotes do AUR em AUR_PACKAGES
  • O script instalará apenas o que estiver ausente

EOF
}

#------------------------------- Main ----------------------------------------#
main() {
  : >"$LOG_FILE"

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -y|--yes)   ASSUME_YES=true ; shift ;;
      -q|--quiet) QUIET=true      ; shift ;;
      -h|--help)  usage; exit 0   ;;
      *)          fail "Opção desconhecida: $1" ;;
    esac
  done

  check_arch

  log "Iniciando instalador de dependências…"
  log "Log detalhado: $LOG_FILE"

  # Atualiza índices e sistema (seguro/idempotente)
  pacman_sync

  # Garante pacotes base (inclui git, base-devel, curl, wget, etc.)
  pacman_install "${PACMAN_PACKAGES[@]}"

  # Garante AUR configurado e instala pacotes do AUR
  if [[ ${#AUR_PACKAGES[@]} -gt 0 || "$AUR_HELPER" == "yay" ]]; then
    check_aur
    aur_install "${AUR_PACKAGES[@]}"
  fi

  log "✔ Dependências concluídas."
}

main "$@"

#------------------------------- Verificação AUR -----------------------------#
check_aur() {
  if ! have "$AUR_HELPER"; then
    log "Nenhum AUR helper detectado. Preparando bootstrap de $AUR_HELPER…"
    bootstrap_yay
  else
    log "✓ AUR helper '$AUR_HELPER' já configurado"
  fi
}
