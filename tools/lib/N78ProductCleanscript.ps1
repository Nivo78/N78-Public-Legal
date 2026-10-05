#Requires -Version 5.1
<#
.SYNOPSIS
  Shared Nivo78 product cleanscript engine — git report and regenerated-output cleanup.
  Copied into each product at tools/lib/N78ProductCleanscript.ps1. Do not point products at N78Kit at runtime.
#>

function Get-N78CleanscriptPwshExecutable {
    $bases = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA)
    foreach ($base in $bases) {
        if (-not [string]::IsNullOrWhiteSpace($base)) {
            $candidate = Join-Path $base 'PowerShell\7\pwsh.exe'
            if (Test-Path -LiteralPath $candidate) { return $candidate }
            $candidatePreview = Join-Path $base 'PowerShell\7-preview\pwsh.exe'
            if (Test-Path -LiteralPath $candidatePreview) { return $candidatePreview }
        }
    }
    $fromPath = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    if ($env:SystemRoot) {
        return (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe')
    }
    return 'powershell.exe'
}

function Get-N78CleanscriptRepoRoot {
    param(
        [Parameter(Mandatory)] [string] $StartPath,
        [Parameter(Mandatory)] [string] $RepoFolderName,
        [Parameter(Mandatory)] [string[]] $RootMarkers
    )

    $cursor = $StartPath
    while ($cursor) {
        $hit = $false
        foreach ($marker in $RootMarkers) {
            if (Test-Path -LiteralPath (Join-Path $cursor $marker)) {
                $hit = $true
                break
            }
        }
        if ($hit) { return $cursor }
        $parent = Split-Path -Parent $cursor
        if (-not $parent -or $parent -eq $cursor) { break }
        $cursor = $parent
    }

    foreach ($fallback in @(
            (Join-Path $env:USERPROFILE "Desktop\Nivo78\$RepoFolderName"),
            "C:\Users\Mike\Desktop\Nivo78\$RepoFolderName"
        )) {
        foreach ($marker in $RootMarkers) {
            if (Test-Path -LiteralPath (Join-Path $fallback $marker)) { return $fallback }
        }
    }
    return $null
}

function Test-N78CleanscriptSkipWalkPath {
    param([Parameter(Mandatory)] [string] $FullName)
    return ($FullName -match '[\\/]\.git([\\/]|$)' -or $FullName -match '[\\/]\.idea([\\/]|$)' -or $FullName -match '[\\/]\.cursor([\\/]|$)')
}

function Invoke-N78ProductCleanscript {
    param(
        [Parameter(Mandatory)] [hashtable] $Config,
        [Parameter(Mandatory)] [string] $StartPath,
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
    $exitCode = 0
    $productCode = [string]$Config.ProductCode
    $displayName = [string]$Config.DisplayName
    $repoFolder = [string]$Config.RepoFolderName
    $markers = @($Config.RootMarkers)
    $gradlewRels = @($Config.GradleWRelativePaths)
    $cleanupNames = @($Config.CleanupDirNames)
    $extraRels = @($Config.ExtraRelativePaths)
    $docHint = [string]$Config.DocHint
    $nextHint = [string]$Config.NextHint
    $includeWebsiteGit = [bool]$Config.IncludeWebsiteGit
    $logFile = $LogFile.Trim()

    function Write-Log {
        param([string] $Message, [string] $Color = 'White')
        if ($logFile) {
            $line = "$(Get-Date -Format 'HH:mm:ss')  $Message"
            Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
        }
        Write-Host $Message -ForegroundColor $Color
    }

    function Wait-IfInteractiveConsole {
        if ($SkipInteractiveWait) { return }
        if (-not [Environment]::UserInteractive) { return }
        try {
            if ([Console]::IsInputRedirected) { return }
        } catch {
            return
        }
        Read-Host 'Press Enter to close'
    }

    function Invoke-GitStep {
        param(
            [Parameter(Mandatory)] [string] $Root,
            [Parameter(Mandatory)] [string[]] $Arguments,
            [Parameter(Mandatory)] [string] $Label
        )
        Push-Location -LiteralPath $Root
        try {
            $output = & git @Arguments 2>&1
            $output | ForEach-Object { Write-Log $_.ToString() 'DarkGray' }
            if ($LASTEXITCODE -ne 0) {
                throw "$Label failed with exit code $LASTEXITCODE"
            }
        } finally {
            Pop-Location
        }
    }

    function Write-GitStatus {
        param(
            [Parameter(Mandatory)] [string] $Root,
            [Parameter(Mandatory)] [string] $Label
        )
        if (-not (Test-Path -LiteralPath (Join-Path $Root '.git'))) {
            Write-Log "$Label -- not a git repo: $Root" 'Yellow'
            return
        }
        Write-Log "$Label ($Root):" 'Cyan'
        Push-Location -LiteralPath $Root
        try {
            $status = & git status --short 2>&1
            if (-not $status) {
                Write-Log '  Working tree clean.' 'Green'
            } else {
                $status | ForEach-Object { Write-Log "  $_" 'Yellow' }
            }
        } finally {
            Pop-Location
        }
    }

    function Commit-IfRequested {
        param(
            [Parameter(Mandatory)] [string] $Root,
            [Parameter(Mandatory)] [string] $Label
        )
        if (-not $Commit) { return }
        if (-not (Test-Path -LiteralPath (Join-Path $Root '.git'))) { return }
        Push-Location -LiteralPath $Root
        try {
            $status = & git status --short 2>&1
            if (-not $status) { return }
            Invoke-GitStep -Root $Root -Arguments @('add', '-A') -Label "$Label git add"
            Invoke-GitStep -Root $Root -Arguments @('commit', '-m', $CommitMessage) -Label "$Label git commit"
            Write-Log "Committed $Label changes." 'Green'
            if ($Push) {
                Invoke-GitStep -Root $Root -Arguments @('push', 'origin', 'HEAD') -Label "$Label git push"
                Write-Log "Pushed $Label to origin." 'Green'
            }
        } finally {
            Pop-Location
        }
    }

    function Get-FolderSizeBytes {
        param([Parameter(Mandatory)] [string] $Path)
        if (-not (Test-Path -LiteralPath $Path)) { return [long]0 }
        $measure = Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum
        if ($null -eq $measure.Sum) { return [long]0 }
        return [long]$measure.Sum
    }

    function Format-Size {
        param([long] $Bytes)
        if ($Bytes -ge 1GB) { return '{0:N2} GB' -f ($Bytes / 1GB) }
        if ($Bytes -ge 1MB) { return '{0:N1} MB' -f ($Bytes / 1MB) }
        return '{0:N0} KB' -f ($Bytes / 1KB)
    }

    function Remove-RegeneratedPath {
        param(
            [Parameter(Mandatory)] [string] $Path,
            [Parameter(Mandatory)] [string] $Label
        )
        if (-not (Test-Path -LiteralPath $Path)) { return [long]0 }
        $sizeBytes = Get-FolderSizeBytes -Path $Path
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            Write-Log ("Removed {0} ({1})" -f $Label, (Format-Size $sizeBytes)) 'DarkGray'
            return [long]$sizeBytes
        } catch {
            Write-Log ("Could not remove {0}: {1}" -f $Label, $_.Exception.Message) 'Yellow'
            return [long]0
        }
    }

    function Stop-RepoGradleLockHolders {
        param([Parameter(Mandatory)] [string] $RepoRoot)
        $gradleStopCount = 0
        $processStopCount = 0
        foreach ($rel in $gradlewRels) {
            if ([string]::IsNullOrWhiteSpace($rel)) { continue }
            $gradlew = Join-Path $RepoRoot $rel
            if (-not (Test-Path -LiteralPath $gradlew)) { continue }
            $work = Split-Path -Parent $gradlew
            Push-Location -LiteralPath $work
            try {
                & $gradlew --stop 2>&1 | Out-Null
                $gradleStopCount++
            } catch {
                Write-Log "gradlew --stop failed in ${work}: $($_.Exception.Message)" 'Yellow'
            } finally {
                Pop-Location
            }
        }
        if ($gradleStopCount -gt 0) {
            Start-Sleep -Seconds 1
        }
        $escapedRoot = [Regex]::Escape($RepoRoot)
        Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match '^(java|javaw)\.exe$' -and
                $_.CommandLine -and
                $_.CommandLine -match $escapedRoot -and
                (
                    $_.CommandLine -match 'GradleDaemon|KotlinCompileDaemon|gradle-wrapper' -or
                    $_.CommandLine -match '[\\/]gradle[\\/]'
                )
            } |
            ForEach-Object {
                try {
                    Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop
                    $processStopCount++
                } catch {
                    Write-Log ("Could not stop PID {0}: {1}" -f $_.ProcessId, $_.Exception.Message) 'Yellow'
                }
            }
        return [pscustomobject]@{
            GradleStopCount  = $gradleStopCount
            ProcessStopCount = $processStopCount
        }
    }

    try {
        if ($logFile) {
            Set-Content -LiteralPath $logFile -Value "=== $productCode cleanscript ===" -Encoding UTF8
        }

        Write-Log ''
        Write-Log '========================================' 'Cyan'
        Write-Log " $displayName cleanscript" 'Cyan'
        if ($docHint) {
            Write-Log " $docHint" 'Cyan'
        }
        Write-Log '========================================' 'Cyan'

        $repoRoot = Get-N78CleanscriptRepoRoot -StartPath $StartPath -RepoFolderName $repoFolder -RootMarkers $markers
        if (-not $repoRoot) {
            Write-Log "ERROR: $productCode repo not found (markers: $($markers -join ', '))." 'Red'
            $exitCode = 1
            throw 'repo-not-found'
        }

        $websiteRoot = Join-Path (Split-Path -Parent $repoRoot) 'Website'
        Write-Log "Repo: $repoRoot"
        if ($includeWebsiteGit) {
            Write-Log "Website: $websiteRoot" 'DarkGray'
        }
        Write-Log ("Shell: {0}" -f (Get-N78CleanscriptPwshExecutable)) 'DarkGray'

        if (-not $SkipGit) {
            Write-Log ''
            Write-Log '=== Phase 1: git status ===' 'Cyan'
            Write-GitStatus -Root $repoRoot -Label $productCode
            if ($includeWebsiteGit) {
                Write-GitStatus -Root $websiteRoot -Label 'Website'
            }
            if ($Commit) {
                if (-not $CommitMessage.Trim()) {
                    Write-Log 'ERROR: -Commit requires -CommitMessage.' 'Red'
                    $exitCode = 1
                    throw 'missing-commit-message'
                }
                Commit-IfRequested -Root $repoRoot -Label $productCode
                if ($includeWebsiteGit) {
                    Commit-IfRequested -Root $websiteRoot -Label 'Website'
                }
            } else {
                Write-Log 'Uncommitted changes may remain (pass -Commit -CommitMessage to ship).' 'Yellow'
            }
            Write-Log 'Phase 1 PASSED' 'Green'
        } else {
            Write-Log ''
            Write-Log 'Skipped Phase 1 (-SkipGit).' 'Yellow'
        }

        $hasGradle = $false
        foreach ($rel in $gradlewRels) {
            if ($rel -and (Test-Path -LiteralPath (Join-Path $repoRoot $rel))) {
                $hasGradle = $true
                break
            }
        }

        if (-not $SkipCleanup) {
            if ($hasGradle -and -not $SkipGradleUnlock) {
                Write-Log ''
                Write-Log "=== Phase 2a: stop Gradle lock holders ($productCode) ===" 'Cyan'
                $unlockResult = Stop-RepoGradleLockHolders -RepoRoot $repoRoot
                Write-Log (
                    "Stopped gradlew in $($unlockResult.GradleStopCount) location(s); ended $($unlockResult.ProcessStopCount) Gradle-related process(es)."
                ) 'DarkGray'
            } elseif ($hasGradle) {
                Write-Log ''
                Write-Log 'Skipped Phase 2a (-SkipGradleUnlock).' 'Yellow'
            }

            Write-Log ''
            Write-Log "=== Phase 2b: cleanup regenerated output ($productCode) ===" 'Cyan'
            Write-Log "Cleanup regenerated output under $repoRoot"
            $removedBytes = [long]0
            if ($cleanupNames.Count -gt 0) {
                Get-ChildItem -LiteralPath $repoRoot -Recurse -Directory -Force -ErrorAction SilentlyContinue |
                    Where-Object { $cleanupNames -contains $_.Name -and -not (Test-N78CleanscriptSkipWalkPath -FullName $_.FullName) } |
                    Sort-Object FullName -Descending |
                    ForEach-Object {
                        $removedBytes += Remove-RegeneratedPath -Path $_.FullName -Label $_.FullName
                    }
            }
            foreach ($rel in $extraRels) {
                if ([string]::IsNullOrWhiteSpace($rel)) { continue }
                $p = Join-Path $repoRoot $rel
                $removedBytes += Remove-RegeneratedPath -Path $p -Label $p
            }
            Write-Log ("Cleanup complete -- freed about {0}." -f (Format-Size $removedBytes)) 'DarkGray'
            Write-Log 'Phase 2b PASSED' 'Green'
        } else {
            Write-Log ''
            Write-Log 'Skipped Phase 2 (-SkipCleanup).' 'Yellow'
        }

        Write-Log ''
        Write-Log 'CLEANSCRIPT PASSED' 'Green'
        if ($nextHint) {
            Write-Log $nextHint 'DarkGray'
        }
    } catch {
        if ($_.Exception.Message -notin @('missing-commit-message', 'repo-not-found')) {
            Write-Log "ERROR: $($_.Exception.Message)" 'Red'
            if ($exitCode -eq 0) { $exitCode = 1 }
        }
    } finally {
        if ($logFile) {
            Write-Log ''
            Write-Log "Log saved: $logFile" 'DarkGray'
        }
        Write-Log ''
        Wait-IfInteractiveConsole
    }

    return $exitCode
}
