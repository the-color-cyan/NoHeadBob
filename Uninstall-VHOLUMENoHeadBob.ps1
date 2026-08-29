[CmdletBinding()]
param(
    [string]$GameDirectory,
    [switch]$RemoveUE4SS
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modName = 'NoHeadBob'
$manifestName = '.NoHeadBob-install.json'

function Resolve-GameDirectory {
    param([string]$Candidate)

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        $Candidate = Read-Host 'Paste the folder containing VHOLUME-Win64-Shipping.exe'
    }

    $resolved = (Resolve-Path -LiteralPath $Candidate).Path
    $gameExe = Join-Path $resolved 'VHOLUME-Win64-Shipping.exe'

    if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) {
        throw "Game executable not found: $gameExe`nChoose the game's VHOLUME\Binaries\Win64 folder."
    }

    return $resolved
}

function Disable-Mod {
    param([string]$ModsFile)

    if (-not (Test-Path -LiteralPath $ModsFile -PathType Leaf)) {
        return
    }

    $remaining = @(Get-Content -LiteralPath $ModsFile | Where-Object {
        $_ -notmatch '^\s*NoHeadBob\s*:'
    })

    Set-Content -LiteralPath $ModsFile -Value $remaining -Encoding UTF8
}

$target = Resolve-GameDirectory $GameDirectory
$modsFile = Join-Path $target 'Mods\mods.txt'
$targetMod = Join-Path $target "Mods\$modName"
$manifestPath = Join-Path $target $manifestName

Disable-Mod $modsFile
if (Test-Path -LiteralPath $targetMod) {
    Remove-Item -LiteralPath $targetMod -Recurse -Force
}

Write-Host 'Removed the NoHeadBob mod and its mods.txt entry.' -ForegroundColor Green

if (-not $RemoveUE4SS) {
    Write-Host 'UE4SS was left installed. To remove both this mod and UE4SS, re-run with -RemoveUE4SS.'
    exit 0
}

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Cannot safely remove UE4SS: install manifest not found at $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$backupPath = [string]$manifest.BackupPath
$backedUpCoreFiles = @($manifest.BackedUpCoreFiles)
$coreFiles = @($manifest.CoreFiles)

foreach ($file in $coreFiles) {
    $installedFile = Join-Path $target $file
    if (Test-Path -LiteralPath $installedFile -PathType Leaf) {
        Remove-Item -LiteralPath $installedFile -Force
    }

    if ($backedUpCoreFiles -contains $file) {
        $backupFile = Join-Path $backupPath $file
        if (Test-Path -LiteralPath $backupFile -PathType Leaf) {
            Copy-Item -LiteralPath $backupFile -Destination $installedFile -Force
        }
    }
}

if (Test-Path -LiteralPath $backupPath) {
    Remove-Item -LiteralPath $backupPath -Recurse -Force
}
Remove-Item -LiteralPath $manifestPath -Force

Write-Host 'Removed UE4SS core files installed by this package and restored any files backed up during installation.' -ForegroundColor Green
Write-Host 'The Mods directory and UE4SS cache were intentionally left in place to avoid deleting unrelated user mods or data.'
