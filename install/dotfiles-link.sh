#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# dotfiles-link.sh — cria symlinks a partir do seu repo, em qualquer lugar
# Opções:
#   -n | --dry-run   : só mostra o que faria
#   -f | --force     : relinka se já houver symlink diferente
#   -v | --verbose   : saída detalhada
# Variáveis:
#   BASE_DIR         : força o caminho do repo (opcional)
# ============================================================

DRY_RUN=0; FORCE=0; VERBOSE=0
log()  { printf '%s\n' "$*"; }
vlog() { [ "$VERBOSE" -eq 1 ] && printf '%s\n' "$*"; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then echo "[dry-run] $*"; else eval "$@"; fi; }

# ---------- Descobre diretório do script (resolve symlinks) ----------
resolve_script_dir() {
  local src="${BASH_SOURCE[0]}"
  while [ -h "$src" ]; do
    local link; link="$(readlink "$src")"
    if [[ "$link" = /* ]]; then src="$link"; else src="$(cd -P -- "$(dirname -- "$src")" && pwd)/$link"; fi
  done
  cd -P -- "$(dirname -- "$src")" && pwd
}

SCRIPT_DIR="$(resolve_script_dir)"

# ---------- Descobre BASE_DIR automaticamente ----------
detect_base_dir() {
  # 1) Variável de ambiente (prioridade máxima)
  if [ -n "${BASE_DIR:-}" ]; then
    printf '%s\n' "$(realpath -m -- "$BASE_DIR")"
    return
  fi

  # 2) Git toplevel (se estiver dentro do repo)
  if command -v git >/dev/null 2>&1; then
    if top=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true); then
      if [ -n "$top" ]; then
        printf '%s\n' "$(realpath -m -- "$top")"
        return
      fi
    fi
  fi

  # 3) Sobe diretórios a partir do SCRIPT_DIR procurando estrutura típica
  local probe="$SCRIPT_DIR"
  while [[ "$probe" != "/" ]]; do
    if [[ -d "$probe/config" && -d "$probe/zsh" ]]; then
      printf '%s\n' "$probe"
      return
    fi
    probe="$(dirname -- "$probe")"
  done

  # 4) Fallback: pasta do script
  printf '%s\n' "$SCRIPT_DIR"
}

BASE_DIR="$(detect_base_dir)"
BASE_DIR="$(realpath -m -- "$BASE_DIR")"

timestamp() { date +'%Y%m%d-%H%M%S'; }
backup_path() { printf '%s.bak-%s' "$1" "$(timestamp)"; }

ensure_parent_dir() {
  local target="$1"
  local parent; parent="$(dirname -- "$target")"
  [ -d "$parent" ] || run "mkdir -p -- \"$parent\""
}

link_one() {
  local dest="$1" relsrc="$2"
  dest="${dest/#\~/$HOME}"

  # Origem é relativa ao BASE_DIR (ou absoluta, se vier /…)
  local source_path
  if [[ "$relsrc" == /* ]]; then
    source_path="$relsrc"
  else
    source_path="$BASE_DIR/$relsrc"
  fi
  source_path="$(realpath -m -- "$source_path")"

  if [ ! -e "$source_path" ]; then
    log "⚠️  Origem inexistente: $source_path  (pulado)"
    return 0
  fi

  ensure_parent_dir "$dest"

  if [ -L "$dest" ]; then
    local current; current="$(readlink -- "$dest")" || true
    # Normaliza current relativo para absoluto baseado no dest parent
    if [[ "$current" != /* ]]; then
      current="$(realpath -m -- "$(dirname -- "$dest")/$current")"
    fi
    if [ "$current" = "$source_path" ]; then
      vlog "✓ Já aponta corretamente: $dest -> $source_path"
      return 0
    fi
    if [ "$FORCE" -eq 1 ]; then
      vlog "↻ Relink (force): $dest (era -> $current)"
      run "ln -sfn -- \"$source_path\" \"$dest\""
      return 0
    else
      local bak; bak="$(backup_path "$dest")"
      log "ℹ️  Symlink diferente encontrado. Movendo para: $bak"
      run "mv -- \"$dest\" \"$bak\""
    fi
  elif [ -e "$dest" ]; then
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

Você pode definir BASE_DIR para forçar o caminho do repositório.
EOF
      exit 0 ;;
    *) log "Opção desconhecida: $1"; exit 2 ;;
  esac; shift
done

# -------------------- SANITY CHECK --------------------
if [[ ! -d "$BASE_DIR/config" || ! -d "$BASE_DIR/zsh" ]]; then
  log "⚠️  Aviso: BASE_DIR não parece um repo de dotfiles esperado:"
  log "    BASE_DIR = $BASE_DIR"
  log "    (faltando 'config/' e/ou 'zsh/'). Continuando mesmo assim…"
fi

log "==> Repo detectado em: $BASE_DIR"
[ "$DRY_RUN" -eq 1 ] && log "(modo dry-run: nenhuma alteração será feita)"
[ "$FORCE" -eq 1 ] && vlog "(force ON)"
[ "$VERBOSE" -eq 1 ] && vlog "(verbose ON)"

# -------------------- MAPEAMENTO --------------------
# Formato: DESTINO|ORIGEM_RELATIVA_AO_BASE_DIR (ou absoluta)
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
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  IFS='|' read -r dest src <<<"$line"
  link_one "$dest" "$src"
done <<< "$MAP"

log "✓ Finalizado."
