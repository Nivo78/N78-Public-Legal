#Requires -Version 5.1
<#
.SYNOPSIS
  Ensures every pages/*.privacy.html, *.terms.html, and *.operator.html includes family critical legal blocks.

.DESCRIPTION
  Inserts or refreshes a marked HTML block (UCC conspicuous disclaimer, liability cap, Texas venue,
  severability + merger, not professional legal/tax advice). Also normalizes legacy liability-cap wording.
#>
param(
    [string]$PagesDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'pages')
)

$ErrorActionPreference = 'Stop'
$beginMarker = '<!-- BEGIN N78-FAMILY-CRITICAL-LEGAL-PROVISIONS -->'
$endMarker = '<!-- END N78-FAMILY-CRITICAL-LEGAL-PROVISIONS -->'

function Get-ProductLabel {
    param([string]$BaseName)
    switch -Regex ($BaseName) {
        '^N78-APA$' { return 'App Publishing Assistant (N78-APA)' }
        '^N78-Ops$' { return 'N78-Ops' }
        default { return $BaseName }
    }
}

function Get-CriticalBlock {
    param([string]$ProductLabel, [string]$Kind)
    $siblingNote = switch ($Kind) {
        'privacy' {
            ' These provisions supplement this Privacy Policy; the <a class="text-link" href="#n78-family-terms-link">Terms of Use</a> and <a class="text-link" href="#n78-family-operator-link">Operator Responsibility Disclaimer</a> for this product also apply.'
        }
        'operator' {
            ' These provisions supplement this Operator Responsibility Disclaimer; the <a class="text-link" href="#n78-family-privacy-link">Privacy Policy</a> and <a class="text-link" href="#n78-family-terms-link">Terms of Use</a> for this product also apply.'
        }
        default { '' }
    }
    $merger = switch ($Kind) {
        'privacy' {
            'The Privacy Policy, Terms of Use, and Operator Responsibility Disclaimer (each as published for this product on N78-Public-Legal) constitute the entire agreement between you and Nivo78 Mobile Apps, LLC regarding the App and supersede prior or contemporaneous understandings on that subject, except for additional terms imposed by the applicable app store or platform.'
        }
        'operator' {
            'The Operator Responsibility Disclaimer, Terms of Use, and Privacy Policy (each as published for this product on N78-Public-Legal) constitute the entire agreement between you and Nivo78 Mobile Apps, LLC regarding the App and supersede prior or contemporaneous understandings on that subject, except for additional terms imposed by the applicable app store or platform.'
        }
        default {
            'The Terms of Use, Privacy Policy, and Operator Responsibility Disclaimer (each as published for this product on N78-Public-Legal) constitute the entire agreement between you and Nivo78 Mobile Apps, LLC regarding the App and supersede prior or contemporaneous understandings on that subject, except for additional terms imposed by the applicable app store or platform.'
        }
    }
    @'
      __BEGIN_MARKER__
      <h2 id="n78-family-critical-legal">Critical legal provisions (UCC, liability cap, venue, severability, professional advice)</h2>
      <p><strong>Product:</strong> __PRODUCT__ · <strong>Publisher:</strong> Nivo78 Mobile Apps, LLC · <strong>Updated:</strong> October 4, 2026.__SIBLING_NOTE__</p>

      <div class="n78-legal-ucc-callout" style="border: 2px solid #f59e0b; background: rgba(245, 158, 11, 0.08); padding: 16px 18px; margin: 16px 0; border-radius: 8px;">
        <p style="margin: 0 0 10px 0; font-weight: 700; color: #f8fafc; letter-spacing: 0.04em;">CONSPICUOUS WARRANTY DISCLAIMER (UCC &sect; 2-316 WHERE APPLICABLE)</p>
        <p style="margin: 0; color: #e2e8f0; line-height: 1.6; text-transform: uppercase;">
          THE APP IS PROVIDED &ldquo;AS IS&rdquo; AND &ldquo;AS AVAILABLE,&rdquo; WITH ALL FAULTS. TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, NIVO78 MOBILE APPS, LLC DISCLAIMS ALL WARRANTIES, WHETHER EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
        </p>
      </div>

      <p><strong>Limitation of liability:</strong> TO THE MAXIMUM EXTENT PERMITTED BY LAW, NIVO78 MOBILE APPS, LLC AND ITS OFFICERS, DIRECTORS, EMPLOYEES, CONTRACTORS, AND AFFILIATES SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, EXEMPLARY, OR PUNITIVE DAMAGES, OR FOR LOST PROFITS, LOST DATA, BUSINESS INTERRUPTION, OR PERSONAL INJURY ARISING FROM USE OF THE APP, EVEN IF ADVISED OF THE POSSIBILITY. <strong>LIABILITY CAP:</strong> IN NO EVENT WILL NIVO78 MOBILE APPS, LLC&rsquo;S TOTAL AGGREGATE LIABILITY ARISING OUT OF OR RELATED TO THE APP OR THESE LEGAL TERMS EXCEED THE GREATER OF (A) THE AMOUNT YOU PAID FOR THE APP IN THE TWELVE (12) MONTHS BEFORE THE EVENT GIVING RISE TO THE CLAIM, OR (B) FIFTY U.S. DOLLARS (USD&nbsp;$50.00).</p>

      <p><strong>Governing law:</strong> These legal terms are governed by the laws of the State of Texas, United States, without regard to conflict-of-law principles.</p>
      <p><strong>Venue:</strong> Any dispute arising out of or relating to the App or these legal terms shall be brought exclusively in the state or federal courts located in Smith County, Texas, and each party consents to personal jurisdiction and venue in those courts, except where applicable law requires otherwise.</p>
      <p><strong>Severability:</strong> If any provision is held invalid, illegal, or unenforceable by a court of competent jurisdiction, that provision will be enforced to the maximum extent permitted and the remaining provisions will remain in full force and effect.</p>
      <p><strong>Entire agreement (merger):</strong> __MERGER__</p>

      <p><strong>Not professional legal, tax, or financial advice:</strong> The App is software only. It is <strong>not</strong> a substitute for advice from a licensed attorney, certified public accountant (CPA), enrolled agent, or other qualified tax, accounting, or financial professional. You remain solely responsible for legal compliance, tax filings, regulatory obligations, and professional decisions.</p>
      __END_MARKER__
'@ -replace '__BEGIN_MARKER__', $beginMarker -replace '__PRODUCT__', $ProductLabel -replace '__SIBLING_NOTE__', $siblingNote -replace '__MERGER__', $merger -replace '__END_MARKER__', $endMarker
}

function Remove-ExistingBlock {
    param([string]$Content)
    $pattern = "(?s)\s*$([regex]::Escape($beginMarker)).*?$([regex]::Escape($endMarker))\s*"
    return [regex]::Replace($Content, $pattern, "`n")
}

function Normalize-LiabilityCap {
    param([string]$Content)
    $standard = 'IN NO EVENT WILL NIVO78 MOBILE APPS, LLC''S TOTAL AGGREGATE LIABILITY ARISING OUT OF OR RELATED TO THE APP OR THESE LEGAL TERMS EXCEED THE GREATER OF (A) THE AMOUNT YOU PAID FOR THE APP IN THE TWELVE (12) MONTHS BEFORE THE EVENT GIVING RISE TO THE CLAIM, OR (B) FIFTY U.S. DOLLARS (USD&nbsp;$50.00).'
    $patterns = @(
        '(?i)IN NO EVENT SHALL NIVO78[^<]{0,220}EXCEED THE ACTUAL AMOUNT PAID[^<]{0,120}',
        '(?i)OUR TOTAL LIABILITY FOR ANY CLAIM WILL NOT EXCEED THE GREATER OF \(A\) THE AMOUNT YOU PAID US FOR THE APP\s+IN THE TWELVE MONTHS BEFORE THE CLAIM OR \(B\) USD \$50\.',
        'FIFTY U\.S\. DOLLARS \(USD&nbsp;\.00\)'
    )
    foreach ($pat in $patterns) {
        if ($Content -match $pat) {
            if ($pat -match '\.00\)') {
                $Content = $Content -replace 'USD&nbsp;\.00', 'USD&nbsp;$50.00'
            } else {
                $Content = [regex]::Replace($Content, $pat, $standard)
            }
        }
    }
    return $Content
}

function Get-LegalPageKind {
    param([string] $FileName)
    if ($FileName -match '\.privacy\.html$') { return 'privacy' }
    if ($FileName -match '\.terms\.html$') { return 'terms' }
    if ($FileName -match '\.operator\.html$') { return 'operator' }
    return $null
}

function Insert-CriticalBlock {
    param([string]$Content, [string]$Block)
    $insertPatterns = @(
        '(?i)(<h2[^>]*>\s*(?:\d+\.\s*)?Contact\b)',
        '(?i)(<h2[^>]*>\s*(?:\d+\.\s*)?Policy Changes\b)',
        '(?i)(<h2[^>]*>\s*(?:\d+\.\s*)?Contact &amp; Business Inquiries\b)',
        '(?i)(<footer class="site-footer")'
    )
    foreach ($pat in $insertPatterns) {
        if ($Content -match $pat) {
            return [regex]::Replace($Content, $pat, "$Block`n`n      `$1", 1)
        }
    }
    if ($Content -match '(?i)(</article>)') {
        return [regex]::Replace($Content, '(?i)(</article>)', "$Block`n`n    `$1", 1)
    }
    throw "Could not find insertion point in file"
}

$files = Get-ChildItem -LiteralPath $PagesDir -File -Filter '*.html' | Sort-Object Name
$updated = @()
foreach ($file in $files) {
    $kind = Get-LegalPageKind -FileName $file.Name
    if (-not $kind) { continue }
    $base = $file.BaseName -replace '\.(privacy|terms|operator)$', ''
    $label = Get-ProductLabel -BaseName $base
    $block = Get-CriticalBlock -ProductLabel $label -Kind $kind

    $raw = [IO.File]::ReadAllText($file.FullName)
    $text = Remove-ExistingBlock -Content $raw
    $text = Normalize-LiabilityCap -Content $text
    $text = Insert-CriticalBlock -Content $text -Block $block

    $pagesBase = "https://nivo78.github.io/N78-Public-Legal/pages"
    if ($kind -eq 'privacy') {
        $text = $text.Replace('href="#n78-family-terms-link"', "href=`"$pagesBase/$base.terms.html`" id=`"n78-family-terms-link`"")
        $text = $text.Replace('href="#n78-family-operator-link"', "href=`"$pagesBase/$base.operator.html`" id=`"n78-family-operator-link`"")
    }
    if ($kind -eq 'operator') {
        $text = $text.Replace('href="#n78-family-privacy-link"', "href=`"$pagesBase/$base.privacy.html`" id=`"n78-family-privacy-link`"")
        $text = $text.Replace('href="#n78-family-terms-link"', "href=`"$pagesBase/$base.terms.html`" id=`"n78-family-terms-link`"")
    }

    if ($text -ne $raw) {
        [IO.File]::WriteAllText($file.FullName, $text, [Text.UTF8Encoding]::new($false))
        $updated += $file.Name
    }
}

Write-Host "Updated $($updated.Count) file(s) under $PagesDir"
$updated | ForEach-Object { Write-Host "  $_" }
