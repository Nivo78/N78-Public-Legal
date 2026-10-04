#Requires -Version 7.0
<#
.SYNOPSIS
  GATE evidence for N78-STD-LEGAL-01 on WinForms desktop utilities.
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoRoot
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
. (Join-Path $PSScriptRoot '..\..\..\tools\lib\N78PortfolioRoot.ps1')
$nivo78Root = Get-N78PortfolioRootFromRepo -RepoRoot $RepoRoot
$canonical = Join-Path $nivo78Root 'N78-Public-Legal\family\winforms\N78FamilyWinFormsLegalSnapshot.vb'
$mirror = Join-Path $nivo78Root 'Common\WinForms\N78FamilyWinFormsLegalSnapshot.vb'

$failed = $false
function Fail([string] $msg) {
    Write-Host "  FAIL: $msg" -ForegroundColor Red
    $script:failed = $true
}
function Ok([string] $msg) {
    Write-Host "  OK: $msg" -ForegroundColor DarkGreen
}

if (-not (Test-Path -LiteralPath $canonical)) {
    Fail "Missing canonical WinForms legal module: $canonical"
    exit 1
}

$vbproj = Get-ChildItem -Path $RepoRoot -Filter '*.vbproj' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike '*.Tests*' } |
    Select-Object -First 1
if (-not $vbproj) {
    Fail "No product vbproj under $RepoRoot"
    exit 1
}
$projText = Get-Content -LiteralPath $vbproj.FullName -Raw
if ($projText -notmatch 'N78FamilyWinFormsLegalSnapshot') {
    Fail "$($vbproj.Name) must link N78FamilyWinFormsLegalSnapshot.vb"
} else {
    Ok "$($vbproj.Name) links N78FamilyWinFormsLegalSnapshot"
}

if ($projText -notmatch 'privacy-baseline\.txt' -or $projText -notmatch 'terms-baseline\.txt') {
    Fail "$($vbproj.Name) must embed Resources\legal\*-baseline.txt"
} else {
    Ok "$($vbproj.Name) embeds legal baselines"
}

$identityCandidates = @(
    (Join-Path $RepoRoot 'AppIdentity.vb'),
    (Join-Path $RepoRoot 'MainForm.vb')
)
$wired = $false
foreach ($path in $identityCandidates) {
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $t = Get-Content -LiteralPath $path -Raw
    if ($t -match 'BeginReadingUpgrade|N78FamilyWinFormsLegalSnapshot|ReadingBody') {
        $wired = $true
        Ok "$(Split-Path -Leaf $path) wires WinForms legal snapshot"
        break
    }
}
if (-not $wired) {
    Fail "AppIdentity.vb or MainForm.vb must wire N78FamilyWinFormsLegalSnapshot"
}

if (Test-Path -LiteralPath $mirror) {
    $cHash = (Get-FileHash -LiteralPath $canonical -Algorithm SHA256).Hash
    $mHash = (Get-FileHash -LiteralPath $mirror -Algorithm SHA256).Hash
    if ($cHash -ne $mHash) {
        Fail "Common mirror out of sync — run N78-Public-Legal/tools/sync-winforms-legal-snapshot.ps1"
    } else {
        Ok 'Common WinForms mirror matches N78-Public-Legal canonical'
    }
} else {
    Fail "Missing Common mirror: $mirror (run sync-winforms-legal-snapshot.ps1)"
}

if ($failed) {
    Write-Host 'N78-STD-LEGAL-01 WinForms GATE FAIL' -ForegroundColor Red
    exit 1
}
Write-Host 'N78-STD-LEGAL-01 WinForms GATE OK' -ForegroundColor Green
exit 0
