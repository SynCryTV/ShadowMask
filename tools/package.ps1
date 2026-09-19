[CmdletBinding()]
param(
    [string]$Version
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
$addonSource = Join-Path $projectRoot "shadowmask"
$tocFile = Join-Path $addonSource "ShadowMask.toc"
$dist = Join-Path $projectRoot "dist"
$stage = Join-Path $dist "shadowmask"

if (-not (Test-Path -LiteralPath $addonSource)) {
    throw "Addon folder not found: $addonSource"
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $versionLine = Select-String -LiteralPath $tocFile -Pattern '^## Version:\s*(.+)$' | Select-Object -First 1
    if (-not $versionLine) { throw "No ## Version entry found in $tocFile" }
    $Version = $versionLine.Matches[0].Groups[1].Value.Trim()
}

$archive = Join-Path $dist ("ShadowMask-{0}.zip" -f $Version)

New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }

Copy-Item -LiteralPath $addonSource -Destination $stage -Recurse
Compress-Archive -Path $stage -DestinationPath $archive -CompressionLevel Optimal
Write-Output "Created $archive"
