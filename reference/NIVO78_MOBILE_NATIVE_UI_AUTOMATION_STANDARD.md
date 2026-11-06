# Nivo78 mobile native UI automation standard (Phase 4B)

**Standard ID:** N78-MOBILE-NATIVE-UI-AUTOMATION  
**Rule ID (projection):** **FAMILY-N78-MOBILE-NATIVE-UI-AUTOMATION** [GATE / QA — product matrix]  
**Authority:** Supplements `NIVO78_ON_SCREEN_QA_TESTING_STANDARD.md` §2.8; complements **N78-TEST-001** Layer 3 and **N78-QA-001** device evidence.

## 1. Scope and separation from desktop OCR

| Platform | Primary installed / on-device UI automation |
| -------- | --------------------------------------------- |
| **Windows desktop** (.exe, WinForms, Compose Desktop installed pilots) | **OCR-first** — `FAMILY-N78-OCR-FIRST-UI-TARGETING`, N78OcrResult v1, Stage-4 installed readonly pilot where **REQUIRED** in `NIVO78_OCR_PLATFORM_APPLICABILITY.json` |
| **Android** | **Native** — instrumented tests, UI Automator, Espresso / Compose UI Test, accessibility semantics, resource identifiers |
| **iOS** | **Native** — XCTest, XCUITest, accessibility identifiers and labels |

Mobile applications **MUST NOT** be required to use desktop OCR tooling, ML Kit OCR bounding boxes, or OCR-based tapping for mandatory release gates.

Optional OCR-based diagnostics (Phase 4A experimental adapter) may exist for engineering comparison only — see `mobileOptionalOcrDiagnostic` in the applicability registry.

## 2. Android requirements

Use **native Android testing infrastructure** on emulator or physical device (API level per product `minSdk`):

| Mechanism | Use |
| --------- | --- |
| **Android instrumented tests** | Production-faithful APK (`debug` / product documented variant) on device |
| **Compose UI Test / Espresso** | In-process interaction with rendered Compose or View hierarchies |
| **UI Automator** | Cross-app or full-screen gestures when in-process APIs are insufficient |
| **Accessibility** | `contentDescription`, semantics / test tags, resource ids — **primary control identification** |
| **Screenshots** | Platform capture (`UiDevice.takeScreenshot`, on-failure screenshots, manual QA attachments) — **not** mandatory OCR JSON |
| **State verification** | Assert visible text, semantics, navigation destination, persisted state after **every** interaction |

**Mandatory behaviors:**

1. Test **actual rendered** application interfaces (retail shell or documented test harness that mirrors retail navigation).
2. Identify controls with **appropriate native selectors** — not raw coordinate guessing as the primary strategy.
3. **Verify resulting state** after every interaction (visible UI, toasts, dialogs dismissed, data saved).
4. Cover **missing, disabled, unavailable**, and incorrectly behaving controls where applicable.
5. Exercise **applicable operating modes and workflows** (tiers, permissions, offline, rotation/lifecycle when product supports them).
6. **Evidence retention:** screenshots on failure, execution logs, JUnit / Android Test XML, Gradle connected-test output, and product `.nivo78/evidence/` or `docs/evidence/` layout when N78-QA-001 applies.

**Prohibited for mandatory mobile gates:**

- Requiring ML Kit (or other OCR) for target identification or tap coordinates.
- Treating N78OcrResult v1 mobile pilot PASS as a substitute for native instrumented / XCUITest coverage.

## 3. iOS requirements

| Mechanism | Use |
| --------- | --- |
| **XCTest / XCUITest** | UI queries by accessibility identifier, label, and element type |
| **Screenshots** | `XCUIScreen` / attachment APIs in test failures |
| **Evidence** | `.xcresult` bundles exported or summarized under product evidence directories |

Same behavioral requirements as Android (rendered UI, native selectors, post-interaction verification, modes/workflows, failure evidence).

**Prohibited for mandatory mobile gates:** OCR-based interaction or requiring word-level OCR bounding boxes.

## 4. N78-TEST-001 layer mapping (mobile)

| Layer | Mobile expectation |
| ----- | ------------------ |
| **Layer 1 — Logic** | JVM / shared `commonTest` (unchanged) |
| **Layer 2 — Rendered UI** | Compose UI Test / Robolectric where applicable — **not** desktop `:desktop:visibleUiQa` |
| **Layer 3 — Device / runtime** | `connected*AndroidTest`, on-device iOS test targets — **native automation** |

## 5. Registry

`Common/N78-Family/reference/NIVO78_OCR_PLATFORM_APPLICABILITY.json` — fields:

- `desktopStage4Pilot` — desktop OCR only  
- `mobileNativeUiAutomation` — **REQUIRED** | **PLANNED** | **NOT_APPLICABLE**  
- `mobileOptionalOcrDiagnostic` — **OPTIONAL_DIAGNOSTIC** | **NOT_APPLICABLE** (never **REQUIRED**)

## 6. Phase 4B disposition reference

`Common/N78-Family/docs/evidence/ocr-first-standardization/phase4b/PHASE4B-MOBILE-ARCHITECTURE-REPORT.md`
