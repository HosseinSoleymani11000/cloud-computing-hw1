#!/usr/bin/env bash
set -euo pipefail

[[ $# -lt 2 ]] && { echo "Usage: $0 <src> <dst> [ping-opts…]"; exit 1; }

src=$1; dst_name=$2; shift 2
declare -A addr=(
  [node1]=172.0.0.2 [node2]=172.0.0.3
  [node3]=10.10.0.2 [node4]=10.10.0.3
  [router1]=172.0.0.1 [router2]=10.10.0.1 [router]=172.0.0.1
)
ip_dst=${addr[$dst_name]:-} || { echo "Unknown dst $dst_name"; exit 1; }

ip netns exec "$src" ping ${*:- -c 4} "$ip_dst"
