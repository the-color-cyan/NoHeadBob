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
$coreFiles = @('UE4SS.dll', 'dwmapi.dll', 'UE4SS-settings.ini')
$releaseApi = 'https://api.github.com/repos/UE4SS-RE/RE-UE4SS/releases/tags/experimental-latest'

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

function Enable-Mod {
    param([string]$ModsFile)

    $modsDirectory = Split-Path -Parent $ModsFile
    New-Item -ItemType Directory -Path $modsDirectory -Force | Out-Null

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
$modsFile = Join-Path $target 'Mods\mods.txt'
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

    $backupPath = Join-Path $target ('.NoHeadBob-UE4SS-backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $backedUpCoreFiles = @()

    foreach ($file in $coreFiles) {
        $source = Join-Path $target $file
        if (Test-Path -LiteralPath $source -PathType Leaf) {
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination (Join-Path $backupPath $file) -Force
            $backedUpCoreFiles += $file
        }
    }

    # Preserve a pre-existing mod list so the UE4SS extraction cannot overwrite it.
    $savedModsFile = Join-Path $tempRoot 'mods.txt.before-install'
    $hadModsFile = Test-Path -LiteralPath $modsFile -PathType Leaf
    if ($hadModsFile) {
        Copy-Item -LiteralPath $modsFile -Destination $savedModsFile -Force
    }

    Write-Host 'Installing normal UE4SS experimental files...'
    Expand-Archive -LiteralPath $archive -DestinationPath $target -Force

    if ($hadModsFile) {
        Copy-Item -LiteralPath $savedModsFile -Destination $modsFile -Force
    }

    $targetMod = Join-Path $target "Mods\$modName"
    if (Test-Path -LiteralPath $targetMod) {
        Remove-Item -LiteralPath $targetMod -Recurse -Force
    }
    Copy-Item -LiteralPath $modSource -Destination (Join-Path $target 'Mods') -Recurse -Force
    Enable-Mod $modsFile

    $manifest = [ordered]@{
        ModName = $modName
        InstalledAt = (Get-Date).ToString('o')
        UE4SSAsset = $asset.name
        UE4SSDigest = $asset.digest
        CoreFiles = $coreFiles
        BackupPath = $backupPath
        BackedUpCoreFiles = $backedUpCoreFiles
    }
    $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding UTF8

    Write-Host ''
    Write-Host 'Installed successfully.' -ForegroundColor Green
    Write-Host "Game directory: $target"
    Write-Host 'Start VHOLUME and enter a level. Check UE4SS.log for: [NoHeadBob] NoHeadBob successfully applied'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
