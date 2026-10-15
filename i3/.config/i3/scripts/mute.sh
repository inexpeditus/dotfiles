#!/usr/bin/env bash
# Speaker icon for the default sink, red while muted.
#
# Not polled: i3blocks runs it once and again on SIGRTMIN+10, which the volume
# keybindings in i3/config send after every change.

icon_muted=$'\uf026' # speaker, no waves
icon_vol=$'\uf028'   # speaker with waves

if [[ $(pactl get-sink-mute @DEFAULT_SINK@) == *yes ]]; then
  echo "$icon_muted"
  echo "$icon_muted"
  echo "#FF5555"
else
  echo "$icon_vol"
fi
