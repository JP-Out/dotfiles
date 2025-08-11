#!/bin/bash

# Lista de processos conhecidos que criam ícones no tray
APPS="discord steam telegram-desktop nm-applet blueman-applet obs keybase-gui nextcloud copyq zapzap"

# Conta quantos estão ativos
COUNT=0
for APP in $APPS; do
    if pgrep -x "$APP" >/dev/null 2>&1; then
        COUNT=$((COUNT+1))
    fi
done

# Se algum está rodando, mostra o separador
if [ "$COUNT" -gt 0 ]; then
    echo "│"
else
    echo ""
fi
