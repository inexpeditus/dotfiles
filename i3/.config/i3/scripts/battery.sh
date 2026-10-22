#!/usr/bin/env bash
# Battery charge and state for i3blocks, read straight from sysfs.

source "$(dirname "$0")/lib.sh"

for bat in /sys/class/power_supply/BAT*; do
  [[ -r $bat/capacity ]] && break
done

# No battery (desktop): hide the block.
if [[ ! -r $bat/capacity ]]; then
  echo
  exit 0
fi

read -r percent <"$bat/capacity"
read -r state <"$bat/status"

# Only warn while draining; a low battery that is charging is fine.
COLOR=$COLOR_OK
if [[ $state == Discharging ]]; then
  if ((percent < 10)); then
    COLOR=$COLOR_CRIT
  elif ((percent < 20)); then
    COLOR=$COLOR_WARN
  fi
fi

# ⚡ charging, orange ⚡ draining (the same colour as upload in the wifi block),
# = on the charger but not charging (full or held).
case $state in
Charging) sign="⚡" ;;
Discharging) sign="<span color='$COLOR_ACCENT'>⚡</span>" ;;
*) sign="=" ;;
esac

echo "Battery: ${percent}% ${sign}"
echo "${percent}%${sign}"
echo "$COLOR"
