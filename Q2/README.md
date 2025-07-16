# Assignment 2 / Problem 2: Container Runtime
**Author**: Hossein Soleymani  
**Term**: Spring 2025

This README documents the setup and usage instructions for the container runtime environment as specified in Problem 2, accompanying the submitted Python script (`mini_container.py`).

---

## One-time Setup

Create and populate the `file_system/` directory with a base Ubuntu 20.04 filesystem, and install `stress` and `htop` for testing container resource limits.

**Commands**:
```bash
# Create file_system directory
mkdir -p file_system

# Remove any existing ubuntufs container
docker rm -f ubuntufs 2>/dev/null || true

# Create a temporary container to export the Ubuntu 20.04 filesystem
docker create --name ubuntufs ubuntu:20.04
docker export ubuntufs | tar -C file_system -xvf -
docker rm ubuntufs

# Install stress and htop in the filesystem
sudo chroot file_system /bin/bash -c "apt update && apt install -y stress htop"
```

**Purpose**:
- Sets up a minimal Ubuntu 20.04 filesystem in `file_system/`.
- Installs `stress` and `htop` for testing memory limits and process monitoring within containers.

---

## Running a Container

**Syntax**:
```bash
sudo python3.12 mini_container.py run <hostname> [memory_MB]
```

**Example**:
Launch a container named "demo" with a 256 MB memory limit:
```bash
sudo python3.12 mini_container.py run demo 256
```

**Description**:
- The `mini_container.py` script runs a container with the specified hostname and optional memory limit (in MB).
- The container uses the prepared `file_system/` as its root filesystem.
- The container runs `/bin/bash` as PID 1, with a properly mounted `/proc` filesystem and isolated namespaces.

---

## Manual Verification Checklist

After running the container, verify its functionality with the following checks:

1. **Hostname**:
   ```bash
   hostname
   ```
   - Expected output: `demo` (or the specified hostname).

2. **Check for `/bin/bash` as PID 1**:
   ```bash
   ps fax | grep bash
   ```
   - Expected output: Shows `/bin/bash` running as PID 1.

3. **Verify `/proc` mount**:
   ```bash
   mount | grep '^proc on /proc '
   ```
   - Expected output: Confirms `/proc` is mounted.

4. **Test file creation**:
   ```bash
   echo test > /tmp/in_container
   ```
   - Expected outcome: Creates a file `/tmp/in_container` in the container's filesystem.

5. **Test memory limit**:
   ```bash
   stress --vm 1 --vm-bytes 512M --vm-keep -t 10s
   ```
   - Expected outcome: If the memory limit is set to 256 MB, the `stress` command should be killed due to exceeding the memory limit.

**Notes**:
- Use `htop` inside the container to monitor resource usage if needed.
- The memory limit (`[memory_MB]`) is optional; if omitted, the container runs without a memory cap.
