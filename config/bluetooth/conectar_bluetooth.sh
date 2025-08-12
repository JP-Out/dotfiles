#!/usr/bin/env bash

DEVICE_MAC="68:B6:91:8D:DB:B5"  # Substitua pelo MAC do seu dispositivo (Alexa)
LOGFILE="$HOME/.cache/bluetooth_autoconnect.log"

mkdir -p "$HOME/.cache"

echo "[$(date)] Iniciando auto-conexão Bluetooth..." >> "$LOGFILE"

# Espera até o bluetoothd estar ativo
until systemctl is-active --quiet bluetooth.service; do
    echo "[$(date)] Aguardando bluetooth.service..." >> "$LOGFILE"
    sleep 2
done

# Liga o bluetooth se estiver desligado
bluetoothctl show | grep -q "Powered: no" && {
    echo "[$(date)] Ligando adaptador..." >> "$LOGFILE"
    bluetoothctl power on
    sleep 2
}

# Tenta conectar até conseguir
for i in {1..10}; do
    if bluetoothctl connect "$DEVICE_MAC"; then
        echo "[$(date)] Conectado com sucesso ao $DEVICE_MAC!" >> "$LOGFILE"
        exit 0
    else
        echo "[$(date)] Tentativa $i falhou, tentando novamente..." >> "$LOGFILE"
        sleep 5
    fi
done

echo "[$(date)] Não foi possível conectar após várias tentativas." >> "$LOGFILE"
exit 1
