#Requires -Version 5.1
# Shared helpers for N78-Public-Legal page generation.

function Get-N78PublicLegalPagesBase {
    return 'https://nivo78.github.io/N78-Public-Legal/pages'
}

function Get-N78FamilyLegalApps {
    param(
        [string] $KitFamilyAppsPath = (Join-Path $env:USERPROFILE 'Desktop\Nivo78\N78-Cosmos\N78-Kit\identity\family-apps.json')
    )
    if (-not (Test-Path -LiteralPath $KitFamilyAppsPath)) {
        throw "Missing family app catalog: $KitFamilyAppsPath"
    }
    $raw = Get-Content -LiteralPath $KitFamilyAppsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $excludeProductCodes = @('N78Kit', 'N78Cosmos', 'N78Theme')
    $apps = @($raw | Where-Object { $excludeProductCodes -notcontains $_.productCode })
    $hasQr = @($apps | Where-Object { $_.productCode -eq 'N78QRTest' }).Count -gt 0
    if (-not $hasQr -and (Test-Path -LiteralPath (Join-Path $env:USERPROFILE 'Desktop\Nivo78\N78-QRTest\product.identity.json'))) {
        $qr = Get-Content -LiteralPath (Join-Path $env:USERPROFILE 'Desktop\Nivo78\N78-QRTest\product.identity.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        $apps += [pscustomobject]@{
            repoFolder        = 'N78-QRTest'
            productCode       = [string]$qr.product_code
            displayName       = [string]$qr.display_name
            slug              = [string]$qr.slug
            oneJob            = [string]$qr.one_job
            skipHostedWebsite = $true
        }
    }
    return $apps | Sort-Object displayName
}

function Get-N78PublicLegalFileName {
    param(
        [string] $DisplayName,
        [ValidateSet('privacy', 'terms', 'operator')][string] $Kind
    )
    return "$DisplayName.$Kind.html"
}

function Get-N78PublicLegalPageUrl {
    param(
        [string] $DisplayName,
        [ValidateSet('privacy', 'terms', 'operator')][string] $Kind
    )
    $fileName = Get-N78PublicLegalFileName -DisplayName $DisplayName -Kind $Kind
    $encoded = [uri]::EscapeDataString($fileName)
    return "$(Get-N78PublicLegalPagesBase)/$encoded"
}

function Expand-N78PublicLegalTemplate {
    param(
        [string] $TemplateText,
        [object] $App,
        [string] $PermissionsAppendixHtml = ''
    )
    $displayName = [string]$App.displayName
    $year = (Get-Date).Year.ToString()
    $privacyUrl = Get-N78PublicLegalPageUrl -DisplayName $displayName -Kind 'privacy'
    $termsUrl = Get-N78PublicLegalPageUrl -DisplayName $displayName -Kind 'terms'
    $operatorUrl = Get-N78PublicLegalPageUrl -DisplayName $displayName -Kind 'operator'
    $map = @{
        '{{PRODUCT_TITLE}}'        = $displayName
        '{{PRODUCT_SLUG}}'         = [string]$App.slug
        '{{ONE_JOB}}'              = [string]$App.oneJob
        '{{COPYRIGHT_YEAR}}'       = $year
        '{{PUBLIC_PRIVACY_URL}}'   = $privacyUrl
        '{{PUBLIC_TERMS_URL}}'     = $termsUrl
        '{{PUBLIC_OPERATOR_URL}}'  = $operatorUrl
        '{{PRIVACY_LAST_UPDATED}}' = 'October 4, 2026'
        '{{TERMS_EFFECTIVE}}'      = 'October 4, 2026'
        '{{TERMS_VERSION}}'        = '1'
        '{{OPERATOR_EFFECTIVE}}'   = 'October 4, 2026'
        '{{OPERATOR_VERSION}}'     = '1'
        '{{PERMISSIONS_APPENDIX}}' = $PermissionsAppendixHtml
    }
    $out = $TemplateText
    foreach ($key in $map.Keys) {
        $out = $out.Replace($key, [string]$map[$key])
    }
    return $out
}

function Convert-N78PublicLegalHtmlForPages {
    param(
        [string] $Html,
        [string] $DisplayName,
        [ValidateSet('privacy', 'terms', 'operator')][string] $Kind
    )
    $titleKind = switch ($Kind) {
        'privacy' { 'Privacy Policy' }
        'terms' { 'Terms of Use' }
        'operator' { 'Operator Responsibility Disclaimer' }
    }
    $h = $Html
    $h = $h -replace 'href="\.\./legal\.css"', 'href="../legal.css"'
    $h = $h -replace 'href="\.\./\.\./legal\.css"', 'href="../legal.css"'
    $h = $h -replace 'href="\.\./support/"', "href=`"https://nivo78.com/$([string]$DisplayName -replace '^N78-','' -replace 'N78-','')/support/`""
    if ($h -notmatch '<html') {
        $h = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$DisplayName — $titleKind</title>
  <meta name="robots" content="index, follow">
  <link rel="stylesheet" href="../legal.css">
</head>
<body>
<main class="app">
<article class="panel legal-prose">
$h
</article>
</main>
</body>
</html>
"@
    }
    return $h
}

function Write-N78PublicLegalIndex {
    param(
        [string] $RepoRoot,
        [string] $PagesDir
    )
    $manifest = @()
    Get-ChildItem -LiteralPath $PagesDir -Filter '*.html' | Sort-Object Name | ForEach-Object {
        $kind = if ($_.Name -match '\.privacy\.html$') { 'privacy' }
        elseif ($_.Name -match '\.terms\.html$') { 'terms' }
        elseif ($_.Name -match '\.operator\.html$') { 'operator' }
        else { 'page' }
        $app = $_.Name -replace '\.(privacy|terms|operator)\.html$', ''
        $manifest += [pscustomobject]@{ App = $app; Kind = $kind; File = "pages/$($_.Name)" }
    }
    $indexLines = @(
        '<!DOCTYPE html>',
        '<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">',
        '<title>Nivo78 — public legal mirror</title>',
        '<link rel="stylesheet" href="legal.css">',
        '</head><body><main class="app"><article class="panel legal-prose">',
        '<h1>Nivo78 public legal mirror</h1>',
        '<p>Canonical public <strong>Privacy Policy</strong>, <strong>Terms of Use</strong>, and <strong>Operator Responsibility Disclaimer</strong> for every Nivo78 app (website sources via <code>tools/sync-from-n78-website.ps1</code>; family templates via <code>tools/ensure-all-family-legal-pages.ps1</code>). Marketing: <a class="text-link" href="https://nivo78.com/">nivo78.com</a>.</p>',
        '<ul>'
    )
    foreach ($row in ($manifest | Sort-Object App, @{ Expression = { switch ($_.Kind) { 'privacy' { 0 } 'terms' { 1 } 'operator' { 2 } default { 9 } } } })) {
        $label = switch ($row.Kind) {
            'privacy' { 'Privacy' }
            'terms' { 'Terms' }
            'operator' { 'Operator disclaimer' }
            default { 'Page' }
        }
        $indexLines += "<li><a class=`"text-link`" href=`"$($row.File)`">$($row.App) — $label</a></li>"
    }
    $indexLines += @('</ul>', '</article></main></body></html>')
    Set-Content -LiteralPath (Join-Path $RepoRoot 'index.html') -Value ($indexLines -join "`n") -Encoding UTF8
}
