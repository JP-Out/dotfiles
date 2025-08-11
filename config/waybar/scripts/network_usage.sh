#!/bin/bash

LC_NUMERIC=C  # garante ponto decimal

IFACE=$(ip route | grep '^default' | awk '{print $5}')
[ -z "$IFACE" ] && exit 0

# Lê os bytes recebidos/enviados antes e depois de 1 segundo
RX1=$(< /sys/class/net/$IFACE/statistics/rx_bytes)
TX1=$(< /sys/class/net/$IFACE/statistics/tx_bytes)
sleep 1
RX2=$(< /sys/class/net/$IFACE/statistics/rx_bytes)
TX2=$(< /sys/class/net/$IFACE/statistics/tx_bytes)

# Calcula diferença e converte para MB
RX_MB=$(awk "BEGIN {printf \"%.2f\", ($RX2-$RX1)/1024/1024}")
TX_MB=$(awk "BEGIN {printf \"%.2f\", ($TX2-$TX1)/1024/1024}")

THRESHOLD=0.01             # 0.01 MB/s (10 KB/s) para considerar atividade
STATE_FILE="/tmp/net_speed_counter"
VISIBLE_FILE="/tmp/net_speed_visible"

COUNTER=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
VISIBLE=$(cat "$VISIBLE_FILE" 2>/dev/null || echo 0)

# Detecta atividade
if (( $(echo "$RX_MB >= $THRESHOLD || $TX_MB >= $THRESHOLD" | bc -l) )); then
    COUNTER=$((COUNTER+1))
else
    COUNTER=0
fi

# Define por quantos ciclos deve permanecer visível mesmo após parar
HOLD_CYCLES=5  # ~5 segundos se o script rodar 1x por segundo

if [ "$COUNTER" -ge 2 ]; then
    # Ativou visibilidade
    VISIBLE=$HOLD_CYCLES
fi

if [ "$VISIBLE" -gt 0 ]; then
    VISIBLE=$((VISIBLE-1))
    # Exibe saída em JSON
    printf '{"text":"↓%s MB/s ↑%s MB/s","tooltip":"Uso da Rede: Dw︱Up","class":"net_usage"}\n' "$RX_MB" "$TX_MB"
fi

echo "$COUNTER" > "$STATE_FILE"
echo "$VISIBLE" > "$VISIBLE_FILE"
