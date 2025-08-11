#!/usr/bin/env bash
set -euo pipefail

# ===================== Configs padrão ajustáveis =====================
DEFAULT_DELAY=0.8           # segundos entre testes no modo --all
DEFAULT_CHAR_LIMIT=380      # usado pelo nsend (corte por caracteres)
DEFAULT_ICON_FILE="$HOME/.local/share/icons/hicolor/64x64/apps/arch.png"

# ===================== Dependências =====================
has() { command -v "$1" >/dev/null 2>&1; }
need_cmds=(notify-send gdbus)
for c in "${need_cmds[@]}"; do
  has "$c" || { echo "Faltando dependência: $c"; exit 1; }
done

# Python é opcional (só para gerar lorem enorme). Sem ele, usa fallback.
HAS_PY=false; has python3 && HAS_PY=true

# ===================== Helpers =====================
_sleep() { sleep "${1:-$DEFAULT_DELAY}"; }

nsend() {
  # nsend "Title" "Message" [char_limit] [notify-send extras...]
  local title="$1"; shift
  local msg="$1"; shift
  local max_chars="${1:-$DEFAULT_CHAR_LIMIT}"; shift || true
  local ellipsis="…"
  if [ "${#msg}" -gt "$max_chars" ]; then
    msg="${msg:0:max_chars}${ellipsis}"
  fi
  notify-send "$title" "$msg" "$@"
}

long_lorem() {
  if $HAS_PY; then
    python3 - <<'PY'
txt = ("Lorem ipsum dolor sit amet, consectetur adipiscing elit. ")*40
print(txt)
PY
  else
    # fallback sem python
    for _ in $(seq 1 40); do
      printf "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
    done
    printf "\n"
  fi
}

big_log() {
  # Linha 01..30
  printf '%s ' $(printf 'Linha_%02d:evento_registrado.' {1..30})
}

reload_swaync() {
  if has swaync-client; then
    swaync-client -rs
  else
    echo "swaync-client não encontrado; tentando reiniciar processo..."
    pkill -x swaync || true
    nohup swaync >/dev/null 2>&1 &
  fi
}

# ===================== Testes =====================
t_small()        { notify-send "Ping" "" -u low -t 3000; }
t_ok()           { notify-send "Backup" "OK" -u normal -t 4000; }
t_build()        { notify-send "Build" "Compilação finalizada com 0 erros e 18 avisos." -t 5000; }
t_long()         { notify-send "Release" "Uma nova versão foi publicada com correções importantes de estabilidade, melhorias de performance e ajustes na UI das preferências." -t 6000; }
t_icon_sym()     { notify-send -i dialog-information "Info" "Mensagem com ícone simbólico." -t 5000; }
t_icon_file()    { notify-send -i "${ICON_FILE:-$DEFAULT_ICON_FILE}" "Ícone custom" "Arquivo de ícone grande; deve respeitar o layout." -t 6000; }
t_large()        { notify-send "Log" "$(big_log)" -t 8000; }
t_giant()        { notify-send "Gigante" "$(long_lorem)" -t 12000; }
t_char_limit()   { local msg; msg=$(printf 'ID=%04d: atualização crítica disponível. ' {1..200}); nsend "Char-Limit" "$msg" "${CHAR_LIMIT:-$DEFAULT_CHAR_LIMIT}" -t 12000; }
t_critical()     { notify-send -u critical "Alerta" "Temperatura alta detectada!"; }
t_button()       {
  gdbus call --session \
    --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify \
    "Teste" 0 "" \
    "Teste de Botão" \
    "Clique no botão abaixo para testar o CSS" \
    '["config", "Abrir Configurações"]' \
    '{}' \
    5000 >/dev/null
}
t_reload()       { reload_swaync; }

# ===================== Sequências =====================
run_all() {
  t_reload; _sleep
  t_small; _sleep
  t_ok; _sleep
  t_build; _sleep
  t_long; _sleep
  t_icon_sym; _sleep
  t_icon_file; _sleep
  t_large; _sleep
  t_giant; _sleep
  t_char_limit; _sleep
  t_critical; _sleep
  t_button
}

list_tests() {
  cat <<EOF
Disponíveis (use por nome):
  reload         -> recarrega swaync (config + CSS)
  small          -> só título curto
  ok             -> "Backup" + "OK"
  build          -> corpo médio
  long           -> corpo longo (várias linhas)
  icon-sym       -> ícone simbólico (dialog-information)
  icon-file      -> ícone de arquivo (defina --icon-file=PATH)
  large          -> atinge max-width e quebra em linhas
  giant          -> gigante (testa corte por linhas/reticências no GTK)
  char-limit     -> usa truncagem por caracteres (nsend) [--char-limit=N]
  critical       -> urgência crítica
  button         -> notificação com botão via DBus
  all            -> roda todos em sequência
EOF
}

usage() {
  cat <<EOF
Uso: $0 [opções] [teste1 teste2 ...]
Se nenhum teste for passado e --menu não for usado, mostra --list.

Opções:
  --menu                 Menu interativo (requer fzf; se ausente, usa "select")
  --all                  Roda todos em sequência (igual ao teste "all")
  --delay=SEG            Delay entre testes no modo --all (padrão: $DEFAULT_DELAY)
  --char-limit=N         Limite de caracteres para "char-limit" (padrão: $DEFAULT_CHAR_LIMIT)
  --icon-file=PATH       Caminho do ícone para "icon-file" (padrão: $DEFAULT_ICON_FILE)
  --list                 Lista nomes dos testes
  --help                 Esta ajuda

Exemplos:
  $0 --menu
  $0 reload small long icon-file --icon-file="\$HOME/icon.png"
  $0 all --delay=0.5 --char-limit=420
  $0 giant char-limit
EOF
}

# ===================== Argparse simples =====================
MENU=false
RUN_ALL=false
TESTS=()

for arg in "$@"; do
  case "$arg" in
    --menu) MENU=true ;;
    --all) RUN_ALL=true ;;
    --delay=*) DEFAULT_DELAY="${arg#*=}" ;;
    --char-limit=*) CHAR_LIMIT="${arg#*=}" ;;
    --icon-file=*) ICON_FILE="${arg#*=}" ;;
    --list) list_tests; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    -*)
      echo "Opção desconhecida: $arg"; usage; exit 1 ;;
    *)
      TESTS+=("$arg")
      ;;
  esac
done

# ===================== Execução =====================
# Menu interativo
if $MENU; then
  list=(reload small ok build long icon-sym icon-file large giant char-limit critical button all)
  if has fzf; then
    mapfile -t picked < <(printf "%s\n" "${list[@]}" | fzf --multi --prompt="Selecione testes: ")
  else
    echo "fzf não encontrado; usando menu bash padrão."
    select sel in "${list[@]}" "FIM"; do
      [ "$sel" = "FIM" ] && break
      picked+=("$sel")
    done
  fi
  TESTS=("${picked[@]}")
fi

# --all tem prioridade
if $RUN_ALL; then
  run_all
  exit 0
fi

# Se nenhum teste foi passado, lista e sai
if [ "${#TESTS[@]}" -eq 0 ]; then
  list_tests
  exit 0
fi

# Mapear nomes -> funções
run_test() {
  case "$1" in
    reload)      t_reload ;;
    small)       t_small ;;
    ok)          t_ok ;;
    build)       t_build ;;
    long)        t_long ;;
    icon-sym)    t_icon_sym ;;
    icon-file)   t_icon_file ;;
    large)       t_large ;;
    giant)       t_giant ;;
    char-limit)  t_char_limit ;;
    critical)    t_critical ;;
    button)      t_button ;;
    all)         run_all; return ;;
    *) echo "Teste desconhecido: $1"; return 1 ;;
  esac
}

# Executar sequência escolhida
for t in "${TESTS[@]}"; do
  run_test "$t"
  _sleep
done
