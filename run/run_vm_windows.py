#!/usr/bin/env python3
"""Experimental native Windows ARM64 launcher for a locally built Googlebook VM."""

import argparse
import os
import shutil
import subprocess
import sys

DEFAULT_MEMORY_MIB = 4096
DEFAULT_CPUS = 4
DEFAULT_DISPLAY = "1920x1200"


def find_qemu():
    qemu = shutil.which("qemu-system-aarch64")
    if not qemu:
        raise SystemExit(
            "qemu-system-aarch64 was not found. Install a Windows ARM64 QEMU build "
            "with WHPX support and add it to PATH."
        )
    return qemu


def find_firmware(qemu):
    candidates = [
        os.path.join(os.path.dirname(qemu), "edk2-aarch64-code.fd"),
        os.path.join(os.path.dirname(qemu), "share", "qemu", "edk2-aarch64-code.fd"),
        "/usr/share/qemu/edk2-aarch64-code.fd",
        "/usr/share/AAVMF/AAVMF_CODE.fd",
    ]
    for path in candidates:
        if os.path.exists(path):
            return path
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("image_dir", nargs="?", default="work/image")
    parser.add_argument("--display", default=DEFAULT_DISPLAY)
    parser.add_argument("--memory", type=int, default=DEFAULT_MEMORY_MIB)
    parser.add_argument("--cpus", type=int, default=DEFAULT_CPUS)
    parser.add_argument("--fullscreen", action="store_true")
    parser.add_argument("--tcg", action="store_true", help="Force QEMU TCG instead of WHPX")
    parser.add_argument("--no-audio", action="store_true")
    args = parser.parse_args()

    qemu = find_qemu()
    accelerator = "tcg" if args.tcg else "whpx"

    disk = os.path.join(args.image_dir, "googlebook.raw")
    if not os.path.exists(disk):
        raise SystemExit(f"VM disk not found: {disk}")

    cmd = [
        qemu,
        "-machine", "virt",
        "-cpu", "host" if accelerator == "whpx" else "cortex-a76",
        "-accel", accelerator,
        "-smp", str(args.cpus),
        "-m", str(args.memory),
        "-drive", f"file={disk},format=raw,if=virtio",
        "-device", "ramfb",
        "-device", "virtio-keyboard-pci",
        "-device", "virtio-mouse-pci",
        "-device", "virtio-net-pci,netdev=net0",
        "-netdev", "user,id=net0",
        "-display", "sdl,gl=off",
    ]

    firmware = find_firmware(qemu)
    if firmware:
        cmd += ["-bios", firmware]
    else:
        print(
            "Warning: edk2-aarch64-code.fd was not found beside QEMU. "
            "The VM may remain at a blank display without ARM64 UEFI firmware.",
            file=sys.stderr,
        )

    if args.fullscreen:
        cmd += ["-full-screen"]
    if not args.no_audio:
        cmd += ["-audiodev", "dsound,id=snd0", "-device", "virtio-sound-pci,audiodev=snd0"]

    print(" ".join(cmd))
    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        raise SystemExit("Failed to launch QEMU.")
    except subprocess.CalledProcessError as exc:
        if accelerator == "whpx":
            print(
                "WHPX launch failed. Verify that Windows Hypervisor Platform is enabled, "
                "Windows is 24H2 build 26100.3915+, and QEMU includes ARM64 WHPX support.",
                file=sys.stderr,
            )
        raise SystemExit(exc.returncode)


if __name__ == "__main__":
    main()
