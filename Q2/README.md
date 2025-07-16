# Container Runtime (Problem 2)


## One-time setup


Populate file_system/

mkdir -p file_system
docker rm -f ubuntufs 2>/dev/null || true
docker create --name ubuntufs ubuntu:20.04
docker export ubuntufs | tar -C file_system -xvf -
docker rm ubuntufs

stress tool or htop inside every container for testing the limitation for each container 

sudo chroot file_system /bin/bash -c "apt update && apt install -y stress htop"


## Running a container

# Syntax
sudo python3.12 mini_container.py run <hostname> [memory_MB]

Example: 256 MB-limited container named “demo”
sudo python3.12 mini_container.py run demo 256

Manual verification checklist

hostname                         # → demo
ps fax | grep bash               # see /bin/bash at PID 1
mount | grep '^proc on /proc '   # /proc is mounted
echo test > /tmp/in_container    # create a file
stress --vm 1 --vm-bytes 512M --vm-keep -t 10s   # killed if limit is 256


