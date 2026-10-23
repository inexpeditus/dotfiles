#!/usr/bin/env bash
# Wi-Fi connection name, signal quality and traffic for i3blocks.
#
# Quality comes from /proc/net/wireless (link quality is out of 70); the
# connection name comes from NetworkManager. Traffic is the download and upload
# per second since the previous run, from the interface's byte counters (kept in
# $XDG_RUNTIME_DIR).

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

state="${XDG_RUNTIME_DIR:-/tmp}/i3blocks-wifi"
stats=/sys/class/net/$iface/statistics
rx=$(<"$stats/rx_bytes") tx=$(<"$stats/tx_bytes") now=$(date +%s%N)
down=0 up=0
if [[ -r $state ]]; then
  read -r prev_iface prev_rx prev_tx prev_t <"$state"
  dt=$((now - prev_t))
  if [[ $prev_iface == "$iface" ]] && ((dt > 0 && rx >= prev_rx && tx >= prev_tx)); then
    down=$(((rx - prev_rx) * 1000000000 / dt))
    up=$(((tx - prev_tx) * 1000000000 / dt))
  fi
fi
echo "$iface $rx $tx $now" >"$state"

# The block uses pango markup, so escape the connection name.
name=$(escape "$name")
echo "${name} ${quality}% <span color='$COLOR_OK'>↓</span>$(human "$down") <span color='$COLOR_ACCENT'>↑</span>$(human "$up")"
echo "${quality}%"
if ((quality >= 60)); then
  echo "#fff2cc"
elif ((quality >= 35)); then
  echo "$COLOR_WARN"
else
  echo "$COLOR_CRIT"
fi
