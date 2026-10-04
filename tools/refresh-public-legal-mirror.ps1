#Requires -Version 5.1
<#
.SYNOPSIS
  Full refresh: website sync, missing family pages, critical provisions, cross-links, URL catalog.
#>
param(
    [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch] $SkipWebsiteSync
)

$ErrorActionPreference = 'Stop'
$tools = $PSScriptRoot

if (-not $SkipWebsiteSync) {
    & (Join-Path $tools 'sync-from-n78-website.ps1') -RepoRoot $RepoRoot
}
& (Join-Path $tools 'ensure-all-family-legal-pages.ps1') -RepoRoot $RepoRoot
& (Join-Path $tools 'apply-family-critical-legal-provisions.ps1') -PagesDir (Join-Path $RepoRoot 'pages')
& (Join-Path $tools 'apply-legal-cross-links.ps1') -PagesDir (Join-Path $RepoRoot 'pages')
& (Join-Path $tools 'write-legal-url-catalog.ps1') -RepoRoot $RepoRoot
Write-Host '[PASS] refresh-public-legal-mirror complete'
