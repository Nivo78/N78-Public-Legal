#Requires -Version 7.0
<#
.SYNOPSIS
  Refreshes embedded product-repo legal redirect stubs (privacy, terms, operator) from N78-Kit expand script.

.DESCRIPTION
  For each family app with product.identity.json and code/Website/{slug}/, runs
  N78-Kit/tools/expand-n78-family-legal.ps1 (three GitHub Pages redirect index.html files plus support/hub).
  Optionally syncs N78-Ops in-app privacy_policy.html and terms_of_use.html from canonical pages/.
#>
param(
    [string] $Nivo78Root = (Join-Path $env:USERPROFILE 'Desktop\Nivo78'),
    [string] $PublicLegalRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch] $SkipOpsInAppAssets
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PublicLegalRoot 'tools\lib\N78PublicLegalExpand.ps1')

$expandScript = Join-Path $Nivo78Root 'N78-Cosmos\N78-Kit\tools\expand-n78-family-legal.ps1'
if (-not (Test-Path -LiteralPath $expandScript)) {
    throw "Missing $expandScript"
}

function Resolve-ProductIdentityPath {
    param([string] $RepoRoot)
    foreach ($rel in @('product.identity.json', 'code\product.identity.json')) {
        $p = Join-Path $RepoRoot $rel
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

$apps = Get-N78FamilyLegalApps
$expanded = @()

foreach ($app in $apps) {
    $folder = [string]$app.repoFolder
    if ([string]::IsNullOrWhiteSpace($folder)) { continue }
    $repoRoot = Join-Path $Nivo78Root $folder
    if (-not (Test-Path -LiteralPath $repoRoot)) { continue }
    $identityPath = Resolve-ProductIdentityPath -RepoRoot $repoRoot
    if (-not $identityPath) { continue }
    $identity = Get-Content -LiteralPath $identityPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $slug = [string]$identity.slug
    if ([string]::IsNullOrWhiteSpace($slug)) { continue }
    $outDir = Join-Path $repoRoot "code\Website\$slug"
    if (-not (Test-Path -LiteralPath (Split-Path $outDir -Parent))) { continue }
    & $expandScript -IdentityPath $identityPath -OutDir $outDir -LegalRedirectStubsOnly
    $expanded += $folder
}

Write-Host "[PASS] Expanded legal stubs for: $($expanded -join ', ')"

if (-not $SkipOpsInAppAssets) {
    $opsRoot = Join-Path $Nivo78Root 'N78-Ops'
    $pagesDir = Join-Path $PublicLegalRoot 'pages'
    $opsPrivacyPage = Join-Path $pagesDir 'N78-Ops.privacy.html'
    $opsTermsPage = Join-Path $pagesDir 'N78-Ops.terms.html'
    if ((Test-Path -LiteralPath $opsRoot) -and (Test-Path -LiteralPath $opsPrivacyPage) -and (Test-Path -LiteralPath $opsTermsPage)) {
        function Get-PublicLegalArticleInnerHtml {
            param([string] $PagePath)
            $raw = Get-Content -LiteralPath $PagePath -Raw -Encoding UTF8
            if ($raw -match '(?s)<article[^>]*class="panel legal-prose"[^>]*>(.*?)</article>') {
                return $Matches[1].Trim()
            }
            if ($raw -match '(?s)<body[^>]*>(.*)</body>') {
                return $Matches[1].Trim()
            }
            throw "Could not extract article body from $PagePath"
        }

        function Convert-PublicLegalFragmentToOpsInAppBody {
            param(
                [string] $Fragment,
                [string] $Title
            )
            $body = $Fragment
            $body = $body -replace '&ldquo;', '"'
            $body = $body -replace '&rdquo;', '"'
            $body = $body -replace '&rsquo;', "'"
            $body = $body -replace '&mdash;', '—'
            $body = $body -replace '&nbsp;', ' '
            if ($body -notmatch '(?i)<h1') {
                $body = "<h1>$Title</h1>`n$body"
            }
            return $body
        }

        function Write-OpsInAppLegalAsset {
            param(
                [string] $DestPath,
                [string] $WindowTitle,
                [string] $BodyInnerHtml
            )
            $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$WindowTitle</title>
    <style>
        body { font-family: sans-serif; line-height: 1.6; color: #333; padding: 20px; max-width: 720px; margin: 0 auto; }
        h1 { color: #2c3e50; }
        h2 { color: #34495e; margin-top: 24px; font-size: 1.15rem; }
        p { margin-bottom: 10px; }
        ul { margin-top: 0; padding-left: 1.25rem; }
        li { margin-bottom: 6px; }
    </style>
</head>
<body>
$BodyInnerHtml
</body>
</html>
"@
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            New-Item -ItemType Directory -Path (Split-Path -Parent $DestPath) -Force | Out-Null
            [IO.File]::WriteAllText($DestPath, $html.TrimEnd() + "`n", $utf8NoBom)
            Write-Host "Wrote $DestPath"
        }

        $privFrag = Get-PublicLegalArticleInnerHtml -PagePath $opsPrivacyPage
        $termsFrag = Get-PublicLegalArticleInnerHtml -PagePath $opsTermsPage
        $privBody = Convert-PublicLegalFragmentToOpsInAppBody -Fragment $privFrag -Title 'Privacy Policy'
        $termsBody = Convert-PublicLegalFragmentToOpsInAppBody -Fragment $termsFrag -Title 'Terms of Use'
        $destinations = @(
            (Join-Path $opsRoot 'app\src\main\assets\privacy_policy.html')
            (Join-Path $opsRoot 'app\src\main\assets\terms_of_use.html')
            (Join-Path $opsRoot 'iosApp\iosApp\privacy_policy.html')
            (Join-Path $opsRoot 'iosApp\iosApp\terms_of_use.html')
        )
        Write-OpsInAppLegalAsset -DestPath $destinations[0] -WindowTitle 'N78-Ops Privacy Policy' -BodyInnerHtml $privBody
        Write-OpsInAppLegalAsset -DestPath $destinations[1] -WindowTitle 'N78-Ops Terms of Use' -BodyInnerHtml $termsBody
        Write-OpsInAppLegalAsset -DestPath $destinations[2] -WindowTitle 'N78-Ops Privacy Policy' -BodyInnerHtml $privBody
        Write-OpsInAppLegalAsset -DestPath $destinations[3] -WindowTitle 'N78-Ops Terms of Use' -BodyInnerHtml $termsBody
        Write-Host '[PASS] N78-Ops in-app legal assets synced from N78-Public-Legal pages'
    }
}
