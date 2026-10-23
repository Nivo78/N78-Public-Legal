#Requires -Version 5.1
<#
.SYNOPSIS
  Regenerates short-form family Terms pages to match N78-Ops structural parity (Agreement, license, data, acceptance, etc.).

.DESCRIPTION
  Skips N78-Ops (canonical), N78-Machining, N78-APA, and N78-Frame (product-specific full terms).
  Preserves product-specific paragraphs from templates/terms-bodies/{DisplayName}.html or legacy "1. The job" section.
  Then runs cross-links and critical legal provisions refresh.
#>
param(
    [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string[]] $SkipDisplayNames = @('N78-Ops', 'N78-Machining', 'N78-APA', 'N78-Frame'),
    [switch] $IncludeTrackStub,
    [switch] $SyncKmpBaselines
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\N78PublicLegalExpand.ps1')

$pagesDir = Join-Path $RepoRoot 'pages'
$templatesDir = Join-Path $RepoRoot 'templates'
$termsTpl = Get-Content -LiteralPath (Join-Path $templatesDir 'terms_family.html') -Raw -Encoding UTF8
$bodiesDir = Join-Path $templatesDir 'terms-bodies'
$nivo78Root = Join-Path $env:USERPROFILE 'Desktop\Nivo78'

function Get-NextTermsVersion {
    param([string] $Html)
    if ($Html -match 'Version:</strong>\s*(\d+)') {
        return ([int]$Matches[1] + 1).ToString()
    }
    return '2'
}

function Get-TermsProductBodyExtra {
    param(
        [string] $DisplayName,
        [string] $ExistingHtml
    )
    $bodyPath = Join-Path $bodiesDir "$DisplayName.html"
    if (Test-Path -LiteralPath $bodyPath) {
        $rawBody = Get-Content -LiteralPath $bodyPath -Raw -Encoding UTF8
        if ($null -ne $rawBody -and $rawBody.Trim().Length -gt 0) {
            return $rawBody.Trim()
        }
    }
    if ($ExistingHtml -match '(?s)<h2>\s*1\.\s*The job\s*</h2>\s*(.*?)\s*<h2>\s*2\.') {
        $inner = $Matches[1].Trim()
        $inner = $inner -replace '(?s)^\s*<p>\s*{{ONE_JOB}}\s*</p>\s*', ''
        $inner = $inner -replace '(?s)^\s*<p>[^<]*{{ONE_JOB}}[^<]*</p>\s*', ''
        if ($inner -match '(?s)<p>\s*Turn measurements') {
            return $inner
        }
        if ($inner -match '(?s)<p>\s*The app is a tool') {
            $parts = $inner -split '(?=<p>\s*The app is a tool)'
            if ($parts.Count -gt 1) {
                return ($parts[1..($parts.Count - 1)] -join '').Trim()
            }
        }
        return $inner
    }
    return ''
}

function Expand-TermsForApp {
    param(
        [object] $App,
        [string] $TermsVersion,
        [string] $TermsEffective,
        [string] $ProductBodyExtra,
        [string] $PaymentsParagraph
    )
    return Expand-N78PublicLegalTemplate -TemplateText $termsTpl -App $App -ExtraReplacements @{
        '{{TERMS_VERSION}}'            = $TermsVersion
        '{{TERMS_EFFECTIVE}}'          = $TermsEffective
        '{{TERMS_PRODUCT_BODY_EXTRA}}' = $ProductBodyExtra
        '{{TERMS_DATA_BODY_EXTRA}}'    = ''
        '{{TERMS_PAYMENTS_PARAGRAPH}}' = $PaymentsParagraph
    }
}

$defaultPayments = '<p>Purchases, subscriptions, or paid tiers, when offered, are processed by the applicable app store or platform. Platform store policies apply to checkout. We do not receive your full payment card number from the store.</p>'
$estimatePayments = @'
<p>The Microsoft Store price for Windows PC, and the Mac App Store price when that store lists the app, is a one-time purchase of $9.99 USD on that store. The price is fixed. It is not a discount, a sale, or an introductory offer, and it does not increase on a later date. The download includes a 30-day free trial. There is no subscription. The store handles checkout, tax, and refunds. A purchase on one store does not unlock the other platform.</p>
'@.Trim()

$apps = Get-N78FamilyLegalApps
$written = @()
$todayEffective = (Get-Date).ToString('MMMM d, yyyy')

foreach ($app in $apps) {
    $displayName = [string]$app.displayName
    if ($SkipDisplayNames -contains $displayName) { continue }

    $outPath = Join-Path $pagesDir (Get-N78PublicLegalFileName -DisplayName $displayName -Kind 'terms')
    if (-not (Test-Path -LiteralPath $outPath)) { continue }

    $existing = Get-Content -LiteralPath $outPath -Raw -Encoding UTF8
    $isShortJob = $existing -match '1\.\s*The job'
    $isTrackStub = $displayName -eq 'N78-Track' -and $existing -notmatch '<h2>\s*1\.\s*Agreement'
    if (-not $isShortJob -and -not ($IncludeTrackStub -and $isTrackStub)) { continue }

    $version = Get-NextTermsVersion -Html $existing
    $bodyExtra = Get-TermsProductBodyExtra -DisplayName $displayName -ExistingHtml $existing
    $payments = if ($displayName -eq 'N78-Estimate') { $estimatePayments } else { $defaultPayments }

    $html = Expand-TermsForApp -App $app -TermsVersion $version -TermsEffective $todayEffective `
        -ProductBodyExtra $bodyExtra -PaymentsParagraph $payments

    Set-Content -LiteralPath $outPath -Value $html.TrimEnd() -Encoding UTF8
    $written += $displayName
    Write-Host "Regenerated terms: $displayName (v$version)"
}

& (Join-Path $RepoRoot 'tools\apply-legal-cross-links.ps1') -PagesDir $pagesDir
& (Join-Path $RepoRoot 'tools\apply-family-critical-legal-provisions.ps1') -PagesDir $pagesDir

if ($SyncKmpBaselines) {
    $baselineScript = Join-Path $RepoRoot 'tools\sync-embedded-legal-baselines.ps1'
    foreach ($name in $written) {
        $app = @($apps | Where-Object { $_.displayName -eq $name } | Select-Object -First 1)
        if (-not $app) { continue }
        $repoRoot = Join-Path $nivo78Root ([string]$app.repoFolder)
        $outDir = Join-Path $repoRoot 'shared\src\commonMain\resources\legal'
        if (-not (Test-Path -LiteralPath $outDir)) {
            $outDir = Join-Path $repoRoot 'code\shared\src\commonMain\resources\legal'
        }
        if (Test-Path -LiteralPath $outDir) {
            & $baselineScript -DisplayName $name -OutDir $outDir
        }
    }
}

Write-Host "[PASS] regenerate-family-terms-ops-parity: $($written.Count) page(s): $($written -join ', ')"
