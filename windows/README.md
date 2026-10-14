# Native Windows ARM64 WHPX target

Experimental support for running the locally built Googlebook OS VM on a native Windows ARM64 host using QEMU with the Windows Hypervisor Platform (WHPX) accelerator.

## Requirements

- Windows 11 ARM64, version 24H2 build 26100.3915 or newer
- Windows Hypervisor Platform optional feature enabled
- QEMU built for Windows ARM64 with WHPX support
- At least 60 GB free disk space
- The official mica recovery ZIP downloaded locally; do not commit or redistribute it

## Setup

1. Open PowerShell as Administrator.
2. Run `windows/setup-whpx.ps1`.
3. Download the mica recovery image and place it under `downloads/`.
4. Build or obtain the image using the existing Linux build flow, then use `run/run_vm_windows.py` on Windows.

## Current limitations

- Graphics uses a non-GL fallback; Venus/virglrenderer and dma-buf-based acceleration are Linux-specific.
- Audio is disabled by default.
- This is a boot-diagnostic milestone, not a validated daily-driver configuration.
- WHPX does not support SVE or SME.

## References

- QEMU WHPX documentation: https://www.qemu.org/docs/master/system/whpx.html
- Microsoft WHP API: https://learn.microsoft.com/en-us/virtualization/api/hypervisor-platform/hypervisor-platform
