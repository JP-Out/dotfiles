#!/usr/bin/env bash
# conectar_bluetooth.sh — conecta (ou reconecta) a um dispositivo Bluetooth
# Uso:
#   MAC_ALEXA="AA:BB:CC:DD:EE:FF" ./conectar_bluetooth.sh
#   ./conectar_bluetooth.sh AA:BB:CC:DD:EE:FF
# Debug:
#   DEBUG=1 ./conectar_bluetooth.sh ...

set -uo pipefail

#----------------------------- Log -------------------------------------#
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
LOGFILE="$CACHE_DIR/bluetooth_autoconnect.log"
mkdir -p "$CACHE_DIR"

if [[ "${DEBUG:-0}" = "1" ]]; then
  exec > >(tee -a "$LOGFILE") 2>&1
  set -x
  printf "[%s] DEBUG ativado\n" "$(date '+%F %T')"
else
  exec >>"$LOGFILE" 2>&1
fi

log() { printf "[%s] %s\n" "$(date '+%F %T')" "$*"; }

#----------------------- Resolve caminho real --------------------------#
REAL_SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname -- "$REAL_SCRIPT_PATH")"

#----------------------- Carrega .env.local ----------------------------#
try_source() { [[ -n "${1:-}" && -f "$1" ]] && . "$1"; }
try_source "${DOTFILES_ENV:-}"
try_source "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/.env.local"
try_source "$HOME/.env.local"

dir="$SCRIPT_DIR"
for _ in {1..5}; do
  if [[ -f "$dir/.env.local" ]]; then
    . "$dir/.env.local"
    break
  fi
  parent="$(dirname -- "$dir")"
  [[ "$parent" = "$dir" ]] && break
  dir="$parent"

done

# Prioridade: arg > MAC_ALEXA
MAC_ARG="${1:-}"
MAC_ALEXA="${MAC_ARG:-${MAC_ALEXA:-}}"

if [[ -z "${MAC_ALEXA:-}" ]]; then
  log "ERRO: MAC não definido. Use MAC_ALEXA no .env.local, ou passe como argumento."
  exit 2
fi
log "Iniciando auto-conexão Bluetooth para $MAC_ALEXA"

#----------------------------- Dependências ----------------------------#
need() { command -v "$1" &>/dev/null || { log "ERRO: comando '$1' não encontrado"; exit 3; }; }
need systemctl
need bluetoothctl

#----------------------------- Serviços --------------------------------#
if ! systemctl is-active --quiet bluetooth.service; then
  log "bluetooth.service inativo; tentando iniciar…"
  systemctl start bluetooth.service || true
  for _ in {1..5}; do
    systemctl is-active --quiet bluetooth.service && break
    sleep 1
  done
fi

# Liga adaptador se necessário
if bluetoothctl show | grep -q "Powered: no"; then
  log "Ligando adaptador…"
  bluetoothctl power on || true
  sleep 1
fi

#----------------------------- Helpers ---------------------------------#
is_connected() { bluetoothctl info "$MAC_ALEXA" 2>/dev/null | grep -q "Connected: yes"; }

bluetoothctl trust "$MAC_ALEXA" || true
bluetoothctl pair  "$MAC_ALEXA" || true

if is_connected; then
  log "Já conectado a $MAC_ALEXA"
  exit 0
fi

#----------------------------- Conexão (uma tentativa só) --------------#
log "Tentando conectar a $MAC_ALEXA…"
bluetoothctl connect "$MAC_ALEXA" || true

if is_connected; then
  log "Conectado com sucesso a $MAC_ALEXA"
  exit 0
else
  log "FALHA: não foi possível conectar a $MAC_ALEXA"
  exit 1
fi
