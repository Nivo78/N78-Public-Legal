#Requires -Version 5.1

function Get-N78PortfolioRootFromRepo {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $dir = (Resolve-Path -LiteralPath $RepoRoot).Path
    while ($dir) {
        if (Test-Path -LiteralPath (Join-Path $dir 'N78-Public-Legal\tools\verify\verify-n78-std-legal-01-family.ps1')) {
            return $dir
        }
        $parent = Split-Path -Parent $dir
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
    $fallback = Join-Path $env:USERPROFILE 'Desktop\Nivo78'
    if (Test-Path -LiteralPath (Join-Path $fallback 'N78-Public-Legal')) { return $fallback }
    throw "Could not locate Nivo78 portfolio root from $RepoRoot"
}

function Get-N78FamilyLegalVerifierLabel {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)]$Identity
    )
    $leaf = Split-Path -Leaf ((Resolve-Path -LiteralPath $RepoRoot).Path)
    if ($leaf -match '^N78-') { return $leaf }
    $display = [string]$Identity.display_name
    if (-not [string]::IsNullOrWhiteSpace($display)) { return $display.Trim() }
    return $leaf
}
