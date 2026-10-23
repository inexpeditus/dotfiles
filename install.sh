#!/usr/bin/env bash
# Set up a fresh Arch install: switch networking to NetworkManager, install
# packages.txt, copy etc/ into /etc, then link the dotfiles into $HOME with
# GNU Stow.
# Usage: ./install.sh [-l] [-n] [-R] [package...]
#   -l: link only (skip networking, packages and system files)
#   -n: dry run of the linking (implies -l)
#   -R: remove links (implies -l)

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

DEFAULT_PACKAGES=(alacritty bash desktop flameshot i3 nvim X11)

flags=(-v --no-folding)
action=(-R)
link_only=false
while getopts "lnR" opt; do
  case $opt in
  l) link_only=true ;;
  n)
    flags+=(-n)
    link_only=true
    ;;
  R)
    action=(-D)
    link_only=true
    ;;
  *)
    echo "usage: $0 [-l] [-n] [-R] [package...]" >&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

setup_network() {
  echo "==> networking"
  # Installing NetworkManager needs whatever connection got us online so far
  # (iwd or systemd-networkd), so switch over only once it is installed.
  command -v nmcli >/dev/null || sudo pacman -Syu --needed networkmanager
  sudo systemctl disable --now systemd-networkd.socket systemd-networkd iwd 2>/dev/null || true
  sudo systemctl enable --now NetworkManager

  if [ "$(nmcli -t -f STATE general)" = connected ]; then
    echo "already connected"
    return
  fi

  nmcli device wifi list --rescan yes || true
  while true; do
    read -rp "Wi-Fi network (SSID), empty to skip: " ssid
    [ -z "$ssid" ] && return
    nmcli device wifi connect "$ssid" --ask && return
    echo "could not connect to '$ssid', try again" >&2
  done
}

install_packages() {
  echo "==> packages"
  # Strip comments and blank lines.
  mapfile -t pkgs < <(sed 's/#.*//; /^[[:space:]]*$/d' packages.txt)
  sudo pacman -Syu --needed "${pkgs[@]}"
}

install_system_files() {
  echo "==> system files"
  # Stow only links into $HOME, so files under etc/ are copied into /etc.
  mapfile -t files < <(cd etc && find . -type f)
  for f in "${files[@]}"; do
    sudo install -Dm644 "etc/$f" "/etc/$f"
  done
  sudo systemctl enable --now tlp
}

if ! $link_only; then
  setup_network
  install_packages
  install_system_files
fi

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
