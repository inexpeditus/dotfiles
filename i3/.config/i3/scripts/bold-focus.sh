#!/usr/bin/env bash
# Bold title for the focused window, regular for the rest.
#
# i3 has one font for all title bars, so this swaps title_format on every
# focus change. Started with exec_always from the i3 config.

# exec_always runs this again on every reload; stop the previous instance.
pidfile=${XDG_RUNTIME_DIR:-/tmp}/i3-bold-focus.pid
[ -f "$pidfile" ] && kill "$(<"$pidfile")" 2>/dev/null
echo $$ >"$pidfile"

# The _bold mark remembers which window is bold; marks starting with an
# underscore are not shown in the title bar.
bold() {
  i3-msg -q "[con_mark=_bold] title_format \"%title\", unmark _bold; [con_id=$1] mark --add _bold, title_format \"<span size='11pt' weight='bold'>%title</span>\"" 2>/dev/null
}

bold __focused__

re='^\{"change":"focus","container":\{"id":([0-9]+)'
while read -r event; do
  [[ $event =~ $re ]] && bold "${BASH_REMATCH[1]}"
done < <(i3-msg -t subscribe -m '["window"]')
