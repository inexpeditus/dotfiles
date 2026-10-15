export DISPLAY=:0
xrandr --output eDP1 --mode 1920x1200
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources
systemctl --user import-environment DISPLAY XAUTHORITY
xbindkeys
export XDG_SESSION_TYPE=x11
exec i3
