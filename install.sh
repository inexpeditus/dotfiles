#!/usr/bin/env bash
# Link the dotfiles into $HOME with GNU Stow.
# Usage: ./install.sh [-n] [-R] [package...]   (-n: dry run, -R: remove links)

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

DEFAULT_PACKAGES=(alacritty bash desktop flameshot i3 nvim X11)

flags=(-v --no-folding)
action=(-R)
while getopts "nR" opt; do
  case $opt in
  n) flags+=(-n) ;;
  R) action=(-D) ;;
  *)
    echo "usage: $0 [-n] [-R] [package...]" >&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

packages=("$@")
[ ${#packages[@]} -eq 0 ] && packages=("${DEFAULT_PACKAGES[@]}")

if ! command -v stow >/dev/null; then
  echo "stow not found. Install it first: sudo pacman -S stow" >&2
  exit 1
fi

mkdir -p "$HOME/.config" "$HOME/.local/bin"

failed=()
for pkg in "${packages[@]}"; do
  [ -d "$pkg" ] || {
    echo "no such package: $pkg" >&2
    exit 1
  }
  echo "==> $pkg"
  # Stow never overwrites a real file. A conflict leaves that package alone,
  # so the others still run and every conflict gets reported.
  if ! stow "${flags[@]}" "${action[@]}" -d . -t "$HOME" "$pkg"; then
    failed+=("$pkg")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  echo >&2
  echo "error: these packages conflict with existing files: ${failed[*]}" >&2
  echo "Move the listed files aside (for example: mv ~/.gitconfig ~/.gitconfig.bak) and re-run." >&2
  exit 1
fi
