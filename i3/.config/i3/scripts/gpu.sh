#!/usr/bin/env bash
# NVIDIA GPU load and temperature for i3blocks.
#
# Asking nvidia-smi wakes a runtime-suspended dGPU, which defeats power
# management on hybrid laptops. The PCI runtime status is checked first and
# nvidia-smi is only called while the card is already awake.

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
