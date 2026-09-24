#Requires -Version 5.1
<#
.SYNOPSIS
  Write docs/Legal URL.md and docs/Legal URL.docx listing every published GitHub Pages URL in this repo.
#>
param(
    [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

function Encode-UriPathSegment([string]$s) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
    $out = [System.Text.StringBuilder]::new()
    foreach ($b in $bytes) {
        if (($b -ge 0x41 -and $b -le 0x5A) -or ($b -ge 0x61 -and $b -le 0x7A) -or ($b -ge 0x30 -and $b -le 0x39) -or $b -in 0x2D, 0x5F, 0x2E, 0x7E) {
            [void]$out.Append([char]$b)
        } else {
            [void]$out.Append('%' + $b.ToString('X2'))
        }
    }
    return $out.ToString()
}

$base = 'https://nivo78.github.io/N78-Public-Legal/'
$docsDir = Join-Path $RepoRoot 'docs'
New-Item -ItemType Directory -Path $docsDir -Force | Out-Null

$lines = @()
$lines += '# Nivo78 public legal URLs (N78-Public-Legal)'
$lines += ''
$lines += "Generated: $(Get-Date -Format 'MMMM d, yyyy')"
$lines += ''
$lines += "Canonical GitHub Pages base: ``$base``"
$lines += ''
$lines += '## Site root'
$lines += ''
foreach ($f in @('index.html', 'legal.css')) {
    $p = Join-Path $RepoRoot $f
    if (Test-Path -LiteralPath $p) {
        $lines += "- **$f** — $base$(Encode-UriPathSegment $f)"
    }
}
$lines += ''
$lines += '## Product privacy and terms (`pages/`)'
$lines += ''
$pagesDir = Join-Path $RepoRoot 'pages'
if (Test-Path -LiteralPath $pagesDir) {
    Get-ChildItem -LiteralPath $pagesDir -Filter '*.html' | Sort-Object Name | ForEach-Object {
        $rel = 'pages/' + $_.Name
        $enc = 'pages/' + (Encode-UriPathSegment $_.Name)
        $kind = if ($_.Name -match '\.privacy\.html$') { 'Privacy' } elseif ($_.Name -match '\.terms\.html$') { 'Terms' } else { 'Page' }
        $app = $_.Name -replace '\.(privacy|terms)\.html$', ''
        $lines += "- **$app — $kind** (``$rel``) — $base$enc"
    }
}

$mdPath = Join-Path $docsDir 'Legal URL.md'
$docxPath = Join-Path $docsDir 'Legal URL.docx'
$text = ($lines -join "`r`n") + "`r`n"
Set-Content -LiteralPath $mdPath -Value $text -Encoding UTF8

$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
if (-not $pandoc) {
    Write-Warning 'pandoc not on PATH — wrote docs/Legal URL.md only'
    exit 0
}

& pandoc $mdPath -o $docxPath -f markdown -t docx
Write-Host "Wrote $mdPath"
Write-Host "Wrote $docxPath"
