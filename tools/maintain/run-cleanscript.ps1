#Requires -Version 5.1
<#
.SYNOPSIS
  N78-Public-Legal cleanscript — git report and cleanup before commit.

.DESCRIPTION
  Phase 1: git status for N78PublicLegal; optional -Commit / -Push
  Phase 2: remove regenerated staging and cache folders under this repo only.
#>
param(
    [switch] $Commit,
    [string] $CommitMessage = '',
    [switch] $Push,
    [switch] $SkipCleanup,
    [switch] $SkipGradleUnlock,
    [switch] $SkipGit,
    [switch] $SkipInteractiveWait,
    [string] $LogFile = ''
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\lib\N78ProductCleanscript.ps1"

$config = @{
    ProductCode           = 'N78PublicLegal'
    DisplayName           = 'N78-Public-Legal'
    RepoFolderName        = 'N78-Public-Legal'
    RootMarkers           = @('README.md', 'legal.css')
    GradleWRelativePaths  = @()
    CleanupDirNames       = @('.staging', 'out', 'bin', 'obj', '__pycache__')
    ExtraRelativePaths    = @()
    DocHint               = ''
    NextHint              = 'Next: tools\verify\verify-n78-std-legal-01-family.ps1 when legal corpus changes.'
    IncludeWebsiteGit     = $false
}

$code = Invoke-N78ProductCleanscript `
    -Config $config `
    -StartPath $PSScriptRoot `
    -Commit:$Commit `
    -CommitMessage $CommitMessage `
    -Push:$Push `
    -SkipCleanup:$SkipCleanup `
    -SkipGradleUnlock:$SkipGradleUnlock `
    -SkipGit:$SkipGit `
    -SkipInteractiveWait:$SkipInteractiveWait `
    -LogFile $LogFile
exit $code
