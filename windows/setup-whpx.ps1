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

$recoveryUrl = 'https://dl.google.com/device/recovery/mica-user/16471258/recovery.zip'
$dest = Join-Path (Get-Location) 'downloads/mica-user-16471258-recovery.zip'

function Get-RecoveryImage {
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue

    if ($curl) {
        Write-Host "Downloading recovery image with curl.exe to $dest..."
        & $curl.Source -L --fail --progress-bar --output $dest $recoveryUrl
        if ($LASTEXITCODE -eq 0 -and (Test-Path $dest)) {
            return $true
        }
        Write-Warning "curl.exe download failed with exit code $LASTEXITCODE."
        if (Test-Path $dest) { Remove-Item $dest -Force }
    } else {
        Write-Warning 'curl.exe was not found.'
    }

    Write-Host 'Opening the recovery download in your default browser...'
    Write-Host "Save the file as: $dest"
    Start-Process $recoveryUrl

    Write-Host 'Waiting for the download to complete...'
    while (-not (Test-Path $dest)) {
        Start-Sleep -Seconds 2
    }

    Write-Host "Found $dest."
    return $true
}

Get-RecoveryImage | Out-Null

Write-Host 'Recovery image ready.'
Write-Host 'Next: build the VM image with the Linux/Nix flow, then launch it with run/run_vm_windows.py.'
