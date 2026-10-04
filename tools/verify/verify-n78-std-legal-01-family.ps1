#Requires -Version 7.0
<#
.SYNOPSIS
  Family GATE scan for N78-STD-LEGAL-01 (GitHub canonical + embedded fallback).
  Exit 1 with "N78-STD-LEGAL-01 FAIL" when a repo with an in-app legal gate lacks compliance signals.
#>
param(
    [string]$Nivo78Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [string[]]$OnlyLabel = @(),
    [switch]$RequireLabelMatch
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]@()

function Add-Fail([string]$Msg) {
    $failures.Add($Msg)
    Write-Host "  FAIL: $Msg" -ForegroundColor Red
}

function Test-RepoLegalCompliance {
    param([string]$RepoPath, [string]$Label)
    if (-not (Test-Path $RepoPath)) { return }
    $hasGate = $false
    $hasSnapshotRepo = $false
    $hasBaseline = $false
    $hasGithubUrl = $false
    $staticOnly = $false

    $ktFiles = Get-ChildItem -Path $RepoPath -Recurse -Include *.kt -ErrorAction SilentlyContinue
    foreach ($f in $ktFiles) {
        $t = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
        if ($t -match 'FamilyLegalGate|LegalGate|FirstRunLegal|ShowLegalGate') { $hasGate = $true }
        if ($t -match 'LegalSnapshotRepository') { $hasSnapshotRepo = $true }
        if ($t -match 'nivo78\.github\.io/N78-Public-Legal|N78FamilyPublicLegalUrls|LegalUrls') { $hasGithubUrl = $true }
        if ($t -match 'TERMS_SCROLL_BODY|EstimateHostedLegalDocument|HostedLegalDocument\(') { $staticOnly = $true }
    }
    $vbFiles = Get-ChildItem -Path $RepoPath -Recurse -Include *.vb -ErrorAction SilentlyContinue
    foreach ($f in $vbFiles) {
        $t = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
        if ($t -match 'ShowLegalGate|LegalGate|PrivacyPolicyText') { $hasGate = $true }
        if ($t -match 'N78FamilyWinFormsLegalSnapshot|LegalSnapshotRepository') { $hasSnapshotRepo = $true }
        if ($t -match 'N78FamilyWinFormsLegalSnapshot') { $hasSnapshotRepo = $true }
        if ($t -match 'nivo78\.github\.io/N78-Public-Legal|N78FamilyPublicLegalUrls|LegalUrls') { $hasGithubUrl = $true }
        if ($t -match 'ShowHostedLegalDocument\(.*PrivacyPolicyText') { $staticOnly = $true }
    }
    $baselines = Get-ChildItem -Path $RepoPath -Recurse -Filter '*-baseline.txt' -ErrorAction SilentlyContinue
    if ($baselines.Count -gt 0) { $hasBaseline = $true }

    if (-not $hasGate) { return }

    Write-Host "`n[$Label]" -ForegroundColor Cyan
    if (-not $hasSnapshotRepo -and $staticOnly) {
        Add-Fail "$Label — legal gate uses static/hosted-only pattern; missing LegalSnapshotRepository (or WinForms family snapshot helper)."
    }
    if (-not $hasBaseline) {
        Add-Fail "$Label — legal gate present but no *-baseline.txt embedded snapshots found."
    }
    if (-not $hasGithubUrl) {
        Add-Fail "$Label — missing nivo78.github.io/N78-Public-Legal URL mapping."
    }
    if ($hasSnapshotRepo -and $hasBaseline -and $hasGithubUrl) {
        Write-Host "  OK: N78-STD-LEGAL-01 signals present" -ForegroundColor DarkGreen
    }
}

$products = @(
    @{ Path = 'N78-Machining'; Label = 'N78-Machining' }
    @{ Path = 'N78-Electrical'; Label = 'N78-Electrical' }
    @{ Path = 'N78-Estimate'; Label = 'N78-Estimate' }
    @{ Path = 'N78-Frame'; Label = 'N78-Frame' }
    @{ Path = 'N78-BizBlocks'; Label = 'N78-BizBlocks' }
    @{ Path = 'N78-Life'; Label = 'N78-Life' }
    @{ Path = 'N78-APA'; Label = 'N78-APA' }
    @{ Path = 'Business\N78-Successor'; Label = 'N78-Successor' }
    @{ Path = 'Business\N78-Template'; Label = 'N78-Template' }
    @{ Path = 'Business\N78-TestBed'; Label = 'N78-TestBed' }
    @{ Path = 'Business\N78-Integrator'; Label = 'N78-Integrator' }
    @{ Path = 'N78-Cosmos\composer\studio'; Label = 'Cosmos Composer Studio' }
    @{ Path = 'N78-Ops'; Label = 'N78-Ops' }
)

Write-Host 'N78-STD-LEGAL-01 family verifier' -ForegroundColor Cyan
$scanned = 0
foreach ($p in $products) {
    if ($OnlyLabel.Count -gt 0 -and ($OnlyLabel -notcontains $p.Label)) { continue }
    $scanned++
    Test-RepoLegalCompliance -RepoPath (Join-Path $Nivo78Root $p.Path) -Label $p.Label
}
if ($RequireLabelMatch -and $OnlyLabel.Count -gt 0 -and $scanned -eq 0) {
    Add-Fail "No product matched OnlyLabel ($($OnlyLabel -join ', ')) — fix display_name or repo folder vs family catalog."
}

if ($failures.Count -gt 0) {
    Write-Host "`nN78-STD-LEGAL-01 FAIL — Legal document delivery does not implement: GitHub canonical source + embedded offline fallback." -ForegroundColor Red
    exit 1
}
Write-Host "`nN78-STD-LEGAL-01 family scan: no gate violations detected in scanned repos." -ForegroundColor Green
exit 0
