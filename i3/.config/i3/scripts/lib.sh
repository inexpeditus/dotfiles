# Shared helpers for the i3blocks scripts. Source this file, don't run it.

COLOR_OK="#a4d280"
COLOR_WARN="#f0a050"
COLOR_CRIT="#e05050"
COLOR_DIM="#888888"

# level VALUE WARN CRIT
# Sets LEVEL to 0 (ok), 1 (VALUE > WARN) or 2 (VALUE > CRIT).
level() {
  LEVEL=0
  (($1 > $2)) && LEVEL=1
  (($1 > $3)) && LEVEL=2
}

# worst_color LEVEL...
# Sets COLOR from the highest level given.
worst_color() {
  local max=0 l
  for l; do
    ((l > max)) && max=$l
  done
  case $max in
  2) COLOR=$COLOR_CRIT ;;
  1) COLOR=$COLOR_WARN ;;
  *) COLOR=$COLOR_OK ;;
  esac
}
