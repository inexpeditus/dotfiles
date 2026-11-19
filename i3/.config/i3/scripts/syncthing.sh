#!/usr/bin/env bash
# Syncthing status for i3blocks, from its REST API on localhost.
#
# Each remote device: ✓ when connected and up to date, its completion while it
# is catching up, dimmed while offline. A percentage after SYNC: means this
# machine is still pulling changes; errors are counted in red.

source "$(dirname "$0")/lib.sh"

config=${XDG_STATE_HOME:-$HOME/.local/state}/syncthing/config.xml
key=$(sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' "$config" 2>/dev/null)
addr=$(sed -n '/<gui/,/<\/gui>/s:.*<address>\(.*\)</address>.*:\1:p' "$config" 2>/dev/null)

api() { curl -fsS -m 2 -H "X-API-Key: $key" "http://$addr/rest/$1"; }

if [[ -z $key ]] || ! me=$(api system/status | jq -r .myID 2>/dev/null); then
  echo "SYNC: off"
  echo "SYNC: off"
  echo "$COLOR_DIM"
  exit 0
fi

# One "id connected name" line per remote device.
devices=$(jq -nr --argjson c "$(api system/connections)" --argjson d "$(api config/devices)" --arg me "$me" '
  $d[] | select(.deviceID != $me)
  | "\(.deviceID) \($c.connections[.deviceID].connected // false) \(.name)"')

sep=" <span color='$COLOR_DIM'>|</span> "
full='' COLOR=$COLOR_OK
while read -r id connected name; do
  [[ -n $id ]] || continue
  name=$(escape "$name")
  if [[ $connected != true ]]; then
    item="<span color='$COLOR_DIM'>$name</span>"
  else
    done=$(api "db/completion?device=$id" | jq '.completion | floor')
    if ((done >= 100)); then
      item="$name ✓"
    else
      item="$name $done%"
      COLOR=$COLOR_WARN
    fi
  fi
  full+="${full:+$sep}$item"
done <<<"$devices"

local_done=$(api db/completion | jq '.completion | floor')
((local_done < 100)) && full="$local_done% $full" COLOR=$COLOR_WARN

errors=0
for folder in $(api config/folders | jq -r '.[].id'); do
  ((errors += $(api "db/status?folder=$folder" | jq '.pullErrors // 0')))
done
((errors += $(api system/error | jq '.errors | length')))
((errors)) && full+=" <span color='$COLOR_CRIT'>$errors errors</span>"

echo "SYNC: $full"
echo "SYNC"
echo "$COLOR"
