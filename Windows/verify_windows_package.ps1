param(
    [ValidateSet("dynamic-island", "companion")]
    [string]$Flavor = "dynamic-island",
    [ValidateSet("win-x64", "win-arm64")]
    [string]$Runtime = "win-x64",
    [string]$CharacterPack = "generic"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$distRoot = Join-Path $root "dist/windows"
$profilePath = if ($CharacterPack -eq "generic") {
    Join-Path $PSScriptRoot "CharacterEfficiencyIsland.Windows/profile.json"
} else {
    Join-Path $PSScriptRoot "CharacterPacks/$CharacterPack/profile.json"
}
if (-not (Test-Path $profilePath)) {
    throw "Character profile does not exist: $profilePath"
}
$profile = Get-Content $profilePath -Raw -Encoding UTF8 | ConvertFrom-Json
$appName = [string]$profile.appName
$label = if ($Flavor -eq "companion") { "桌宠" } else { "灵动岛" }
$exe = Join-Path $distRoot "$appName-Windows-$label-$Runtime.exe"
$zip = Join-Path $distRoot "$appName-Windows-$label-$Runtime.zip"

# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
foreach ($path in @($exe, $zip)) {
    if (-not (Test-Path $path)) {
        throw "Missing package: $path"
    }
    if ((Get-Item $path).Length -lt 1024) {
        throw "Package is unexpectedly small: $path"
    }
}

$header = [System.IO.File]::ReadAllBytes($exe)[0..1]
if ($header[0] -ne 0x4D -or $header[1] -ne 0x5A) {
    # Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    throw "Executable does not have a valid PE header: $exe"
}

# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
$temporary = Join-Path ([System.IO.Path]::GetTempPath()) ("character-island-verify-" + [guid]::NewGuid())
try {
    Expand-Archive -Path $zip -DestinationPath $temporary
    # Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    $zippedExeName = if ($CharacterPack -eq "generic") { "CharacterEfficiencyIsland.exe" } else { "$appName.exe" }
    $zippedExe = Join-Path $temporary $zippedExeName
    if (-not (Test-Path $zippedExe)) {
        throw "ZIP does not contain $zippedExeName"
    }
    $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($zippedExe)
    Write-Host "Verified: $zip"
    Write-Host "File version: $($version.FileVersion)"
    Write-Host "Size: $((Get-Item $zip).Length) bytes"
}
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
finally {
    if (Test-Path $temporary) {
        Remove-Item $temporary -Recurse -Force
    }
}
