# Assignment 2 / Problem 1: Container Networking

**Hossein Soleymani — Spring 2025**

This document answers the written questions that accompany the two Bash scripts I submitted (`create_topology.sh`, `ping_ns.sh`). No further code is needed.

---

## 1. Figure 2 – What happens after deleting the router namespace

**Goal**  
The `172.0.0.0/24` LAN (node1, node2) must still talk to `10.10.0.0/24` (node3, node4) even though the dedicated router namespace and its veths are gone.

**Solution**  
Make the host itself (root namespace) the new router:

1. **Assign bridge IPs** (root namespace)  
   ```bash
   ip addr add 172.0.0.254/24 dev br1     # gateway for 172.0.0.0/24
   ip addr add 10.10.0.254/24 dev br2     # gateway for 10.10.0.0/24


 Turn on forwarding once for the whole host  
  ```
  sysctl -w net.ipv4.ip_forward=1
  ```

 Tell every node to use its bridge as the default-gw  
  ```
  # in node1 + node2 namespaces
  ip route replace default via 172.0.0.254
  # in node3 + node4 namespaces
  ip route replace default via 10.10.0.254
  ```

Why it works ?? The host now owns *one interface in each /24*,
so its kernel can forward packets between them exactly like the
old router namespace did.  
No iptables or NAT rules are necessary because both networks are
RFC1918 address blocks and are routable as-is.


────────────────────────────────────────────────────────────────
2 .  Figure 3 ─ Namespaces on TWO Hosts Sharing the Same Switch
────────────────────────────────────────────────────────────────

──────────────────────────────────────────────────────────
Topology Assumed
──────────────────────────────────────────────────────────
              ┌───────────── Server A ─────────────┐
              │ br1   → 172.0.0.0/24               │
              │ node1, node2                       │
              │ eth0 = A.B.C.D   (same VLAN)       │
              └─────────────────────────────────────┘
                           ▲   Layer-2 switch / vSwitch
                           ▼
              ┌───────────── Server B ─────────────┐
              │ br2   → 10.10.0.0/24               │
              │ node3, node4                       │
              │ eth0 = W.X.Y.Z   (same VLAN)       │
              └─────────────────────────────────────┘

──────────────────────────────────────────────────────────
A.  Host-based Static Routing
──────────────────────────────────────────────────────────
*Keeps the two /24s logically separate.  Only two host routes are added.*

Server A (root)  
ip addr add 172.0.0.254/24 dev br1          # gateway for 172/24  
sysctl -w net.ipv4.ip_forward=1  
ip route add 10.10.0.0/24 via W.X.Y.Z       # W.X.Y.Z = Server B eth0  

Server B (root)  
ip addr add 10.10.0.254/24 dev br2          # gateway for 10/24  
sysctl -w net.ipv4.ip_forward=1  
ip route add 172.0.0.0/24 via A.B.C.D       # A.B.C.D = Server A eth0  

Node namespaces (unchanged)  
  on Server A node1,node2 → default via 172.0.0.254  
  on Server B node3,node4 → default via 10.10.0.254  

Packet path (node1 → node3)  
node1 → br1 → Server A-L3 → switch → Server B-L3 → br2 → node3  

No tunnels; just two static routes.

──────────────────────────────────────────────────────────
B. Flat Layer-2 Extension with VXLAN
──────────────────────────────────────────────────────────
Server A  

ip link add vxlan10 type vxlan id 10 \
        local A.B.C.D remote W.X.Y.Z dev eth0 dstport 4789  
ip link set vxlan10 master br1  
ip link set vxlan10 up  

Server B  

ip link add vxlan10 type vxlan id 10 \
        local W.X.Y.Z remote A.B.C.D dev eth0 dstport 4789  
ip link set vxlan10 master br2  
ip link set vxlan10 up  

Nodes keep the same IPs and default gateways (172.0.0.254 or 10.10.0.254).  

Result  
• br1 + br2 now form a single broadcast domain.  
• node1 ARPs directly for node3; frames ride inside UDP/4789.  
• Zero extra routes on either host.  

