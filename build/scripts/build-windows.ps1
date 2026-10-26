#Requires -Version 5.1
# hcc only emits Linux and macOS binaries, so on Windows the game is built
# and run inside WSL2. WSLg (Windows 11, or Windows 10 21H2+) shows the
# window on the Windows desktop with GPU-backed OpenGL.
param(
    [switch]$Test,
    [switch]$Run,
    [string]$Distro = ""
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Write-Error "wsl.exe not found. Install WSL2 first: wsl --install (see docs/setup.md)"
}

$wslArgs = @()
if ($Distro -ne "") {
    $wslArgs += @("-d", $Distro)
}

function Invoke-Wsl([string[]]$Command) {
    & wsl.exe @wslArgs --cd $root @Command
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Invoke-Wsl @("bash", "build/scripts/build-linux.sh")

if ($Test) {
    Invoke-Wsl @("bash", "build/scripts/test.sh")
}

if ($Run) {
    Invoke-Wsl @("./build/out/ossuary")
}
