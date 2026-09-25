#Requires -Version 5.1
<#
.SYNOPSIS
  Build N78-Ops GitHub Pages privacy/terms from N78-Ops in-app HTML assets.
#>
param(
    [string] $OpsRepoRoot = (Join-Path $env:USERPROFILE 'Desktop\Nivo78\N78-Ops'),
    [string] $PublicLegalRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

$privacySrc = Join-Path $OpsRepoRoot 'app\src\main\assets\privacy_policy.html'
$termsSrc = Join-Path $OpsRepoRoot 'app\src\main\assets\terms_of_use.html'
if (-not (Test-Path -LiteralPath $privacySrc)) { throw "Missing $privacySrc" }
if (-not (Test-Path -LiteralPath $termsSrc)) { throw "Missing $termsSrc" }

$githubPrivacy = 'https://nivo78.github.io/N78-Public-Legal/pages/N78-Ops.privacy.html'
$githubTerms = 'https://nivo78.github.io/N78-Public-Legal/pages/N78-Ops.terms.html'

function Get-N78OpsAssetBodyFragment {
    param(
        [string] $SourcePath,
        [string] $HeadingToStrip = ''
    )
    $raw = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8
    if ($raw -notmatch '(?s)<body[^>]*>(.*)</body>') {
        throw "Could not parse <body> from $SourcePath"
    }
    $text = $Matches[1].Trim()
    if ($HeadingToStrip -ne '') {
        $escapedHeading = [regex]::Escape($HeadingToStrip)
        $text = $text -replace "(?m)^\s*<h1>$escapedHeading</h1>\s*", ''
    }
    $text = $text -replace '(?m)^\s*<p class="policy-product-name">.*?</p>\s*', ''
    $text = $text -replace [char]0x2014, '&mdash;'
    $text = $text -replace [char]0x2013, '&mdash;'
    $text = $text -replace '\u201c', '&ldquo;'
    $text = $text -replace '\u201d', '&rdquo;'
    $text = $text -replace '\u2018', '&rsquo;'
    $text = $text -replace '\u2019', '&rsquo;'
    $text = $text -replace 'https://nivo78\.com/ops/N78-Ops-Privacy/?', $githubPrivacy
    $text = $text -replace '/ops/N78-Ops-Privacy/?', $githubPrivacy
    $text = $text -replace 'https://nivo78\.com/ops/N78-Ops-Terms/?', $githubTerms
    $text = $text -replace '/ops/N78-Ops-Terms/?', $githubTerms
    return $text
}

function Write-N78OpsPublicLegalPage {
    param(
        [string] $Fragment,
        [ValidateSet('privacy', 'terms')][string] $Kind
    )
    $display = 'N78-Ops'
    $titleKind = if ($Kind -eq 'privacy') { 'Privacy Policy' } else { 'Terms of Use' }
    $outName = "$display.$Kind.html"
    $outPath = Join-Path $PublicLegalRoot "pages\$outName"
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$display — $titleKind</title>
  <meta name="robots" content="index, follow">
  <link rel="stylesheet" href="../legal.css">
</head>
<body>
<main class="app">
<article class="panel legal-prose">
$Fragment
</article>
</main>
</body>
</html>
"@
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($outPath, $html.TrimEnd() + "`n", $utf8NoBom)
    Write-Host "Wrote pages/$outName"
}

$privacyFragment = Get-N78OpsAssetBodyFragment -SourcePath $privacySrc -HeadingToStrip 'Privacy Policy'
$termsFragment = Get-N78OpsAssetBodyFragment -SourcePath $termsSrc -HeadingToStrip 'Terms of Use'

Write-N78OpsPublicLegalPage -Fragment $privacyFragment -Kind 'privacy'
Write-N78OpsPublicLegalPage -Fragment $termsFragment -Kind 'terms'

& (Join-Path $PSScriptRoot 'write-legal-url-catalog.ps1') -RepoRoot $PublicLegalRoot
