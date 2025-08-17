#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# dotfiles-link.sh — cria links simbólicos a partir do seu repo
# ------------------------------------------------------------
# Opções:
#   -n | --dry-run   : mostra o que faria, sem alterar nada
#   -f | --force     : sobrescreve mesmo se já houver symlink diferente
#   -v | --verbose   : saída detalhada
#
# Ex:
#   ./dotfiles-link.sh --dry-run
#   ./dotfiles-link.sh -v
# ============================================================

DRY_RUN=0
FORCE=0
VERBOSE=0

log()  { printf '%s\n' "$*"; }
vlog() { [ "$VERBOSE" -eq 1 ] && printf '%s\n' "$*"; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then echo "[dry-run] $*"; else eval "$@"; fi; }

# --- Ajuste se o repo não estiver em ~/.dotfiles
BASE_DIR="${BASE_DIR:-"$HOME/.dotfiles"}"

timestamp() { date +'%Y%m%d-%H%M%S'; }

backup_path() {
  local path="$1"
  printf '%s.bak-%s' "$path" "$(timestamp)"
}

# Cria diretório pai (mkdir -p) do caminho informado
ensure_parent_dir() {
  local target="$1"
  local parent; parent="$(dirname -- "$target")"
  [ -d "$parent" ] || run "mkdir -p -- \"$parent\""
}

# Linka um único par DEST -> SRC
link_one() {
  local dest="$1"
  local src="$2"

  # Expande ~ se aparecer no mapping (defensivo)
  dest="${dest/#\~/$HOME}"

  # Substitui prefixo /home/shaka por $HOME de forma segura
  local home_prefix="/home/$(id -un)"
  dest="${dest/#\/home\/shaka/$HOME}"

  # Fonte dentro do repo (permite caminho absoluto também)
  if [[ "$src" == /* ]]; then
    source_path="$src"
  else
    source_path="$BASE_DIR/$src"
  fi

  # Normaliza também os exemplos que vieram absolutos do seu texto:
  source_path="${source_path/#\/home\/shaka\/.dotfiles/$BASE_DIR}"

  if [ ! -e "$source_path" ]; then
    log "⚠️  Origem inexistente: $source_path  (pulado)"
    return 0
  fi

  ensure_parent_dir "$dest"

  if [ -L "$dest" ]; then
    # Já é link simbólico
    local current; current="$(readlink -- "$dest")" || true
    if [ "$current" = "$source_path" ]; then
      vlog "✓ Já aponta corretamente: $dest -> $source_path"
      return 0
    else
      if [ "$FORCE" -eq 1 ]; then
        vlog "↻ Relink (force): $dest (era -> $current)"
        run "ln -sfn -- \"$source_path\" \"$dest\""
      else
        local bak; bak="$(backup_path "$dest")"
        log "ℹ️  Symlink diferente encontrado. Movendo para $bak"
        run "mv -- \"$dest\" \"$bak\""
        run "ln -s -- \"$source_path\" \"$dest\""
      fi
      return 0
    fi
  fi

  if [ -e "$dest" ]; then
    # Existe arquivo/dir comum
    local bak; bak="$(backup_path "$dest")"
    log "ℹ️  Existe em $dest. Movendo para backup: $bak"
    run "mv -- \"$dest\" \"$bak\""
  fi

  vlog "→ ln -s \"$source_path\" \"$dest\""
  run "ln -s -- \"$source_path\" \"$dest\""
}

# -------------------- PARÂMETROS --------------------
while (($#)); do
  case "$1" in
    -n|--dry-run) DRY_RUN=1 ;;
    -f|--force)   FORCE=1 ;;
    -v|--verbose) VERBOSE=1 ;;
    -h|--help)
      cat <<EOF
Uso: $(basename "$0") [opções]

Opções:
  -n, --dry-run   Mostra o que faria sem mudar nada
  -f, --force     Força relink quando já houver symlink diferente
  -v, --verbose   Saída detalhada
Vars:
  BASE_DIR        (padrão: \$HOME/.dotfiles)

Exemplos:
  BASE_DIR="\$HOME/dev/dotfiles" $(basename "$0") -v
  $(basename "$0") --dry-run
EOF
      exit 0
      ;;
    *) log "Opção desconhecida: $1"; exit 2 ;;
  esac
  shift
done

# -------------------- MAPEAMENTO --------------------
# Formato: DESTINO|ORIGEM_NO_REPO_ou_ABSOLUTO
# Observação:
# - Você pode remover/ajustar qualquer linha abaixo.
# - Caminhos absolutos em /home/shaka/.dotfiles são normalizados para \$BASE_DIR.
MAP=$(cat <<'EOF'
$HOME/.zshenv.bak|zsh/zshenv
$HOME/.zprofile.bak|zsh/zprofile
$HOME/.config/swaync|config/swaync
$HOME/.config/assets-dotfiles|config/assets-dotfiles
$HOME/.config/fastfetch|config/fastfetch
$HOME/.config/rofi.bak.2025-08-16-1912|config/rofi
$HOME/.config/copyq/themes|config/copyq/themes
$HOME/.config/copyq/copyq.conf|config/copyq/copyq.conf
$HOME/.config/rofi|config/rofi
$HOME/.config/hypr|config/hypr
$HOME/.config/kitty|config/kitty
$HOME/.config/nwg-bar|config/nwg-bar
$HOME/.config/systemd-copia/user/default.target.wants/bluetooth-autoconnect.service|config/systemd/user/bluetooth-autoconnect.service
$HOME/.config/scripts|config/scripts
$HOME/.config/avatar.png|config/assets-dotfiles/avatar.png
$HOME/.config/waybar|config/waybar
$HOME/.config/kdeglobals|config/kdeglobals
$HOME/.config/galendae|config/galendae
$HOME/.config/nvim|config/nvim
$HOME/.config/systemd/user|config/systemd/user
$HOME/.local/share/Trash/files/cliphist.service|config/systemd/user/cliphist.service
$HOME/.local/bin/screenshot.sh|config/grim/screenshot.sh
EOF
)

# -------------------- EXECUÇÃO --------------------
log "==> Criando links simbólicos a partir de: $BASE_DIR"
[ "$DRY_RUN" -eq 1 ] && log "(modo dry-run: nenhuma alteração será feita)"
[ "$FORCE"  -eq 1 ] && vlog "(force ON)"
[ "$VERBOSE" -eq 1 ] && vlog "(verbose ON)"

# Itera o mapa (pula linhas vazias/comentários)
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  IFS='|' read -r dest src <<<"$line"
  link_one "$dest" "$src"
done <<< "$MAP"

log "✓ Finalizado."
