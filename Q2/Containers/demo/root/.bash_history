which stress htop
cat /sys/fs/cgroup/memory/limit_in_bytes 
cat /sys/fs/cgroup/memory.max 
mkdir -p /sys/fs/cgroup/memory
mount -t cgroup -o memory memory /sys/fs/cgroup/memory
cat /sys/fs/cgroup/memory/limit_in_bytes
mkdir -p /sys/fs/cgroup
mount -t cgroup2 none /sys/fs/cgroup
cat /sys/fs/cgroup/memory.max
ls -l
which htop
ps auxf | grep "[m]ini_container.py run demo"
pgrep -f "mini_container.py run demo"
sudo mount --bind /sys/fs/cgroup /proc/5678/root/sys/fs/cgrou
mount --bind /sys/fs/cgroup /proc/5678/root/sys/fs/cgroup
htop
cat /sys/fs/cgroup/memory.max
cat /sys/fs/cgroup/memory/limit_in_bytes
htop
mkdir -p /sys/fs/cgroup/memory
mount -t cgroup -o memory memory /sys/fs/cgroup/memory
cat /sys/fs/cgroup/memory/limit_in_bytes
mkdir -p /sys/fs/cgroup
mount -t cgroup2 none /sys/fs/cgroup
cat /sys/fs/cgroup/memory.max
sudo mount --bind /sys/fs/cgroup /proc/5678/root/sys/fs/cgroup
cat /proc/self/cgroup
cat /sys/fs/cgroup/limit-demo/memory.max
cat /sys/fs/cgroup/memory/limit-demo/memory.limit_in_bytes
ls -l
cat /sys/fs/cgroup/memory/limit-demo/memory.limit_in_bytes
exit
touch /inside_demo
ping -c1 8.8.8.8
exit
ps fax 
hostname
mount | grep '^proc on /proc '
ping -c1 8.8.8.8
echo test > /tmp/in_container.txt
test -f /tmp/in_container.txt && echo "leaked" || echo "rootfs isolated"
stress --vm 1 --vm-bytes 512M --vm-keep -t 10s
exit
apt update && apt install -y iputils-ping 
ping -c1 8.8.8.8 
# inside
mkdir -p /sys/fs/cgroup
mount -t cgroup2 none /sys/fs/cgroup 2>/dev/null || mount -t cgroup -o memory memory /sys/fs/cgroup/memory
cat /sys/fs/cgroup/memory.max 2>/dev/null || cat /sys/fs/cgroup/memory/limit_in_bytes
# → 268435456
# already inside root@demo:/#
mkdir -p /sys/fs/cgroup
mount -t cgroup2 none /sys/fs/cgroup 2>/dev/null || true
# show the 256 MB ceiling
cat /sys/fs/cgroup/limit-demo/memory.max
# → 268435456
stress --vm 1 --vm-bytes 512M --vm-keep -t 10s
python3 - <<'PY'
import time, sys
try:
    a = bytearray(400*1024*1024)  # 400 MB > 256 MB cap

except MemoryError:
    print("MemoryError – limit works")
else:
    print("allocation survived – limit FAILED")
PY

stress --vm 1 --vm-bytes 512M --vm-keep -t 10s
which stress python3
ps fax | grep bash
mount | grep '^proc on /proc '
ls -l /proc/self/ns
echo inside > /tmp/container.txt
test -f /tmp/container.txt && echo leaked || echo rootfs isolated
stress --vm 1 --vm-bytes 512M --vm-keep -t 10s
clear
hostname
exit
hostname
ps fax 
mount | grep '^proc on /proc '
echo hello > /root/inside.txt
cat /sys/fs/cgroup/memory.max
mkdir -p /sys/fs/cgroup
mount -t cgroup2 none /sys/fs/cgroup
cat /sys/fs/cgroup/memory.max
stress --vm 1 --vm-bytes 512M --vm-keep -t 10s
stress --vm 1 --vm-bytes 250M --vm-keep -t 10s
clear
exit
hostname
ps fax 
stress --vm 1 --vm-bytes 250M --vm-keep -t 10s
stress --vm 1 --vm-bytes 512M --vm-keep -t 10s
exit
