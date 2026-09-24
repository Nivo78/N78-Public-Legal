#Requires -Version 5.1
$ErrorActionPreference = 'Continue'
$repos = @(
    'C:\Users\Mike\Desktop\Nivo78\N78-Public-Legal',
    'C:\Users\Mike\Desktop\Nivo78\Business\N78-Kit',
    'C:\Users\Mike\Desktop\Nivo78\Common\N78-Theme',
    'C:\Users\Mike\Desktop\Nivo78\N78-StlLite',
    'C:\Users\Mike\Desktop\Nivo78\N78-Website',
    'C:\Users\Mike\Desktop\Nivo78\Business\N78-Successor',
    'C:\Users\Mike\Desktop\Nivo78\Business\N78-Template',
    'C:\Users\Mike\Desktop\Nivo78\N78-Machining',
    'C:\Users\Mike\Desktop\Nivo78\N78-Electrical',
    'C:\Users\Mike\Desktop\Nivo78\N78-Ops',
    'C:\Users\Mike\Desktop\Nivo78\N78-APA',
    'C:\Users\Mike\Desktop\Nivo78\N78-Dash',
    'C:\Users\Mike\Desktop\Nivo78\N78-Probe',
    'C:\Users\Mike\Desktop\Nivo78\N78-Track',
    'C:\Users\Mike\Desktop\Nivo78\N78-Frame',
    'C:\Users\Mike\Desktop\Nivo78\N78-Life',
    'C:\Users\Mike\Desktop\Nivo78\N78-Estimate',
    'C:\Users\Mike\Desktop\Nivo78\N78-Book',
    'C:\Users\Mike\Desktop\Nivo78\Business\N78-Standards',
    'C:\Users\Mike\Desktop\Nivo78\N78-QRTest'
)
$msg = "Canonical public legal on GitHub Pages (N78-Public-Legal).`n`nApps use nivo78.github.io legal URLs; N78-StlLite customer display name; kit/theme URL helpers."
foreach ($repo in $repos) {
    if (-not (Test-Path -LiteralPath (Join-Path $repo '.git'))) { continue }
    Push-Location -LiteralPath $repo
    $porcelain = git status --porcelain 2>$null
    if (-not $porcelain) { Pop-Location; continue }
    $short = Split-Path -Leaf $repo
    Write-Host "--- $short ---"
    git add -A 2>&1 | Out-Null
    git -c user.name=Nivo78 -c user.email=support@nivo78.com commit -m $msg 2>&1
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        continue
    }
    $hash = git rev-parse --short HEAD
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    git push origin $branch 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] $short $hash -> origin/$branch"
    } else {
        Write-Host "[FAIL push] $short $hash"
    }
    Pop-Location
}
