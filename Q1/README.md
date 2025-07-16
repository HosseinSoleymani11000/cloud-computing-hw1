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
2. **Enable IP forwarding**]
   ```bash
   sysctl -w net.ipv4.ip_forward=1
3. **Point each node at its bridge as default gateway**
   ```bash
   # node1 + node2 namespaces
   ip route replace default via 172.0.0.254

   # node3 + node4 namespaces
   ip route replace default via 10.10.0.254

   
Why it works ?? 
The host now owns one interface in each /24, so its kernel forwards packets just like the old router namespace did. No iptables or NAT rules are needed because both are RFC 1918 networks and routable as-is.

# Figure 3 – Namespaces on TWO Hosts Sharing the Same Switch
Topology Assumed
┌─────────────────── Server A ───────────────────┐
│ br1 → 172.0.0.0/24                             │
│ node1, node2                                  │
│ eth0 = A.B.C.D (same VLAN)                     │
└────────────────────────────────────────────────┘
              ▲ Layer-2 switch / vSwitch ▼
┌─────────────────── Server B ───────────────────┐
│ br2 → 10.10.0.0/24                             │
│ node3, node4                                  │
│ eth0 = W.X.Y.Z (same VLAN)                     │
└────────────────────────────────────────────────┘
