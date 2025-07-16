#!/usr/bin/env python3
"""
mini_container.py  ──────────────────────────────────────────────────────────────
A minimal, educational container runtime that mimics a subset of Docker.

Features
────────
• Creates NEW namespaces:  UTS, PID, NET, MNT
• Per-container root filesystem (expects a prepared Ubuntu-20.04 tree)
• Optional memory cgroup limit (MB)  – works on cgroup v1 **and** unified v2
• Interactive bash inside the container appears as PID 1
• Zero external dependencies beyond a standard Linux userspace (Python ≥3.8)

Usage
─────
  sudo python3 mini_container.py run <hostname> [memory_limit_MB]

Example
  sudo python3 mini_container.py run demo 256
"""
import os
import sys
import shutil
import subprocess
from pathlib import Path
import ctypes

# ────────────────────────────────────────────────────────────────────────── util
def die(msg: str, code: int = 1):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(code)

def ensure_root():
    if os.geteuid() != 0:
        die("run me as root (sudo)")

# ────────────────────────────────────────────── low-level: hostname + cgroups
def set_hostname(name: str):
    libc = ctypes.CDLL("libc.so.6")
    if libc.sethostname(name.encode(), len(name)) != 0:
        die("failed to set hostname")

def apply_mem_limit(limit_mb: int, tag: str) -> Path | None:
    """
    Create a throw-away cgroup just for this container.
    Works automatically on both legacy cgroup-v1 and unified cgroup-v2.
    Returns the cgroup path so the parent can optionally clean it up.
    """
    limit_bytes = limit_mb * 1024 * 1024
    cg_root = Path("/sys/fs/cgroup")

    # unified (v2) has `cgroup.controllers`
    if (cg_root / "cgroup.controllers").exists():
        cg = cg_root / f"limit-{tag}"
        cg.mkdir(exist_ok=True)
        (cg / "memory.max").write_text(str(limit_bytes))
        (cg / "memory.swap.max").write_text("0")
        (cg / "cgroup.procs").write_text(str(os.getpid()))
        return cg

    # fallback: v1 “memory” hierarchy
    cg = cg_root / "memory" / f"limit-{tag}"
    cg.mkdir(exist_ok=True)
    (cg / "memory.limit_in_bytes").write_text(str(limit_bytes))
    (cg / "memory.swappiness").write_text("0")
    (cg / "tasks").write_text(str(os.getpid()))
    return cg

# ───────────────────────────────────────────────────────── child container code
def container_init(hostname: str, limit_mb: int | None):
    """
    Runs after the fork, inside the new PID namespace.
    Replaces itself with /bin/bash (PID 1 inside container).
    """
    set_hostname(hostname)

    cg_path = apply_mem_limit(limit_mb, hostname) if limit_mb else None

    # isolate filesystem
    workdir = Path.cwd()
    rootfs = workdir / "Containers" / hostname
    if not rootfs.is_dir():
        die(f"rootfs {rootfs} not found – did you create/populate it?")

    # make mount propagation private, then chroot
    subprocess.check_call(["mount", "--make-rprivate", "/"])
    os.chroot(str(rootfs))
    os.chdir("/")

    # mount /proc so that ps/top etc. work
    (Path("/proc")).mkdir(exist_ok=True)
    subprocess.check_call(["mount", "-t", "proc", "proc", "/proc"])

    # hand over control – becomes PID 1
    os.execv("/bin/bash", ["/bin/bash"])

    # never reached, but good hygiene if we add logic later
    if cg_path and cg_path.exists():
        try:
            cg_path.rmdir()
        except OSError:
            pass

# ─────────────────────────────────────────────────────────────── entry point
def run_container(hostname: str, limit_mb: int | None):
    """
    1. Copy Ubuntu-20.04 base rootfs into Containers/<hostname>   (only once)
    2. Unshare UTS, MNT, PID, NET  namespaces
    3. Fork → child becomes PID 1 in its new PID namespace
    """
    base_root = Path("file_system")                  # Ubuntu 20.04 contents
    target_root = Path("Containers") / hostname
    target_root.mkdir(parents=True, exist_ok=True)

    if not any(target_root.iterdir()):               # populate only first time
        print(f"[+] populating rootfs for {hostname} …")
        if shutil.which("rsync"):
            subprocess.check_call(["rsync", "-a", f"{base_root}/", str(target_root)])
        else:
            shutil.copytree(base_root, target_root, dirs_exist_ok=True)

    flags = (os.CLONE_NEWUTS |
             os.CLONE_NEWNS |
             os.CLONE_NEWPID |
             os.CLONE_NEWNET)

    os.unshare(flags)                                # create the namespaces

    pid = os.fork()
    if pid == 0:                                     # child: actual container
        container_init(hostname, limit_mb)
    else:                                            # parent: wait & cleanup
        _, status = os.waitpid(pid, 0)
        exit_code = os.WEXITSTATUS(status)
        print(f"[+] container exited with code {exit_code}")

        # best-effort cgroup cleanup
        for cg in (Path("/sys/fs/cgroup") / f"limit-{hostname}",
                    Path("/sys/fs/cgroup/memory") / f"limit-{hostname}"):
            if cg.exists():
                try:
                    cg.rmdir()
                except OSError:
                    pass
        sys.exit(exit_code)

def main():
    ensure_root()

    if len(sys.argv) < 3 or sys.argv[1] != "run":
        print("usage: sudo python3 mini_container.py run <hostname> [mem_MB]")
        sys.exit(1)

    host = sys.argv[2]
    mem = int(sys.argv[3]) if len(sys.argv) > 3 else None
    run_container(host, mem)

if __name__ == "__main__":
    main()
