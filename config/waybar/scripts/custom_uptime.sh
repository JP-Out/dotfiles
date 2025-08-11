#!/usr/bin/env bash

UPTIME=$(awk '{print int($1)}' /proc/uptime)
HOURS=$((UPTIME / 3600))
MINS=$(( (UPTIME % 3600) / 60 ))
UPTIME_FORMAT=$(printf "%02dh:%02dm" "$HOURS" "$MINS")

# Padding só à esquerda
SPACING_LEFT="<span size='1000'>        </span>"  # 5 espaços à esquerda
SPACING_RIGHT="<span size='1000'>     </span>"  # 5 espaços à esquerda
ICON="<span size='26000' rise='-7000'>󰭖</span>"

# Não adiciono espaço após o ícone, apenas concateno direto com uptime
TEXT="$SPACING_LEFT$ICON$SPACING_RIGHT$UPTIME_FORMAT"

printf '{"text":"%s","tooltip":"Tempo de Sessão: %s","class":"user","markup":"pango"}\n' \
       "$TEXT" "$UPTIME_FORMAT"
