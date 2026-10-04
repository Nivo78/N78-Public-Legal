#Requires -Version 7.0
<#
.SYNOPSIS
  Per-product N78-STD-LEGAL-01 GATE — family verifier scoped to this repo's catalog label.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\N78PortfolioRoot.ps1')

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$idPath = Join-Path $RepoRoot 'product.identity.json'
if (-not (Test-Path -LiteralPath $idPath)) {
    throw "Missing product.identity.json under $RepoRoot"
}
$identity = Get-Content -LiteralPath $idPath -Raw | ConvertFrom-Json
$portfolio = Get-N78PortfolioRootFromRepo -RepoRoot $RepoRoot
$label = Get-N78FamilyLegalVerifierLabel -RepoRoot $RepoRoot -Identity $identity
$verifier = Join-Path $portfolio 'N78-Public-Legal\tools\verify\verify-n78-std-legal-01-family.ps1'
if (-not (Test-Path -LiteralPath $verifier)) {
    throw "Missing family legal verifier: $verifier"
}

& pwsh -NoProfile -File $verifier -Nivo78Root $portfolio -OnlyLabel $label -RequireLabelMatch
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Write-Host "N78-STD-LEGAL-01 product verify OK ($label)" -ForegroundColor Green
exit 0
