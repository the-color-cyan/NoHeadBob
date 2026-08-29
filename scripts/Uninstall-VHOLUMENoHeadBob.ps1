[CmdletBinding()]
param(
    [string]$GameDirectory,
    [switch]$KeepUE4SS,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modName = 'NoHeadBob'
$manifestName = '.NoHeadBob-install.json'

function Resolve-GameDirectory {
    param([string]$Candidate)

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        $Candidate = Read-Host 'Paste the VHOLUME install root (the folder containing VHOLUME.exe and the VHOLUME folder)'
    }

    $root = (Resolve-Path -LiteralPath $Candidate).Path
    $gameDirectory = Join-Path $root 'VHOLUME\Binaries\Win64'
    $gameExe = Join-Path $gameDirectory 'VHOLUME-Win64-Shipping.exe'

    if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) {
        throw "Game executable not found: $gameExe`nChoose the VHOLUME install root, not its Binaries\\Win64 subfolder."
    }

    return $gameDirectory
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
$ue4ssRoot = Join-Path $target 'ue4ss'
$modsFile = Join-Path $ue4ssRoot 'Mods\mods.txt'
$targetMod = Join-Path $ue4ssRoot "Mods\$modName"
$manifestPath = Join-Path $target $manifestName

Disable-Mod $modsFile
if (Test-Path -LiteralPath $targetMod) {
    Remove-Item -LiteralPath $targetMod -Recurse -Force
}

Write-Host 'Removed the NoHeadBob mod and its mods.txt entry.' -ForegroundColor Green

if ($KeepUE4SS) {
    Write-Host 'UE4SS was kept because -KeepUE4SS was specified.'
    exit 0
}

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Cannot safely remove UE4SS: install manifest not found at $manifestPath"
}

if (-not $Force) {
    $answer = Read-Host 'This will remove Win64\ue4ss and Win64\dwmapi.dll, then restore any pre-install backup. Continue? [y/N]'
    if ($answer -notmatch '^(?i)y(es)?$') {
        Write-Host 'UE4SS removal cancelled. The NoHeadBob mod itself was removed.'
        exit 0
    }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$backupPath = [string]$manifest.BackupPath

if (Test-Path -LiteralPath $ue4ssRoot) {
    Remove-Item -LiteralPath $ue4ssRoot -Recurse -Force
}

$proxyPath = Join-Path $target 'dwmapi.dll'
if (Test-Path -LiteralPath $proxyPath -PathType Leaf) {
    Remove-Item -LiteralPath $proxyPath -Force
}

if ([bool]$manifest.HadProxy) {
    $proxyBackup = Join-Path $backupPath 'dwmapi.dll'
    if (Test-Path -LiteralPath $proxyBackup -PathType Leaf) {
        Copy-Item -LiteralPath $proxyBackup -Destination $proxyPath -Force
    }
}

if ([bool]$manifest.HadUE4SSRoot) {
    $rootBackup = Join-Path $backupPath 'ue4ss'
    if (Test-Path -LiteralPath $rootBackup -PathType Container) {
        Copy-Item -LiteralPath $rootBackup -Destination $ue4ssRoot -Recurse -Force
    }
}

if (Test-Path -LiteralPath $backupPath) {
    Remove-Item -LiteralPath $backupPath -Recurse -Force
}
Remove-Item -LiteralPath $manifestPath -Force

Write-Host 'Removed UE4SS installed by this package and restored any pre-install UE4SS files.' -ForegroundColor Green
