#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Build the Figure-1 namespace topology
# ┌────────┐            ┌─────────┐            ┌────────┐
# │node1   │            │ router  │            │ node3  │
# │172.0.0.2/24 ─┐    ┌─┤17.0.0.1│            │10.10.0.2/24
# └────────┘     │    │ └─────────┘            └────────┘d 
#                │ br1│                           │
# ┌────────┐     │    │                           │
# │node2   │     │    │            br2            │
# │172.0.0.3/24 ─┘    └───────────────────────────┘
# └────────┘                                       │
#                                                ┌────────┐
#                                                │ node4  │
#                                                │10.10.0.3/24
#                                                └────────┘
# -----------------------------------------------------------------------------
set -euo pipefail

# -------- helper --------------------------------------------------------------
cleanup() {
  for ns in router node1 node2 node3 node4; do
    ip netns del "$ns" 2>/dev/null || true
  done
  ip link del br1 2>/dev/null || true
  ip link del br2 2>/dev/null || true
}
die() { echo "Error: $*" >&2; exit 1; }

# -------- build ---------------------------------------------------------------
echo "[*] Cleaning previous run (if any)…"
cleanup

echo "[*] Enabling IPv4 forwarding in the root namespace"
sysctl -qw net.ipv4.ip_forward=1

echo "[*] Creating namespaces"
for ns in router node1 node2 node3 node4; do
  ip netns add "$ns"
done

echo "[*] Creating bridges"
ip link add br1 type bridge
ip link add br2 type bridge
ip link set br1 up
ip link set br2 up

create_veth() {
  local side_a=$1 side_b=$2
  ip link add "$side_a" type veth peer name "$side_b"
}

echo "[*] Creating veth pairs and attaching to namespaces / bridges"
# node1 ↔ br1
create_veth node1-veth br1-veth2
ip link set node1-veth netns node1
ip link set br1-veth2 master br1

# node2 ↔ br1
create_veth node2-veth br1-veth3
ip link set node2-veth netns node2
ip link set br1-veth3 master br1

# node3 ↔ br2
create_veth node3-veth br2-veth2
ip link set node3-veth netns node3
ip link set br2-veth2 master br2

# node4 ↔ br2
create_veth node4-veth br2-veth3
ip link set node4-veth netns node4
ip link set br2-veth3 master br2

# router ↔ br1
create_veth router-veth1 br1-veth1
ip link set router-veth1 netns router
ip link set br1-veth1 master br1

# router ↔ br2
create_veth router-veth2 br2-veth1
ip link set router-veth2 netns router
ip link set br2-veth1 master br2

echo "[*] Assigning IP addresses"
ip -n node1   addr add 172.0.0.2/24 dev node1-veth
ip -n node2   addr add 172.0.0.3/24 dev node2-veth
ip -n router  addr add 172.0.0.1/24 dev router-veth1

ip -n node3   addr add 10.10.0.2/24 dev node3-veth
ip -n node4   addr add 10.10.0.3/24 dev node4-veth
ip -n router  addr add 10.10.0.1/24 dev router-veth2

echo "[*] Bringing all links up"
for ns in node1 node2 node3 node4 router; do
  ip -n "$ns" link set lo up
done

# user namespaces
ip -n node1   link set node1-veth up
ip -n node2   link set node2-veth up
ip -n node3   link set node3-veth up
ip -n node4   link set node4-veth up
ip -n router  link set router-veth1 up
ip -n router  link set router-veth2 up
# root-namespace ports
for p in br1-veth1 br1-veth2 br1-veth3 br2-veth1 br2-veth2 br2-veth3; do
  ip link set "$p" up
done

echo "[*] Setting default gateways"
ip -n node1 route add default via 172.0.0.1
ip -n node2 route add default via 172.0.0.1
ip -n node3 route add default via 10.10.0.1
ip -n node4 route add default via 10.10.0.1

echo "[*] Enabling forwarding inside the router namespace"
ip netns exec router sysctl -qw net.ipv4.ip_forward=1

echo "[✓]   Topology is ready!  Try:"
echo "      ./ping_ns.sh node1 node3"
echo "      ./ping_ns.sh node3 node1"
