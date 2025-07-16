Assignment 2 / Problem 1: Container Networking
Author: Hossein SoleymaniTerm: Spring 2025
This README addresses the written questions for Assignment 2, Problem 1, accompanying the submitted bash scripts (create_topology.sh, ping_ns.sh). No additional code is required.

1. Figure 2 – Post-Router Namespace Deletion
Goal: Ensure the 172.0.0.0/24 LAN (node1, node2) can still communicate with the 10.10.0.0/24 LAN (node3, node4) after the router namespace and its veths are deleted.
Solution: Use the host (root namespace) as the new router.
Steps:

Assign each bridge an IP address within its respective subnet:# In root namespace
ip addr add 172.0.0.254/24 dev br1    # Gateway for 172.0.0.0/24
ip addr add 10.10.0.254/24 dev br2    # Gateway for 10.10.0.0/24


Enable IP forwarding on the host:sysctl -w net.ipv4.ip_forward=1


Configure each node to use its bridge as the default gateway:# In node1 and node2 namespaces
ip route replace default via 172.0.0.254
# In node3 and node4 namespaces
ip route replace default via 10.10.0.254



Why it works: The host now has one interface in each /24 subnet, allowing its kernel to forward packets between them, replicating the functionality of the deleted router namespace. No iptables or NAT rules are needed since both networks use RFC1918 address blocks and are routable as-is.

2. Figure 3 – Namespaces on Two Hosts Sharing the Same Switch
Topology Assumed
┌───────────── Server A ─────────────┐
│ br1   → 172.0.0.0/24              │
│ node1, node2                      │
│ eth0 = A.B.C.D   (same VLAN)      │
└────────────────────────────────────┘
            ▲   Layer-2 switch / vSwitch
            ▼
┌───────────── Server B ─────────────┐
│ br2   → 10.10.0.0/24              │
│ node3, node4                      │
│ eth0 = W.X.Y.Z   (same VLAN)      │
└────────────────────────────────────┘

A. Host-based Static Routing
Keeps the two /24 subnets logically separate with only two host routes added.
Server A (root):
ip addr add 172.0.0.254/24 dev br1          # Gateway for 172.0.0.0/24
sysctl -w net.ipv4.ip_forward=1
ip route add 10.10.0.0/24 via W.X.Y.Z       # W.X.Y.Z = Server B eth0

Server B (root):
ip addr add 10.10.0.254/24 dev br2          # Gateway for 10.10.0.0/24
sysctl -w net.ipv4.ip_forward=1
ip route add 172.0.0.0/24 via A.B.C.D       # A.B.C.D = Server A eth0

Node namespaces (unchanged):

On Server A: node1, node2 → default via 172.0.0.254
On Server B: node3, node4 → default via 10.10.0.254

Packet path (node1 → node3):node1 → br1 → Server A (L3) → switch → Server B (L3) → br2 → node3
Notes: No tunnels are required; only two static routes are added.

B. Flat Layer-2 Extension with VXLAN
Server A:
ip link add vxlan10 type vxlan id 10 \
        local A.B.C.D remote W.X.Y.Z dev eth0 dstport 4789
ip link set vxlan10 master br1
ip link set vxlan10 up

Server B:
ip link add vxlan sulphur type vxlan id 10 \
        local W.X.Y.Z remote A.B.C.D dev eth0 dstport 4789
ip link set vxlan10 master br2
ip link set vxlan10 up

Nodes: Retain their original IPs and default gateways (172.0.0._owned or 10.10.0.254).
Result:

Bridges br1 and br2 form a single broadcast domain.
Node1 can ARP directly for node3, with frames encapsulated in UDP/4789.
No additional routes are needed on either host.
