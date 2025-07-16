#!/usr/bin/env bash
nodes=(node1 node2 node3 node4)
for s in "${nodes[@]}"; do
  for d in "${nodes[@]}"; do
    [[ $s == $d ]] && continue
    ./ping_ns.sh "$s" "$d" -c 1 -W 1 &>/dev/null \
       && echo "✓ $s → $d" || echo "✗ $s → $d"
  done
done
