[CmdletBinding()]
param(
    [string]$GameDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modName = 'NoHeadBob'
$scriptRoot = $PSScriptRoot
$modSource = Join-Path $scriptRoot "Mods\$modName"
$manifestName = '.NoHeadBob-install.json'
$releaseApi = 'https://api.github.com/repos/UE4SS-RE/RE-UE4SS/releases/tags/experimental-latest'

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

function Enable-Mod {
    param([string]$ModsFile)

    $lines = if (Test-Path -LiteralPath $ModsFile) {
        @(Get-Content -LiteralPath $ModsFile)
    } else {
        @()
    }

    $found = $false
    $updated = foreach ($line in $lines) {
        if ($line -match '^\s*NoHeadBob\s*:') {
            $found = $true
            'NoHeadBob : 1'
        } else {
            $line
        }
    }

    if (-not $found) {
        $updated += 'NoHeadBob : 1'
    }

    Set-Content -LiteralPath $ModsFile -Value $updated -Encoding UTF8
}

if (-not (Test-Path -LiteralPath $modSource -PathType Container)) {
    throw "Packaged mod source is missing: $modSource"
}

$target = Resolve-GameDirectory $GameDirectory
$ue4ssRoot = Join-Path $target 'ue4ss'
$modsFile = Join-Path $ue4ssRoot 'Mods\mods.txt'
$manifestPath = Join-Path $target $manifestName
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("VHOLUME-NoHeadBob-" + [guid]::NewGuid().ToString())

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    Write-Host 'Looking up the newest normal UE4SS experimental release...'
    $release = Invoke-RestMethod -Uri $releaseApi -Headers @{ 'User-Agent' = 'VHOLUME-NoHeadBob-Installer' }
    $asset = @($release.assets | Where-Object { $_.name -match '^UE4SS_.+\.zip$' } | Select-Object -First 1)[0]

    if ($null -eq $asset) {
        throw 'The UE4SS release did not contain a normal UE4SS ZIP asset.'
    }

    $archive = Join-Path $tempRoot $asset.name
    Write-Host "Downloading $($asset.name)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archive

    if ($asset.digest -match '^sha256:([a-fA-F0-9]{64})$') {
        $actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedHash = $matches[1].ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            throw "Downloaded UE4SS checksum mismatch. Expected $expectedHash; received $actualHash."
        }
    }

    # UE4SS's current basic archive intentionally has this layout:
    # Win64\dwmapi.dll (proxy) and Win64\ue4ss\Mods (working directory).
    $backupPath = Join-Path $target ('.NoHeadBob-UE4SS-backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $hadProxy = Test-Path -LiteralPath (Join-Path $target 'dwmapi.dll') -PathType Leaf
    $hadUE4SSRoot = Test-Path -LiteralPath $ue4ssRoot -PathType Container

    if ($hadProxy -or $hadUE4SSRoot) {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        if ($hadProxy) {
            Copy-Item -LiteralPath (Join-Path $target 'dwmapi.dll') -Destination (Join-Path $backupPath 'dwmapi.dll') -Force
        }
        if ($hadUE4SSRoot) {
            Copy-Item -LiteralPath $ue4ssRoot -Destination (Join-Path $backupPath 'ue4ss') -Recurse -Force
        }
    }

    # Preserve an existing mod list even when UE4SS itself is being updated.
    $savedModsFile = Join-Path $tempRoot 'mods.txt.before-install'
    $hadModsFile = Test-Path -LiteralPath $modsFile -PathType Leaf
    if ($hadModsFile) {
        Copy-Item -LiteralPath $modsFile -Destination $savedModsFile -Force
    }

    Write-Host 'Installing UE4SS into Win64\ue4ss and its proxy into Win64...'
    Expand-Archive -LiteralPath $archive -DestinationPath $target -Force

    if ($hadModsFile) {
        Copy-Item -LiteralPath $savedModsFile -Destination $modsFile -Force
    }

    if (-not (Test-Path -LiteralPath (Join-Path $ue4ssRoot 'UE4SS.dll') -PathType Leaf)) {
        throw 'UE4SS extraction did not produce Win64\ue4ss\UE4SS.dll as expected.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $target 'dwmapi.dll') -PathType Leaf)) {
        throw 'UE4SS extraction did not produce Win64\dwmapi.dll as expected.'
    }

    $targetMod = Join-Path $ue4ssRoot "Mods\$modName"
    if (Test-Path -LiteralPath $targetMod) {
        Remove-Item -LiteralPath $targetMod -Recurse -Force
    }
    Copy-Item -LiteralPath $modSource -Destination (Join-Path $ue4ssRoot 'Mods') -Recurse -Force
    Enable-Mod $modsFile

    $manifest = [ordered]@{
        ModName = $modName
        InstalledAt = (Get-Date).ToString('o')
        UE4SSAsset = $asset.name
        UE4SSDigest = $asset.digest
        BackupPath = $backupPath
        HadProxy = $hadProxy
        HadUE4SSRoot = $hadUE4SSRoot
    }
    $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding UTF8

    Write-Host ''
    Write-Host 'Installed successfully.' -ForegroundColor Green
    Write-Host "UE4SS root: $ue4ssRoot"
    Write-Host 'Start VHOLUME and enter a level. Check ue4ss\UE4SS.log for: [NoHeadBob] NoHeadBob successfully applied'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
