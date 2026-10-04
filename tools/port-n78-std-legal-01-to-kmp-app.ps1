#Requires -Version 7.0
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [Parameter(Mandatory = $true)]
    [string]$PackagePrefix,
    [Parameter(Mandatory = $true)]
    [string]$PackageSegment,
    [Parameter(Mandatory = $true)]
    [string]$DisplayName,
    [Parameter(Mandatory = $true)]
    [string]$WebsiteSlug,
    [Parameter(Mandatory = $true)]
    [string]$CatalogName,
    [Parameter(Mandatory = $true)]
    [string]$UrlsObjectName,
    [string]$TemplateRoot = (Join-Path $PSScriptRoot "..\..\N78-Machining\shared\src"),
    [string]$TermsVersion = "1",
    [string]$TermsEffectiveIso = "2026-10-01"
)

$ErrorActionPreference = "Stop"
$sharedSrc = Join-Path $RepoRoot "shared\src"
if (-not (Test-Path $sharedSrc)) { throw "No shared\src under $RepoRoot" }

$ctxFn = "${PackageSegment}AndroidApplicationContext"
$pkgPath = $PackagePrefix.Replace(".", "\")

function Copy-LegalTree {
    param([hashtable]$Map)
    foreach ($rel in $Map.Keys) {
        $src = Join-Path $TemplateRoot $rel
        $dst = Join-Path $sharedSrc $Map[$rel]
        if (-not (Test-Path $src)) { throw "Missing template $src" }
        $dir = Split-Path $dst -Parent
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $text = Get-Content -Raw -Path $src
        $text = $text -replace 'com\.nivo78\.machining', $PackagePrefix
        $text = $text -replace 'MachiningLegalCatalog', $CatalogName
        $text = $text -replace 'MachiningLegalUrls', $UrlsObjectName
        $text = $text -replace 'machiningAndroidApplicationContext', $ctxFn
        $text = $text -replace 'nivo78/machining/legal', "nivo78/$WebsiteSlug/legal"
        $text = $text -replace 'https://nivo78\.com/machining/legal-manifest\.json', "https://nivo78.com/$WebsiteSlug/legal-manifest.json"
        $text = $text -replace 'N78-Machining', $DisplayName
        $text = $text -replace 'MachiningLegalCatalog', $CatalogName
        Set-Content -Path $dst -Value $text -Encoding utf8 -NoNewline
    }
}

$legalMap = @{
    "commonMain\kotlin\com\nivo78\machining\legal\LegalDocumentSnapshot.kt" = "commonMain\kotlin\$pkgPath\legal\LegalDocumentSnapshot.kt"
    "commonMain\kotlin\com\nivo78\machining\legal\LegalHtmlPlainText.kt" = "commonMain\kotlin\$pkgPath\legal\LegalHtmlPlainText.kt"
    "commonMain\kotlin\com\nivo78\machining\legal\LegalPlatformPort.kt" = "commonMain\kotlin\$pkgPath\legal\LegalPlatformPort.kt"
    "commonMain\kotlin\com\nivo78\machining\legal\LegalSnapshotRepository.kt" = "commonMain\kotlin\$pkgPath\legal\LegalSnapshotRepository.kt"
    "commonMain\kotlin\com\nivo78\machining\ui\Nivo78LegalScrollToEndEffect.kt" = "commonMain\kotlin\$pkgPath\ui\Nivo78LegalScrollToEndEffect.kt"
    "commonMain\kotlin\com\nivo78\machining\ui\FamilyLegalDocumentModal.kt" = "commonMain\kotlin\$pkgPath\ui\FamilyLegalDocumentModal.kt"
    "commonMain\kotlin\com\nivo78\machining\ui\LegalDocumentAttribution.kt" = "commonMain\kotlin\$pkgPath\ui\LegalDocumentAttribution.kt"
    "desktopMain\kotlin\com\nivo78\machining\legal\LegalPlatformPort.desktop.kt" = "desktopMain\kotlin\$pkgPath\legal\LegalPlatformPort.desktop.kt"
    "androidMain\kotlin\com\nivo78\machining\legal\LegalPlatformPort.android.kt" = "androidMain\kotlin\$pkgPath\legal\LegalPlatformPort.android.kt"
    "iosMain\kotlin\com\nivo78\machining\legal\LegalPlatformPort.ios.kt" = "iosMain\kotlin\$pkgPath\legal\LegalPlatformPort.ios.kt"
    "desktopTest\kotlin\com\nivo78\machining\legal\LegalHtmlPlainTextTest.kt" = "desktopTest\kotlin\$($PackagePrefix.Replace('com.','').Replace('.','\'))\legal\LegalHtmlPlainTextTest.kt"
}
# Fix test path - use package path
$testPkgPath = $pkgPath
$legalMap["desktopTest\kotlin\com\nivo78\machining\legal\LegalHtmlPlainTextTest.kt"] = "desktopTest\kotlin\$testPkgPath\legal\LegalHtmlPlainTextTest.kt"
$legalMap["desktopTest\kotlin\com\nivo78\machining\legal\LegalSnapshotRepositoryTest.kt"] = "desktopTest\kotlin\$testPkgPath\legal\LegalSnapshotRepositoryTest.kt"

Copy-LegalTree -Map $legalMap

# Baselines
$termsBaseline = @"
$DisplayName — Terms of Use (bundled baseline)

Effective Date: $TermsEffectiveIso
Version: $TermsVersion

$DisplayName is a local-first Nivo78 utility. You are responsible for how you use outputs, exports, and device data.

Nivo78 Mobile Apps, LLC provides the software as-is without warranty to the maximum extent permitted by law.

Open the canonical Terms URL when online for the full agreement on GitHub Pages.

End of bundled Terms baseline.
"@
$privacyBaseline = @"
$DisplayName — Privacy Policy (bundled baseline)

Last Updated: $TermsEffectiveIso
Version: $TermsVersion

Core product data stays on this device unless you explicitly export or use optional network features you choose.

Open the canonical Privacy URL when online for the full policy on GitHub Pages.

End of bundled Privacy baseline.
"@

foreach ($base in @("commonMain\resources\legal", "androidMain\assets\legal")) {
    $dir = Join-Path $sharedSrc $base
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Set-Content -Path (Join-Path $dir "terms-baseline.txt") -Value $termsBaseline -Encoding utf8
    Set-Content -Path (Join-Path $dir "privacy-baseline.txt") -Value $privacyBaseline -Encoding utf8
}

# Catalog versions in LegalDocumentSnapshot
$catalogFile = Join-Path $sharedSrc "commonMain\kotlin\$pkgPath\legal\LegalDocumentSnapshot.kt"
$cText = Get-Content -Raw $catalogFile
$cText = $cText -replace 'BUNDLED_TERMS_VERSION: String = "[^"]+"', "BUNDLED_TERMS_VERSION: String = `"$TermsVersion`""
$cText = $cText -replace 'BUNDLED_PRIVACY_VERSION: String = "[^"]+"', "BUNDLED_PRIVACY_VERSION: String = `"$TermsVersion`""
$cText = $cText -replace 'BUNDLED_TERMS_EFFECTIVE_ISO: String = "[^"]+"', "BUNDLED_TERMS_EFFECTIVE_ISO: String = `"$TermsEffectiveIso`""
$cText = $cText -replace 'BUNDLED_PRIVACY_EFFECTIVE_ISO: String = "[^"]+"', "BUNDLED_PRIVACY_EFFECTIVE_ISO: String = `"$TermsEffectiveIso`""
Set-Content -Path $catalogFile -Value $cText -Encoding utf8 -NoNewline

# LegalUrls identity
$idDir = Join-Path $sharedSrc "commonMain\kotlin\$pkgPath\identity"
New-Item -ItemType Directory -Force -Path $idDir | Out-Null
$urlsFile = Join-Path $idDir "${PackageSegment}LegalUrls.kt"
if (-not (Test-Path $urlsFile)) {
    @"
package $PackagePrefix.identity

import com.nivo78.theme.legal.N78FamilyPublicLegalUrls

object $UrlsObjectName {
    private const val DISPLAY_NAME = "$DisplayName"

    val privacy: String = N78FamilyPublicLegalUrls.privacy(DISPLAY_NAME)
    val terms: String = N78FamilyPublicLegalUrls.terms(DISPLAY_NAME)
}
"@ | Set-Content -Path $urlsFile -Encoding utf8
}

# Patch FamilyLegalGate
$gateFile = Get-ChildItem (Join-Path $sharedSrc "commonMain\kotlin\$pkgPath\ui\FamilyLegalGate.kt") -ErrorAction SilentlyContinue
if ($gateFile) {
    $g = Get-Content -Raw $gateFile.FullName
    if ($g -match 'FamilyLegalScrollDocumentModal') {
        $g = $g -replace 'var showTermsModal by remember \{ mutableStateOf\(false\) \}\s*\r?\n\s*var showPrivacyModal by remember \{ mutableStateOf\(false\) \}', 'var showLegalModalKind by remember { mutableStateOf<LegalDocumentKind?>(null) }'
        $g = $g -replace '(?s)if \(showTermsModal\) \{.*?\}\s*if \(showPrivacyModal\) \{.*?\}\s*\r?\n', @'
    if (showLegalModalKind != null) {
        FamilyLegalDocumentModal(
            initialDocument = showLegalModalKind ?: LegalDocumentKind.TermsOfUse,
            onDismiss = { showLegalModalKind = null },
            onTermsScrolledToEnd = { termsScrolledToEnd = true },
            onPrivacyScrolledToEnd = { privacyScrolledToEnd = true },
        )
    }

'@
        $g = $g -replace 'showTermsModal = true', 'showLegalModalKind = LegalDocumentKind.TermsOfUse'
        $g = $g -replace 'showPrivacyModal = true', 'showLegalModalKind = LegalDocumentKind.PrivacyPolicy'
        $g = $g -replace 'FamilyUtilityLegalDisclaimer\.TERMS_SCROLL_BODY', '/* snapshot */'
        Set-Content -Path $gateFile.FullName -Value $g -Encoding utf8 -NoNewline
    }
}

# Remove duplicate scroll effect in FamilyLegalScrollDocumentModal
$scrollModal = Join-Path $sharedSrc "commonMain\kotlin\$pkgPath\ui\FamilyLegalScrollDocumentModal.kt"
if (Test-Path $scrollModal) {
    $s = Get-Content -Raw $scrollModal
    $s = $s -replace '(?s)\r?\n@Composable\r?\nprivate fun Nivo78LegalScrollToEndEffect.*', ''
    $s = $s -replace 'import androidx.compose.runtime.LaunchedEffect\r?\n', ''
    Set-Content -Path $scrollModal -Value $s -Encoding utf8 -NoNewline
}

# Android context helper
$androidPlatform = Get-ChildItem (Join-Path $sharedSrc "androidMain\kotlin\$pkgPath\platform\Platform.kt") -ErrorAction SilentlyContinue | Select-Object -First 1
if ($androidPlatform -and (Get-Content -Raw $androidPlatform.FullName) -notmatch [regex]::Escape($ctxFn)) {
    $p = Get-Content -Raw $androidPlatform.FullName
    $p = $p -replace '(fun bindN78AndroidContext\(context: android\.content\.Context\) \{\s*\r?\n\s*appContext\.set\(context\.applicationContext\)\s*\r?\n\})', "`$1`n`nfun $ctxFn(): android.content.Context? = appContext.get()"
    Set-Content -Path $androidPlatform.FullName -Value $p -Encoding utf8 -NoNewline
}

# build.gradle.kts shared
$gradle = Join-Path $RepoRoot "shared\build.gradle.kts"
if (Test-Path $gradle) {
    $gr = Get-Content -Raw $gradle
    if ($gr -notmatch 'kotlinSerialization') {
        $gr = $gr -replace '(plugins \{[^\}]*kotlinMultiplatform\))', "`$1`r`n    alias(libs.plugins.kotlinSerialization)"
    }
    if ($gr -notmatch 'kotlinx\.coroutines\.core') {
        $gr = $gr -replace '(commonMain\.dependencies \{[^\r\n]*)', "`$1`r`n            implementation(libs.kotlinx.coroutines.core)"
    }
    if ($gr -notmatch 'kotlinx\.serialization\.json') {
        $gr = $gr -replace '(commonMain\.dependencies \{[^\r\n]*)', "`$1`r`n            implementation(libs.kotlinx.serialization.json)"
    }
    Set-Content -Path $gradle -Value $gr -Encoding utf8 -NoNewline
}

Write-Host "OK port legal stack -> $RepoRoot ($DisplayName)"
