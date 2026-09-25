#Requires -Version 5.1
<#
.SYNOPSIS
  Copy privacy and terms HTML from N78-Website into flat GitHub Pages files:
  pages/{AppDisplayName}.privacy.html and pages/{AppDisplayName}.terms.html
#>
param(
    [string] $WebsiteRoot = (Join-Path $env:USERPROFILE 'Desktop\Nivo78\N78-Website'),
    [string] $ApaRepoRoot = (Join-Path $env:USERPROFILE 'Desktop\Nivo78\N78-APA'),
    [string] $OpsRepoRoot = (Join-Path $env:USERPROFILE 'Desktop\Nivo78\N78-Ops'),
    [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch] $OpsOnly
)

$ErrorActionPreference = 'Stop'

$apps = @(
    @{ Slug = 'dash';       Name = 'N78-Dash' }
    @{ Slug = 'probe';      Name = 'N78-Probe' }
    @{ Slug = 'stllite';    Name = 'N78-StlLite' }
    @{ Slug = 'track';      Name = 'N78-Track' }
    @{ Slug = 'machining';  Name = 'N78-Machining' }
    @{ Slug = 'electrical'; Name = 'N78-Electrical' }
    @{ Slug = 'frame';      Name = 'N78-Frame' }
    @{ Slug = 'life';       Name = 'N78-Life' }
    @{ Slug = 'estimate';   Name = 'N78-Estimate'; FamilyTerms = $true }
    @{ Slug = 'ops';        Name = 'N78-Ops'; OpsFromAppAssets = $true }
    @{ Slug = 'apa';        Name = 'N78-APA' }
)

$familyTermsOverrides = @{
    estimate = @{
        terms_effective = 'August 31, 2026'
        terms_version   = '1'
        one_job         = 'Turn measurements and labor into a practical job price for small businesses and solo operators.'
    }
}

function Expand-N78FamilyTermsHtml {
    param(
        [string] $WebsiteRoot,
        [string] $Slug,
        [string] $DisplayName
    )
    $tplPath = Join-Path $WebsiteRoot 'legal\terms_family.html'
    if (-not (Test-Path -LiteralPath $tplPath)) { throw "Missing $tplPath" }
    $tpl = Get-Content -LiteralPath $tplPath -Raw -Encoding UTF8
    $ovr = $familyTermsOverrides[$Slug]
    if (-not $ovr) { $ovr = @{ terms_effective = 'September 2, 2026'; terms_version = '1'; one_job = 'Finish the stated job on this device without a Nivo78 account.' } }
    $year = (Get-Date).Year
    $map = @{
        '{{PRODUCT_TITLE}}'   = $DisplayName
        '{{PRODUCT_SLUG}}'    = $Slug
        '{{TERMS_EFFECTIVE}}' = $ovr.terms_effective
        '{{TERMS_VERSION}}'   = $ovr.terms_version
        '{{ONE_JOB}}'         = $ovr.one_job
        '{{COPYRIGHT_YEAR}}'  = [string]$year
    }
    foreach ($key in $map.Keys) { $tpl = $tpl.Replace($key, [string]$map[$key]) }
    return $tpl
}

function Get-N78ApaWebsiteRoot {
    param([string] $ApaRepo, [string] $RepoRoot)
    $live = Join-Path $ApaRepo 'code\Website'
    if (Test-Path -LiteralPath (Join-Path $live 'apa\privacy\index.html')) {
        return $live
    }
    $staging = Join-Path $RepoRoot '.staging\apa-website'
    foreach ($rel in @('apa\privacy\index.html', 'apa\terms\index.html')) {
        $gitPath = 'code/Website/' + ($rel -replace '\\', '/')
        $dest = Join-Path $staging $rel
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $content = & git -C $ApaRepo show "HEAD:$gitPath" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Could not read $gitPath from N78-APA ($ApaRepo). Check out the repo or fix the path."
        }
        Set-Content -LiteralPath $dest -Value $content -Encoding UTF8
    }
    return $staging
}

function Get-SafePageFileName {
    param([string] $DisplayName, [string] $Kind)
    return "$DisplayName.$Kind.html"
}

function Resolve-N78LegalSourceFile {
    param(
        [string] $WebsiteRoot,
        [string] $Slug,
        [ValidateSet('privacy', 'terms')][string] $Kind,
        [string] $BodyRelative = ''
    )
    if ($BodyRelative) {
        $bodyPath = Join-Path $WebsiteRoot $BodyRelative
        if (Test-Path -LiteralPath $bodyPath) { return @{ Mode = 'body'; Path = $bodyPath } }
        throw "Missing body source: $bodyPath"
    }
    $dir = Join-Path $WebsiteRoot "$Slug\$Kind"
    $html = Join-Path $dir 'index.html'
    $php = Join-Path $dir 'index.php'
    if (Test-Path -LiteralPath $html) { return @{ Mode = 'file'; Path = $html } }
    if (Test-Path -LiteralPath $php) { return @{ Mode = 'php'; Path = $php } }
    return $null
}

function Convert-N78LegalHtmlForPages {
    param(
        [string] $Html,
        [string] $DisplayName,
        [ValidateSet('privacy', 'terms')][string] $Kind
    )
    $titleKind = if ($Kind -eq 'privacy') { 'Privacy Policy' } else { 'Terms of Use' }
    $h = $Html
    $h = $h -replace 'href="\.\./legal\.css"', 'href="../legal.css"'
    $h = $h -replace 'href="\.\./\.\./legal\.css"', 'href="../legal.css"'
    $h = $h -replace 'href="\.\./support/"', 'href="https://nivo78.com/support/"'
    $h = $h -replace 'href="\.\./\.\./support/"', 'href="https://nivo78.com/support/"'
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

function Read-N78PhpLegalMain {
    param([string] $PhpPath)
    $raw = Get-Content -LiteralPath $PhpPath -Raw -Encoding UTF8
    if ($raw -match '(?s)<main\s+class="app">(.*)</main>') {
        return $Matches[1].Trim()
    }
    throw "Could not extract <main> from $PhpPath"
}

if ($OpsOnly) {
    & (Join-Path $PSScriptRoot 'Sync-N78OpsLegalPagesFromAppAssets.ps1') -OpsRepoRoot $OpsRepoRoot -PublicLegalRoot $RepoRoot
    Write-Host '[PASS] Ops-only public legal sync complete'
    exit 0
}

$pagesDir = Join-Path $RepoRoot 'pages'
New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null

$cssSrc = Join-Path $WebsiteRoot 'assets\css\n78_legal_privacy_header.css'
$cssDest = Join-Path $RepoRoot 'legal.css'
if (Test-Path -LiteralPath $cssSrc) {
    $base = Get-Content -LiteralPath $cssSrc -Raw -Encoding UTF8
    $extra = @'

/* Flat mirror pages (N78-Public-Legal) */
:root {
  color-scheme: light;
  --bg: #f8fafc;
  --panel: #ffffff;
  --text: #0f172a;
  --muted: #475569;
  --border: #e2e8f0;
  --link: #006eff;
}
body { margin: 0; background: var(--bg); color: var(--text); font-family: system-ui, Segoe UI, Roboto, sans-serif; line-height: 1.55; }
.app { max-width: 48rem; margin: 0 auto; padding: 1.5rem 1rem 3rem; }
.panel { background: var(--panel); border: 1px solid var(--border); border-radius: 12px; padding: 1.25rem 1.5rem; }
.text-link { color: var(--link); }
'@
    Set-Content -LiteralPath $cssDest -Value ($base + $extra) -Encoding UTF8
}

$apaWebsiteRoot = $null
if (Test-Path -LiteralPath $ApaRepoRoot) {
    $apaWebsiteRoot = Get-N78ApaWebsiteRoot -ApaRepo $ApaRepoRoot -RepoRoot $RepoRoot
}

$manifest = @()
foreach ($app in $apps) {
    if ($app.OpsFromAppAssets) {
        & (Join-Path $PSScriptRoot 'Sync-N78OpsLegalPagesFromAppAssets.ps1') -OpsRepoRoot $OpsRepoRoot -PublicLegalRoot $RepoRoot
        $manifest += [pscustomobject]@{ App = $app.Name; Kind = 'privacy'; File = 'pages/N78-Ops.privacy.html' }
        $manifest += [pscustomobject]@{ App = $app.Name; Kind = 'terms'; File = 'pages/N78-Ops.terms.html' }
        continue
    }
    $appWebsiteRoot = $WebsiteRoot
    if ($app.Slug -eq 'apa' -and $apaWebsiteRoot) {
        $appWebsiteRoot = $apaWebsiteRoot
    }
    foreach ($kind in @('privacy', 'terms')) {
        $bodyRel = ''
        if ($kind -eq 'privacy' -and $app.PrivacyBody) { $bodyRel = $app.PrivacyBody }
        if ($kind -eq 'terms' -and $app.TermsBody) { $bodyRel = $app.TermsBody }
        if ($kind -eq 'terms' -and $app.FamilyTerms) {
            $content = Expand-N78FamilyTermsHtml -WebsiteRoot $WebsiteRoot -Slug $app.Slug -DisplayName $app.Name
            $outName = Get-SafePageFileName -DisplayName $app.Name -Kind $kind
            $outPath = Join-Path $pagesDir $outName
            $final = Convert-N78LegalHtmlForPages -Html $content -DisplayName $app.Name -Kind $kind
            Set-Content -LiteralPath $outPath -Value $final.TrimEnd() -Encoding UTF8
            Write-Host "Wrote $outName (family terms template)"
            $manifest += [pscustomobject]@{ App = $app.Name; Kind = $kind; File = "pages/$outName" }
            continue
        }
        $src = Resolve-N78LegalSourceFile -WebsiteRoot $appWebsiteRoot -Slug $app.Slug -Kind $kind -BodyRelative $bodyRel
        if (-not $src) {
            Write-Warning "Skip $($app.Name) $kind — no source under $appWebsiteRoot"
            continue
        }
        switch ($src.Mode) {
            'file' { $content = Get-Content -LiteralPath $src.Path -Raw -Encoding UTF8 }
            'body' { $content = Get-Content -LiteralPath $src.Path -Raw -Encoding UTF8 }
            'php' { $content = Read-N78PhpLegalMain -PhpPath $src.Path }
            default { throw "Unknown mode $($src.Mode)" }
        }
        $outName = Get-SafePageFileName -DisplayName $app.Name -Kind $kind
        $outPath = Join-Path $pagesDir $outName
        $final = Convert-N78LegalHtmlForPages -Html $content -DisplayName $app.Name -Kind $kind
        Set-Content -LiteralPath $outPath -Value $final.TrimEnd() -Encoding UTF8
        Write-Host "Wrote $outName"
        $manifest += [pscustomobject]@{ App = $app.Name; Kind = $kind; File = "pages/$outName" }
    }
}

$indexLines = @(
    '<!DOCTYPE html>',
    '<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">',
    '<title>Nivo78 — public legal mirror</title>',
    '<link rel="stylesheet" href="legal.css">',
    '</head><body><main class="app"><article class="panel legal-prose">',
    '<h1>Nivo78 public legal mirror</h1>',
    '<p>Canonical public privacy and terms for Nivo78 apps (sourced from <code>N78-Website</code> via <code>tools/sync-from-n78-website.ps1</code>). Marketing: <a class="text-link" href="https://nivo78.com/">nivo78.com</a>.</p>',
    '<ul>'
)
foreach ($row in ($manifest | Sort-Object App, Kind)) {
    $label = if ($row.Kind -eq 'privacy') { 'Privacy' } else { 'Terms' }
    $indexLines += "<li><a class=`"text-link`" href=`"$($row.File)`">$($row.App) — $label</a></li>"
}
$indexLines += @('</ul>', '</article></main></body></html>')
Set-Content -LiteralPath (Join-Path $RepoRoot 'index.html') -Value ($indexLines -join "`n") -Encoding UTF8

& (Join-Path $PSScriptRoot 'write-legal-url-catalog.ps1') -RepoRoot $RepoRoot
Write-Host "[PASS] Sync complete ($($manifest.Count) pages)"
