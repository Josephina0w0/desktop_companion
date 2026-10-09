param(
    [ValidateSet("dynamic-island", "companion")]
    [string]$Flavor = "dynamic-island",
    [ValidateSet("win-x64", "win-arm64")]
    [string]$Runtime = "win-x64",
    [string]$CharacterPack = "generic",
    [string]$Version = "0.1.4-win.2"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $PSScriptRoot "CharacterEfficiencyIsland.Windows/CharacterEfficiencyIsland.Windows.csproj"
$flavorFile = Join-Path $PSScriptRoot "CharacterEfficiencyIsland.Windows/BuildFlavor.cs"
$profilePath = if ($CharacterPack -eq "generic") {
    Join-Path $PSScriptRoot "CharacterEfficiencyIsland.Windows/profile.json"
} else {
    Join-Path $PSScriptRoot "CharacterPacks/$CharacterPack/profile.json"
}
$assetRoot = if ($CharacterPack -eq "generic") {
    Join-Path $root "Sources/CharacterEfficiencyIsland/Assets"
} else {
    Join-Path $PSScriptRoot "CharacterPacks/$CharacterPack/Assets"
}
$distRoot = Join-Path $root "dist/windows"
$publishDir = Join-Path $distRoot "$Flavor/$CharacterPack/$Runtime"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
if (-not (Test-Path $profilePath)) {
    throw "Character pack '$CharacterPack' does not exist. Add Windows/CharacterPacks/<slug>/profile.json and its Assets/ folder first."
}
$profile = Get-Content $profilePath -Raw -Encoding UTF8 | ConvertFrom-Json
$appName = [string]$profile.appName
if ([string]::IsNullOrWhiteSpace($appName)) {
    throw "Character profile is missing appName: $profilePath"
}
$requiredAssets = @(
    "working", "break", "idle", "alert", "ai", "water",
    "reminder-first", "reminder-second", "reminder-third", "reminder-fourth",
    "panel-working", "panel-break", "panel-idle", "panel-water", "panel-ai",
    "panel-reminder-second", "panel-reminder-third", "panel-reminder-fourth",
    "statusIcon"
)
foreach ($asset in $requiredAssets) {
    $assetPath = Join-Path $assetRoot "$asset.png"
    if (-not (Test-Path $assetPath)) {
        throw "Character pack '$CharacterPack' is missing $assetPath"
    }
}

function New-WindowsAppIcon {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        # Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        [Parameter(Mandatory = $true)][string]$Destination
    )

    Add-Type -AssemblyName System.Drawing.Common
    if (-not ("NativeIconMethods" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class NativeIconMethods {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool DestroyIcon(IntPtr handle);
}
"@
    }

    $sourceImage = [System.Drawing.Image]::FromFile($Source)
    $canvas = [System.Drawing.Bitmap]::new(
        256,
        256,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $iconHandle = [IntPtr]::Zero
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

        $available = 248.0
        $scale = [Math]::Min($available / $sourceImage.Width, $available / $sourceImage.Height)
        $width = [Math]::Max(1, [int][Math]::Round($sourceImage.Width * $scale))
        $height = [Math]::Max(1, [int][Math]::Round($sourceImage.Height * $scale))
        $left = [int]((256 - $width) / 2)
        $top = [int]((256 - $height) / 2)
        $graphics.DrawImage($sourceImage, $left, $top, $width, $height)

        $destinationFolder = Split-Path -Parent $Destination
        New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
        $iconHandle = $canvas.GetHicon()
        $icon = [System.Drawing.Icon]::FromHandle($iconHandle)
        $stream = [System.IO.File]::Create($Destination)
        try { $icon.Save($stream) } finally { $stream.Dispose(); $icon.Dispose() }
    }
    finally {
        if ($iconHandle -ne [IntPtr]::Zero) { [NativeIconMethods]::DestroyIcon($iconHandle) | Out-Null }
        $graphics.Dispose()
        # Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        $canvas.Dispose()
        $sourceImage.Dispose()
    }
}

if (Test-Path $publishDir) {
    # Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    Remove-Item $publishDir -Recurse -Force
}
New-Item -ItemType Directory -Path $publishDir -Force | Out-Null
$generatedIcon = Join-Path $PSScriptRoot "CharacterEfficiencyIsland.Windows/obj/generated-app-icons/$CharacterPack.ico"
New-WindowsAppIcon -Source (Join-Path $assetRoot "statusIcon.png") -Destination $generatedIcon

dotnet restore $project -r $Runtime -p:CharacterPack=$CharacterPack -p:Flavor=$Flavor
dotnet publish $project `
    -c Release `
    -r $Runtime `
    --self-contained true `
    --no-restore `
    -o $publishDir `
    -p:Version=$Version `
    -p:CharacterPack=$CharacterPack `
    -p:Flavor=$Flavor `
    -p:ApplicationIcon=$generatedIcon `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:DebugType=None `
    -p:DebugSymbols=false
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).

$exe = Join-Path $publishDir "CharacterEfficiencyIsland.exe"
if (-not (Test-Path $exe)) {
    throw "Windows executable was not produced: $exe"
}

$packagedExeName = if ($CharacterPack -eq "generic") { "CharacterEfficiencyIsland.exe" } else { "$appName.exe" }
$packagedExe = Join-Path $publishDir $packagedExeName
if ($packagedExe -ne $exe) {
    Move-Item $exe $packagedExe -Force
}

$label = if ($Flavor -eq "companion") { "桌宠" } else { "灵动岛" }
$standaloneExe = Join-Path $distRoot "$appName-Windows-$label-$Runtime.exe"
$zip = Join-Path $distRoot "$appName-Windows-$label-$Runtime.zip"
Copy-Item $packagedExe $standaloneExe -Force
if (Test-Path $zip) {
    Remove-Item $zip -Force
}
Compress-Archive -Path (Join-Path $publishDir "*") -DestinationPath $zip -CompressionLevel Optimal

Write-Host "EXE: $standaloneExe"
Write-Host "ZIP: $zip"
