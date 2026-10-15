#!/usr/bin/env bash
# CPU load and package temperature for i3blocks.
#
# Load is the delta between two /proc/stat samples. The previous sample is kept
# in $XDG_RUNTIME_DIR so the script never has to sleep. The first run after
# boot reports 0%.

source "$(dirname "$0")/lib.sh"

state="${XDG_RUNTIME_DIR:-/tmp}/i3blocks-cpu"

read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
idle_all=$((idle + iowait))
total=$((user + nice + system + idle_all + irq + softirq + steal))

usage=0
if [[ -r $state ]]; then
  read -r prev_total prev_idle <"$state"
  dt=$((total - prev_total))
  ((dt > 0)) && usage=$((100 * (dt - (idle_all - prev_idle)) / dt))
fi
echo "$total $idle_all" >"$state"

# coretemp (Intel) and k10temp (AMD) both expose the package temperature as
# temp1, in millidegrees.
temp=
for hwmon in /sys/class/hwmon/hwmon*; do
  read -r name <"$hwmon/name"
  if [[ $name == coretemp || $name == k10temp ]]; then
    read -r millideg <"$hwmon/temp1_input"
    temp=$((millideg / 1000))
    break
  fi
done

level "$usage" 50 85
usage_level=$LEVEL
temp_level=0
if [[ -n $temp ]]; then
  level "$temp" 65 80
  temp_level=$LEVEL
fi
worst_color "$usage_level" "$temp_level"

text="CPU: ${usage}%${temp:+ ${temp}°C}"
echo "$text"
echo "$text"
echo "$COLOR"
