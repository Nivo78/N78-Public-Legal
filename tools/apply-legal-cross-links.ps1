#Requires -Version 5.1
<#
.SYNOPSIS
  Inserts or refreshes shared cross-links between privacy, terms, and operator pages for each product.
#>
param(
    [string] $PagesDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'pages')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\N78PublicLegalExpand.ps1')

$beginMarker = '<!-- BEGIN N78-FAMILY-LEGAL-CROSS-LINKS -->'
$endMarker = '<!-- END N78-FAMILY-LEGAL-CROSS-LINKS -->'

function Remove-CrossLinkBlock {
    param([string] $Content)
    $pattern = "(?s)\s*$([regex]::Escape($beginMarker)).*?$([regex]::Escape($endMarker))\s*"
    return [regex]::Replace($Content, $pattern, "`n")
}

function Get-CrossLinkBlock {
    param(
        [string] $DisplayName,
        [ValidateSet('privacy', 'terms', 'operator')][string] $Kind
    )
    $privacyUrl = Get-N78PublicLegalPageUrl -DisplayName $DisplayName -Kind 'privacy'
    $termsUrl = Get-N78PublicLegalPageUrl -DisplayName $DisplayName -Kind 'terms'
    $operatorUrl = Get-N78PublicLegalPageUrl -DisplayName $DisplayName -Kind 'operator'
    $intro = switch ($Kind) {
        'privacy' {
            "This Privacy Policy works together with the <a class=`"text-link`" href=`"$termsUrl`">Terms of Use</a> and <a class=`"text-link`" href=`"$operatorUrl`">Operator Responsibility Disclaimer</a> for <strong>$DisplayName</strong>. Shared liability, warranty, venue, and severability language appears in the Critical legal provisions section below and on the sibling documents."
        }
        'terms' {
            "These Terms of Use work together with the <a class=`"text-link`" href=`"$privacyUrl`">Privacy Policy</a> and <a class=`"text-link`" href=`"$operatorUrl`">Operator Responsibility Disclaimer</a> for <strong>$DisplayName</strong>. Shared liability, warranty, venue, and severability language appears in the Critical legal provisions section below and on the sibling documents."
        }
        'operator' {
            "This Operator Responsibility Disclaimer works together with the <a class=`"text-link`" href=`"$privacyUrl`">Privacy Policy</a> and <a class=`"text-link`" href=`"$termsUrl`">Terms of Use</a> for <strong>$DisplayName</strong>. Shared liability, warranty, venue, and severability language appears in the Critical legal provisions section below and on the sibling documents."
        }
    }
    @"
      $beginMarker
      <h2 id="n78-family-legal-related">Related legal documents (privacy, terms, operator disclaimer)</h2>
      <p>$intro</p>
      <ul>
        <li><a class="text-link" href="$privacyUrl">Privacy Policy</a></li>
        <li><a class="text-link" href="$termsUrl">Terms of Use</a></li>
        <li><a class="text-link" href="$operatorUrl">Operator Responsibility Disclaimer</a></li>
      </ul>
      $endMarker
"@
}

function Insert-CrossLinkBlock {
    param([string] $Content, [string] $Block)
    if ($Content -match '(?i)BEGIN N78-FAMILY-CRITICAL-LEGAL-PROVISIONS') {
        return [regex]::Replace($Content, '(?i)(\s*<!-- BEGIN N78-FAMILY-CRITICAL-LEGAL-PROVISIONS -->)', "$Block`n`n      `$1", 1)
    }
    $insertPatterns = @(
        '(?i)(<h2[^>]*>\s*(?:\d+\.\s*)?Contact\b)',
        '(?i)(<footer class="site-footer")',
        '(?i)(</article>)'
    )
    foreach ($pat in $insertPatterns) {
        if ($Content -match $pat) {
            return [regex]::Replace($Content, $pat, "$Block`n`n      `$1", 1)
        }
    }
    throw 'Could not find insertion point for cross-links'
}

function Normalize-WeakDisclaimerOverlap {
    param([string] $Content, [string] $Kind)
    if ($Kind -ne 'terms') { return $Content }
    $note = '<p><strong>Disclaimer overlap:</strong> Short warranty language elsewhere on this page is summarized; the <strong>Critical legal provisions</strong> block (UCC disclaimer, liability cap, venue, severability, and professional-advice disclaimer) controls if there is any conflict.</p>'
    if ($Content -match 'Disclaimer overlap') { return $Content }
    if ($Content -match '(?i)<h2[^>]*>\s*4\.\s*Disclaimer</h2>') {
        return [regex]::Replace($Content, '(?i)(<h2[^>]*>\s*4\.\s*Disclaimer</h2>\s*<p>.*?</p>)', "`$1`n      $note", 1)
    }
    return $Content
}

$updated = @()
Get-ChildItem -LiteralPath $PagesDir -File -Filter '*.html' | Sort-Object Name | ForEach-Object {
    $kind = if ($_.Name -match '\.privacy\.html$') { 'privacy' }
    elseif ($_.Name -match '\.terms\.html$') { 'terms' }
    elseif ($_.Name -match '\.operator\.html$') { 'operator' }
    else { return }

    $displayName = $_.BaseName -replace '\.(privacy|terms|operator)$', ''
    $block = Get-CrossLinkBlock -DisplayName $displayName -Kind $kind
    $raw = [IO.File]::ReadAllText($_.FullName)
    $text = Remove-CrossLinkBlock -Content $raw
    $text = Normalize-WeakDisclaimerOverlap -Content $text -Kind $kind
    $text = Insert-CrossLinkBlock -Content $text -Block $block

    if ($text -ne $raw) {
        [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false))
        $updated += $_.Name
    }
}

Write-Host "Cross-links updated on $($updated.Count) file(s)"
$updated | ForEach-Object { Write-Host "  $_" }
