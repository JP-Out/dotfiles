#!/bin/bash

hour=$(date +%H:%M)
day=$(date +%A)
month=$(date +%B)
num=$(date +%d)

# Ajusta nomes em português formal
case $day in
  segunda|terça|quarta|quinta|sexta) day="$day-feira";;
esac
day_cap=$(echo "$day" | sed -E "s/^./\U&/")
month_cap=$(echo "$month" | sed -E "s/^./\U&/")

tooltip="$day_cap, $num de $month_cap"

# Fake letter-spacing com Pango
spacing="<span size='1000'>     </span>" # ajuste os espaços
icon="<span size='19000' rise='-3500'>󰃰</span>"

# Monta JSON em uma única linha
printf '{"text":"%s%s%s","tooltip":"%s","class":"clock","markup":"pango"}\n' \
  "$icon" "$spacing" "$hour" "$tooltip"
