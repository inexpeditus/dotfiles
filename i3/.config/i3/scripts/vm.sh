#!/usr/bin/env bash
# Running libvirt VMs for i3blocks: name, CPU load and host memory of each.
#
# CPU is the delta of each VM's cumulative cpu.time between two runs (kept in
# $XDG_RUNTIME_DIR), averaged over its vCPUs. Memory is the resident set of the
# QEMU process on the host, so it needs no guest agent.
# The block is hidden while no matching VM is running.

source "$(dirname "$0")/lib.sh"

URI="${URI:-qemu:///system}"
PATTERN="${PATTERN:-*}" # glob of VM names to include
COLOR_VM="#e6c35c"
state="${XDG_RUNTIME_DIR:-/tmp}/i3blocks-vm"

# One "name cpu_ns rss_kib vcpus" line per running domain.
stats=$(virsh -c "$URI" domstats --list-running --cpu-total --balloon --vcpu 2>/dev/null |
  awk '
    function flush() { if (name != "") print name, ns, rss, vcpus }
    /^Domain:/ { flush(); name = $2; gsub(/\x27/, "", name); ns = rss = 0; vcpus = 1 }
    /^ *cpu\.time=/ { split($0, a, "="); ns = a[2] }
    /^ *balloon\.rss=/ { split($0, a, "="); rss = a[2] }
    /^ *vcpu\.current=/ { split($0, a, "="); vcpus = a[2] }
    END { flush() }
  ')

# Previous run: one "name cpu_ns time_ns" line per VM.
declare -A prev_ns prev_t
if [[ -r $state ]]; then
  while read -r name ns t; do
    [[ -n $name ]] && prev_ns[$name]=$ns prev_t[$name]=$t
  done <"$state"
fi

now=$(date +%s%N)
sep=" <span color='$COLOR_DIM'>|</span> "
full='' short='' saved=''
while read -r name ns rss vcpus; do
  [[ -n $name ]] || continue
  # shellcheck disable=SC2254 # PATTERN is meant to be a glob
  case $name in $PATTERN) ;; *) continue ;; esac

  cpu=0
  if [[ -n ${prev_ns[$name]} ]]; then
    dt=$((now - prev_t[$name]))
    if ((dt > 0 && ns >= prev_ns[$name] && vcpus > 0)); then
      cpu=$(((ns - prev_ns[$name]) * 100 / (dt * vcpus)))
      ((cpu > 100)) && cpu=100
    fi
  fi
  saved+="$name $ns $now"$'\n'
  label=$(escape "$name")
  full+="${full:+$sep}$label $cpu% $(human $((rss * 1024)))"
  short+="${short:+, }$label"
done <<<"$stats"

if [[ -z $full ]]; then
  rm -f "$state"
  echo
  exit 0
fi
printf '%s' "$saved" >"$state"

echo "$full"
echo "$short"
echo "$COLOR_VM"
