#Requires -Version 7.0
<#
.SYNOPSIS
  Idempotently insert Invoke-N78StdLegal01ProductVerify into verify-product.ps1 after identity check.
#>
param(
    [Parameter(Mandatory = $true)][string]$VerifyProductPath
)

$ErrorActionPreference = 'Stop'
$path = (Resolve-Path -LiteralPath $VerifyProductPath).Path
$text = Get-Content -LiteralPath $path -Raw
if ($text -match 'Invoke-N78StdLegal01ProductVerify') {
    Write-Host "Already wired: $path"
    exit 0
}
$marker = "if (-not (Test-Path -LiteralPath `$id)) {"
$hook = @'

$legalInvoke = Join-Path $env:USERPROFILE 'Desktop\Nivo78\N78-Public-Legal\tools\verify\Invoke-N78StdLegal01ProductVerify.ps1'
if (Test-Path -LiteralPath $legalInvoke) {
    & pwsh -NoProfile -File $legalInvoke -RepoRoot $repoRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'N78-STD-LEGAL-01 product verify failed.'
    }
}

'@
if ($text -notlike "*$marker*") { throw "Could not find identity marker in $path" }
$text = $text.Replace(
    "if (-not (Test-Path -LiteralPath `$id)) {`r`n    throw 'Missing product.identity.json'`r`n}",
    "if (-not (Test-Path -LiteralPath `$id)) {`r`n    throw 'Missing product.identity.json'`r`n}`r`n$hook"
)
Set-Content -LiteralPath $path -Value $text -Encoding UTF8 -NoNewline
Write-Host "Wired legal verify hook: $path" -ForegroundColor Green
