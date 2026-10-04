#Requires -Version 5.1
<#
.SYNOPSIS
  Ensures every Nivo78 app in the family catalog has three GitHub Pages files:
  privacy, terms, and operator responsibility disclaimer.

.DESCRIPTION
  Creates only missing pages by default (does not overwrite product-specific privacy/terms synced from N78-Website).
  Operator pages use templates/operator_family.html plus optional templates/operator-bodies/{DisplayName}.html.
#>
param(
    [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch] $ForceRegenerateFamilyPages,
    [switch] $RegenerateOperatorPages
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\N78PublicLegalExpand.ps1')

$pagesDir = Join-Path $RepoRoot 'pages'
$templatesDir = Join-Path $RepoRoot 'templates'
New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null

$appendixPath = Join-Path $templatesDir 'permissions_appendix.default.html'
$appendix = Get-Content -LiteralPath $appendixPath -Raw -Encoding UTF8
$privacyTpl = Get-Content -LiteralPath (Join-Path $templatesDir 'privacy_family.html') -Raw -Encoding UTF8
$termsTpl = Get-Content -LiteralPath (Join-Path $templatesDir 'terms_family.html') -Raw -Encoding UTF8
$operatorTpl = Get-Content -LiteralPath (Join-Path $templatesDir 'operator_family.html') -Raw -Encoding UTF8

$apps = Get-N78FamilyLegalApps
$created = @()

foreach ($app in $apps) {
    $displayName = [string]$app.displayName
    foreach ($kind in @('privacy', 'terms', 'operator')) {
        $outName = Get-N78PublicLegalFileName -DisplayName $displayName -Kind $kind
        $outPath = Join-Path $pagesDir $outName
        if (Test-Path -LiteralPath $outPath) {
            if ($kind -eq 'operator' -and $RegenerateOperatorPages) { }
            elseif ($kind -ne 'operator' -and $ForceRegenerateFamilyPages) { }
            else { continue }
        }

        $content = switch ($kind) {
            'privacy' {
                Expand-N78PublicLegalTemplate -TemplateText $privacyTpl -App $app -PermissionsAppendixHtml $appendix
            }
            'terms' {
                Expand-N78PublicLegalTemplate -TemplateText $termsTpl -App $app
            }
            'operator' {
                $bodyExtraPath = Join-Path $templatesDir "operator-bodies\$displayName.html"
                $extra = ''
                if (Test-Path -LiteralPath $bodyExtraPath) {
                    $extra = Get-Content -LiteralPath $bodyExtraPath -Raw -Encoding UTF8
                }
                $tpl = Expand-N78PublicLegalTemplate -TemplateText $operatorTpl -App $app
                $tpl.Replace('{{OPERATOR_BODY_EXTRA}}', $extra.Trim())
            }
        }
        $final = Convert-N78PublicLegalHtmlForPages -Html $content -DisplayName $displayName -Kind $kind
        Set-Content -LiteralPath $outPath -Value $final.TrimEnd() -Encoding UTF8
        $created += $outName
        Write-Host "Wrote $outName"
    }
}

Write-N78PublicLegalIndex -RepoRoot $RepoRoot -PagesDir $pagesDir
Write-Host "[PASS] ensure-all-family-legal-pages: $($apps.Count) apps, $($created.Count) file(s) written"
