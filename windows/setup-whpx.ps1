# Experimental setup for native Windows ARM64 WHPX support.
# Run from an elevated PowerShell prompt.

$ErrorActionPreference = 'Stop'

Write-Host 'Checking Windows edition and architecture...'
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "OS: $($os.Caption)"
Write-Host "Architecture: $($env:PROCESSOR_ARCHITECTURE)"

if ($env:PROCESSOR_ARCHITECTURE -ne 'ARM64') {
    Write-Warning 'This script is intended for native Windows ARM64 hosts.'
}

Write-Host 'Enabling Windows Hypervisor Platform...'
$feature = Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform
if ($feature.State -ne 'Enabled') {
    Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -NoRestart
    Write-Host 'A restart is required to finish enabling WHPX.'
} else {
    Write-Host 'Windows Hypervisor Platform is already enabled.'
}

New-Item -ItemType Directory -Force -Path 'downloads', 'work' | Out-Null

$recovery = 'https://dl.google.com/device/recovery/mica-user/16471258/recovery.zip'
$dest = 'downloads/mica-user-16471258-recovery.zip'

if (-not (Test-Path $dest)) {
    Write-Host "Downloading mica recovery to $dest..."
    Invoke-WebRequest -Uri $recovery -OutFile $dest
}

Write-Host 'Recovery image ready.'
Write-Host 'Next: build the VM image with the Linux/Nix flow, then launch it with run/run_vm_windows.py.'
