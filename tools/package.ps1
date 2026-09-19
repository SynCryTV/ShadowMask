[CmdletBinding()]
param(
    [string]$Version = "0.1.0"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
$addonSource = Join-Path $projectRoot "shadowmask"
$dist = Join-Path $projectRoot "dist"
$stage = Join-Path $dist "shadowmask"
$archive = Join-Path $dist ("ShadowMask-{0}.zip" -f $Version)

if (-not (Test-Path -LiteralPath $addonSource)) {
    throw "Addon folder not found: $addonSource"
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }

Copy-Item -LiteralPath $addonSource -Destination $stage -Recurse
Compress-Archive -Path $stage -DestinationPath $archive -CompressionLevel Optimal
Write-Output "Created $archive"
