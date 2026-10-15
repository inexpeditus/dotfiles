#!/usr/bin/env bash
# Running libvirt VMs for i3blocks: name, CPU load and host memory.
#
# CPU is the delta of cumulative cpu.time between two runs (kept in
# $XDG_RUNTIME_DIR), averaged over the vCPUs. Memory is the resident set of the
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

names=()
sum_ns=0 sum_rss=0 sum_vcpus=0
while read -r name ns rss vcpus; do
  [[ -n $name ]] || continue
  # shellcheck disable=SC2254 # PATTERN is meant to be a glob
  case $name in $PATTERN) ;; *) continue ;; esac
  names+=("$name")
  sum_ns=$((sum_ns + ns))
  sum_rss=$((sum_rss + rss))
  sum_vcpus=$((sum_vcpus + vcpus))
done <<<"$stats"

if ((${#names[@]} == 0)); then
  rm -f "$state"
  echo
  exit 0
fi

now=$(date +%s%N)
cpu=0
if [[ -r $state ]]; then
  read -r prev_ns prev_t <"$state"
  dt=$((now - prev_t))
  if ((dt > 0 && sum_ns >= prev_ns && sum_vcpus > 0)); then
    cpu=$(((sum_ns - prev_ns) * 100 / (dt * sum_vcpus)))
    ((cpu > 100)) && cpu=100
  fi
fi
echo "$sum_ns $now" >"$state"

# KiB to a short human string: 1.2G or 512M.
if ((sum_rss >= 1048576)); then
  mem="$((sum_rss * 10 / 1048576 / 10)).$((sum_rss * 10 / 1048576 % 10))G"
else
  mem="$((sum_rss / 1024))M"
fi

if ((${#names[@]} == 1)); then
  label=${names[0]}
else
  label="${#names[@]} VMs"
fi

echo "${label} ${cpu}% ${mem}"
echo "${label}"
echo "$COLOR_VM"
