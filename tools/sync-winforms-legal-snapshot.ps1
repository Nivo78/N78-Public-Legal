#Requires -Version 7.0
<#
.SYNOPSIS
  Copy versioned N78FamilyWinFormsLegalSnapshot.vb to Desktop/Nivo78/Common/WinForms mirror.
#>
$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$src = Join-Path $repoRoot 'family\winforms\N78FamilyWinFormsLegalSnapshot.vb'
$nivo78Root = Resolve-Path (Join-Path $repoRoot '..')
$dst = Join-Path $nivo78Root 'Common\WinForms\N78FamilyWinFormsLegalSnapshot.vb'
if (-not (Test-Path -LiteralPath $src)) { throw "Missing canonical WinForms legal module: $src" }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
Copy-Item -LiteralPath $src -Destination $dst -Force
Write-Host "Synced WinForms legal snapshot -> $dst" -ForegroundColor Green
