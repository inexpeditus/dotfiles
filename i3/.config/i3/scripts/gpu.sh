#!/usr/bin/env bash
# NVIDIA GPU load and temperature for i3blocks.
#
# Asking nvidia-smi wakes a runtime-suspended dGPU and, while it is awake,
# resets its autosuspend timer. Polling it would keep the card powered forever
# on a hybrid laptop, so it is only called while a program other than the X
# server is actually using the GPU. Otherwise only the PCI runtime status is
# read, which never wakes the device.

source "$(dirname "$0")/lib.sh"

# The NVIDIA display controller (vendor 0x10de, class 0x03xxxx).
dev=
for d in /sys/bus/pci/devices/*; do
  read -r vendor <"$d/vendor"
  read -r class <"$d/class"
  if [[ $vendor == 0x10de && $class == 0x03* ]]; then
    dev=$d
    break
  fi
done

# No NVIDIA card or no driver tools: hide the block.
if [[ -z $dev ]] || ! command -v nvidia-smi >/dev/null; then
  echo
  exit 0
fi

read -r status <"$dev/power/runtime_status"
if [[ $status == suspended ]]; then
  echo "GPU: off"
  echo "GPU: off"
  echo "$COLOR_DIM"
  exit 0
fi

# Xorg always holds the device open, so look for any other process with it open.
busy=
while read -r pid; do
  read -r comm <"/proc/$pid/comm"
  if [[ $comm != Xorg ]]; then
    busy=1
    break
  fi
done < <(find /proc -maxdepth 3 -path '/proc/[0-9]*/fd/*' -lname '/dev/nvidia*' 2>/dev/null |
  cut -d/ -f3 | sort -u)

if [[ -z $busy ]]; then
  echo "GPU: on"
  echo "GPU: on"
  echo "$COLOR_DIM"
  exit 0
fi

if ! out=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu \
  --format=csv,noheader,nounits 2>/dev/null); then
  echo "GPU: n/a"
  echo "GPU: n/a"
  echo "$COLOR_DIM"
  exit 0
fi
IFS=', ' read -r util temp <<<"$out"

level "$util" 50 85
util_level=$LEVEL
level "$temp" 65 80
worst_color "$util_level" "$LEVEL"

echo "GPU: ${util}% ${temp}°C"
echo "GPU: ${util}% ${temp}°C"
echo "$COLOR"
