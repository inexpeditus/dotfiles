# Shared helpers for the i3blocks scripts. Source this file, don't run it.

COLOR_OK="#a4d280"
COLOR_WARN="#f0a050"
COLOR_CRIT="#e05050"
COLOR_DIM="#888888"
COLOR_ACCENT="#ef8513" # the accent from the i3 config

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

# human BYTES
# Prints a short size, with one decimal below 10: 512B, 12K, 1.2M or 340M.
human() {
  local b=$1 unit=1073741824 suffix tenths
  for suffix in G M K; do
    if ((b >= unit)); then
      tenths=$((b * 10 / unit))
      if ((tenths < 100)); then
        echo "$((tenths / 10)).$((tenths % 10))$suffix"
      else
        echo "$((b / unit))$suffix"
      fi
      return
    fi
    unit=$((unit / 1024))
  done
  echo "${b}B"
}

# escape TEXT
# Escapes TEXT for blocks with markup=pango.
escape() {
  local s=$1
  s=${s//&/'&amp;'} s=${s//</'&lt;'} s=${s//>/'&gt;'}
  echo "$s"
}
