#Requires -Version 7.0
<#
.SYNOPSIS
  Regenerate plain-text legal baselines from N78-Public-Legal pages/*.html for KMP resource paths.
.PARAMETER DisplayName
  Public-Legal page prefix (e.g. N78-Machining, N78-Estimate, Integrator).
.PARAMETER OutDir
  Directory to write privacy-baseline.txt and terms-baseline.txt
#>
param(
    [Parameter(Mandatory = $true)][string]$DisplayName,
    [Parameter(Mandatory = $true)][string]$OutDir
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$pages = Join-Path $repoRoot 'pages'

function Convert-HtmlToPlain([string]$Html) {
    $t = $Html -replace '(?s)<script.*?</script>', ''
    $t = $t -replace '(?s)<style.*?</style>', ''
    $t = $t -replace '<br\s*/?>', "`n"
    $t = $t -replace '</p>', "`n`n"
    $t = $t -replace '</h[1-6]>', "`n`n"
    $t = $t -replace '<li>', "`n• "
    $t = $t -replace '<[^>]+>', ''
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    ($t -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }) -join "`n"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
foreach ($kind in @('privacy', 'terms')) {
    $page = Join-Path $pages "$DisplayName.$kind.html"
    if (-not (Test-Path $page)) { throw "Missing canonical page $page" }
    $html = Get-Content -LiteralPath $page -Raw
    $plain = Convert-HtmlToPlain $html
    $outFile = Join-Path $OutDir "$kind-baseline.txt"
    Set-Content -LiteralPath $outFile -Value $plain -Encoding utf8
    Write-Host "Wrote $outFile ($($plain.Length) chars)"
}
