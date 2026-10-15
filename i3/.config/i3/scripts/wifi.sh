#!/usr/bin/env bash
# Wi-Fi connection name and signal quality for i3blocks.
#
# Quality comes from /proc/net/wireless (link quality is out of 70); the
# connection name comes from NetworkManager.

source "$(dirname "$0")/lib.sh"

# The first two lines of /proc/net/wireless are headers.
iface= link=
{
  read -r
  read -r
  read -r iface _ link _
} </proc/net/wireless
iface=${iface%:}
link=${link%.}

name=
[[ -n $iface ]] && name=$(nmcli -g GENERAL.CONNECTION device show "$iface" 2>/dev/null)

if [[ -z $name ]]; then
  echo "Wi-Fi: down"
  echo "down"
  echo "$COLOR_DIM"
  exit 0
fi

quality=$((link * 100 / 70))

echo "${name} ${quality}%"
echo "${quality}%"
if ((quality >= 60)); then
  echo "#fff2cc"
elif ((quality >= 35)); then
  echo "$COLOR_WARN"
else
  echo "$COLOR_CRIT"
fi
