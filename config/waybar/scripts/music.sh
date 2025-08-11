#!/usr/bin/env bash

PLAYER="spotify"
class=$(playerctl --player=$PLAYER metadata --format '{{lc(status)}}' 2>/dev/null)
icon=""

if [[ $class == "playing" || $class == "paused" ]]; then
  info=$(playerctl --player=$PLAYER metadata --format '{{title}}')
  volume=$(playerctl --player=$PLAYER volume 2>/dev/null | awk '{printf "%d", $1*100}')

  # Trunca para 25 caracteres adicionando ...
  if [[ ${#info} -gt 10 ]]; then
    info="${info:0:25}..."
  fi

  # Ícone maior usando span do Pango
  if [[ $class == "paused" ]]; then
    text="<span size='22000' rise='-5000'></span><span size='8000'> </span>$info<span size='8000'> </span><span rise='-5900' size='24000'>$icon</span>"
  else
    text="<span size='22000' rise='-5000'></span><span size='8000'> </span>$info<span size='8000'> </span><span rise='-5900' size='24000'>$icon</span>"
  fi

  # Saída em JSON para Waybar
  echo -e "{\"text\":\"$text\",\"tooltip\":\"$info — Volume: ${volume}%\",\"class\":\"$class\"}"

else
  echo -e "{\"text\":\"\",\"tooltip\":\"Spotify parado\",\"class\":\"stopped\"}"
fi
