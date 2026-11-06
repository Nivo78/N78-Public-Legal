# NIVO78 FAMILY QA TESTING STANDARD
## Document ID: NIVO78-QA-STD-2026-V1.54
## Classification: Architecture Governance & Universal Testing Standard
## Target: Universal Nivo78 Mobile, Desktop, and KMP Codebases

Canonical companion: `reference/NIVO78_FAMILY_QA_TESTING_STANDARD.txt` (full lanes, ALL-RESULTS, vault matrix).

---

## 1. Governance Rules (Rules 160–163)

### RULE 160: APP-TEST-TEXT-ORCHESTRATOR
Every application repository must provide a dedicated, standalone text-based scenario orchestrator:
* Path: `tools/text-tests/run-text-scenarios.ps1` (with optional `run-all-text-tests.ps1`).
* Purpose: Execute product-specific CLI flows, data serialization, calculation baselines, and format transformations without starting a GUI.
* Product-Specific Tuning: Generic stubs are prohibited. Scenarios must reflect real operator inputs, units, calculations, and domain limits.
* Execution Output: Emit timestamped JSON or NDJSON run logs capturing per-scenario success/failure status and timing.

### RULE 161: APP-TEST-RELEASE-QA-SUITE
Every application repository must provide an integrated, multi-lane automated release test pipeline:
* Master Pipeline Script: `tools/maintain/run-{product}-qa-suite.ps1`.
* Standard Launchers:
  - `tools/launchers/N78-{Product}-QA-Suite.bat` (Headless full regression).
  - `tools/launchers/N78-{Product}-QA-Suite-Visible.bat` (Watchable on-screen UI preview).
* Desktop App Twins:
  - `Desktop/Apps/N78-{Product}/N78-{Product}-QA-Suite.bat`
  - `Desktop/Apps/N78-{Product}/N78-{Product}-QA-Suite-Visible.bat`
* Required Execution Lanes:
  1. Static Guardrails / Source Linting (`run-{product}-guardrails.ps1`).
  2. KMP Shared Engine Tests (`:shared:desktopTest`).
  3. Headless UI Regression (`:desktop:desktopTest`).
  4. Watchable On-Screen Exploration (`:desktop:visibleUiQa` for Compose; `:winforms:visibleUiQa` for WinForms-primary).
  5. Native Host Subsystem Tests (headless `dotnet test` excluding `Category=WinFormsVisibleUiQa`).
  6. Text Scenario Orchestrator (`tools/text-tests/run-text-scenarios.ps1`).

### RULE 162: APP-TEST-VAULT-BACKUP-QA
Every application must implement deterministic verification of its security boundary and data persistence lifecycle:
* Security / Passcode / Vault:
  - If a Master Passcode or Encrypted Vault exists: Automated tests must assert empty input rejection, invalid passcode locking/throttling, and valid passcode unlock.
  - If an Approved "No-Vault Override" is active: Automated tests must verify the legal/privacy gate ("accept only when confirmed") and assert the complete absence of vault chrome, prompts, or unauthorized lock screens.
* Backup & Restore Verification:
  - Automated engine tests must execute full in-memory serialization round-trips and file export/import parity checks.
  - UI tests must verify the on-screen display of restored data fields.

### RULE 163: APP-TEST-WINFORMS-ON-DEVICE-UI
WinForms-primary desktop products MUST ship maximum on-device UI automation (family standard §3f):
* `tools/verify/run-{product}-winforms-visible-ui-qa.ps1` invoked from the on-device QA lane.
* xUnit trait `Category=WinFormsVisibleUiQa` on STA tests that **Show** the shipping MainForm (Opacity=1).
* Granular JSON → `Desktop\Results\N78-{Product}\winforms-visible-ui-qa\LATEST-results.json` merged into ALL-RESULTS.html.
* Minimum catalog: main menus, command bar, primary modes, transforms, sliders/readouts, Help hub, tier menus, legal QA prep.
* Reference: N78-Estimate `EstimateWinFormsDeviceQaTests`; N78-Frame `FrameWinFormsDeviceQaTests`.

---

## 2. On-Screen Exhaustive Interaction Specification (§ 3d–3f)

### 2.1 Interaction Requirements
Superficial slideshows or non-interactive step-throughs are strictly prohibited. When `:desktop:visibleUiQa` or `:winforms:visibleUiQa` runs, the automation agent must explore every visible interactive component on the **rendered** shell:

1. **Text Fields and Input Boxes:**
   * Focus the input field.
   * Type synthetic valid input.
   * Select All (`Ctrl+A`), Copy to clipboard buffer.
   * Clear (`Backspace` or `Delete`) and assert empty-state handling or validation triggers.
   * Paste back from buffer or enter canonical verified value.
   * Shift focus to trigger commit/blur listeners.

2. **Buttons, Menus, and Actions:**
   * Click/tap all primary, secondary, and utility buttons.
   * Open and navigate all top menu strips (File, Edit, View, Settings, Help) — in-compose menu strip and/or native OS menu when the visible host mounts production chrome.
   * For destructive actions (Clear, Reset, Delete): Exercise the confirmation dialog by triggering the cancel/dismiss path first, then testing actual execution where non-destructive to test isolation.

3. **Toggles, Checkboxes, and Steppers:**
   * Cycle states: Checked -> Unchecked -> Checked.
   * Cycle every tab, segmented control, drawer, and drop-down menu.

### 2.2 Visual Execution and Human Observability
* Host Window: `:desktop:visibleUiQa` must run within a **visible, bordered desktop window frame** on the operator's primary display. Headless off-screen harnesses (`runSkikoComposeUiTest` without a physical window) are strictly reserved for `:desktop:desktopTest`.
* Implementation: Use `runDesktopComposeUiTest` (Compose Desktop) or WinForms `Show()` harness with `Category=WinFormsVisibleUiQa` (not headless-only dotnet for on-device proof).
* Visual Step HUD: A blue informational banner must sit at the top of the viewport indicating the active step, target component, and intended assertion.
* Pacing Clamps: An intentional pacing delay of **50ms to 150ms** (default: **100ms**) must be injected between discrete interaction steps so human operators can visibly observe field mutations, focus switches, and layout transitions.

### 2.3 Semantics Node Resolution & Selector Hygiene
To prevent test crashes and node ambiguity in Compose Desktop:
* Strict Rule: Never perform unanchored, broad substring text matches (`substring = true`) for common action labels (e.g., `"Accept"`, `"Cancel"`, `"OK"`, `"Settings"`, `"Close"`, `"Back"`).
* Selector Enforcement: Target components by compounding exact text matching with semantic role or dedicated test tags:
  ```kotlin
  // REQUIRED: Combine exact text with explicit Role
  onNode(hasText("Accept", substring = false).and(hasRole(Role.Button)))

  // REQUIRED: Use explicit test tags when available
  onNodeWithTag("btn_accept_legal_gate")
  ```
* Readout / domain labels (e.g. `"Customer"`, status strings) may use exact or anchored matchers; prefer `testTag` on chrome controls first.

### 2.5 Desktop page layout visibility (APP-TEST-DESKTOP-PAGE-LAYOUT)
Every desktop product MUST automate a **full page sweep** before release:

1. **Open and display every page** in the product page catalog (all module tabs plus Help, Feedback, and settings surfaces the operator can reach from the main shell).
2. **After each page is shown** and layout is idle, run layout integrity probes that fail on:
   - **Cut off / clipped** primary chrome or readouts whose center is still in the viewport.
   - **Truncated** primary chrome labels (ellipsis on tabs, buttons, or switches).
   - **Overlapping** interactive controls (buttons, tabs, checkboxes) beyond family tolerance.
3. **Implementation:** Compose Desktop products call `N78FamilyDesktopPageLayoutQa.assertPageLayoutIntegrity` from `openModuleTab` / `displayEveryPageLayoutSweep` in the CombinedReleaseQaTest runner and `:shared:visibleUiQa` (or `:desktop:visibleUiQa`). WinForms products document the equivalent dotnet sweep in `docs/QA_RELEASE_SUITE.md`.
4. **Results:** Each page probe is a discrete pass/fail row in ALL-RESULTS.html when the visible lane emits granular JSON.

### 2.6 WinForms maximum on-device lane (`:winforms:visibleUiQa`, § 3f)
* Headless release gate MUST NOT be the only dotnet pass — exclude `WinFormsVisibleUiQa` from verify-tests and run the dedicated winforms-visible script in on-device QA.
* Text-test segment markers (01–07) remain mandatory manual/Agent depth; they do not satisfy § 3f.
* Each `Record(name, action)` from the WinForms reporter is one ALL-RESULTS row under lane `:winforms:visibleUiQa`.

### 2.7 OCR-first installed targeting — **Windows desktop only** (§ 3g — **FAMILY-N78-OCR-FIRST-UI-TARGETING**)

**Rule IDs:** **FAMILY-N78-OCR-FIRST-UI-TARGETING** [GATE], **APP-TEST-OCR-ENGINE-SELFTEST** [STATIC], **APP-TEST-OCR-INSTALLED-PILOT** [GATE], **FAMILY-OCR-TARGETING-EXCEPTIONS** [STATIC].

For **installed** or **production-faithful on-device** UI automation on **Windows desktop** (`.exe`, shown WinForms main form, Compose Desktop installed window), **OCR is the primary targeting mechanism** for selecting on-screen UI items. Compose `:desktop:visibleUiQa` semantics remain required for Layer 2 breadth in the JVM test host but **do not alone** satisfy § 3g.

**Mobile Android and iOS are out of scope for § 3g.** They use **native platform automation** per § 2.8 and `NIVO78_MOBILE_NATIVE_UI_AUTOMATION_STANDARD.md`. Do not require ML Kit OCR, OCR bounding boxes, or OCR-based tapping on mobile release gates.

**Mandatory behavior:**

1. **Native-resolution screenshots** of the target application window (or documented device frame buffer via platform adapter).
2. **OCR word bounding boxes** using the family **N78OcrResult schema v1** (`Common/N78-Family/tools/verify/invoke-windows-ocr.ps1`).
3. **Verified bounding-box targeting** — pointer actions derive from matched word boxes (or registered exception alternative).
4. **Post-interaction OCR verification** — re-capture and assert expected text/state after each critical action.
5. **Evidence retention** — PNG + OCR JSON + machine report under `docs/evidence/ocr-automation/` or `.nivo78/evidence/`.
6. **BLOCKED** when targets are missing or ambiguous (`Select-N78OcrTargetUnique`); never silently pick among duplicates.
7. **No unregistered coordinate guessing** — raw screen clicks without prior OCR match and audit log are prohibited in installed pilots.
8. **Exceptions only** via `Common/N78-Family/reference/NIVO78_OCR_TARGETING_EXCEPTIONS.json` (owner, rationale, review_by, compensating_control).

**Shared library:** `Common/N78-Family/tools/lib/N78WindowsUiOcr.ps1` (product shims under `{Product}/tools/lib/`).

**Verification:** `Common/N78-Family/tools/verify/verify-n78-ocr-first-family.ps1` + product **APP-TEST-OCR-INSTALLED-PILOT** evidence (executed stage-4-style report with `overall: PASS`) **where desktop Stage-4 is REQUIRED** per `NIVO78_OCR_PLATFORM_APPLICABILITY.json`. Library presence alone is **not** compliance.

**Platform applicability (Phase 2c+):**

| Application | Primary platform | Desktop Stage-4 (`APP-TEST-OCR-INSTALLED-PILOT`) |
| ----------- | ---------------- | ------------------------------------------------- |
| N78-Color | Desktop | **REQUIRED** — `overall: PASS` evidence |
| N78-Electrical | Desktop | **REQUIRED** |
| N78-Estimate | Desktop | **REQUIRED** |
| N78-Machining | Desktop | **REQUIRED** |
| N78-Ops | **Mobile (Google Play)** | **NOT APPLICABLE** — do not require desktop Stage-4 PASS; mobile compliance is **native instrumented / XCUITest** (§ 2.8) |

**Status semantics:** **NOT APPLICABLE** is mutually exclusive from **PASS**, **FAIL**, and **BLOCKED**. Family-wide desktop OCR closure PASS requires every **REQUIRED** desktop application to have executed Stage-4 **PASS** evidence; **NOT APPLICABLE** products must not be silently omitted from the applicability registry.

**Display scaling (Stage-4 §4D):** **S4D-SCALE-150** and **S4D-SCALE-200** remain **outstanding** until executed on each applicable desktop product at that scale; pilot **BLOCKED** / **NOT VERIFIED** rows must **not** be reported as PASS.

**Registry:** `Common/N78-Family/reference/NIVO78_OCR_PLATFORM_APPLICABILITY.json`

**Phase 4B correction:** Phase 4A experimental **mobile OCR adapter** code (N78-Ops `androidTest`) is **optional diagnostic tooling only** — not mandatory mobile architecture. See Phase 4B report under `phase4b/`.

### 2.8 Native mobile UI automation (§ 3h — **FAMILY-N78-MOBILE-NATIVE-UI-AUTOMATION**)

**Canonical:** `Common/N78-Family/reference/NIVO78_MOBILE_NATIVE_UI_AUTOMATION_STANDARD.md`

**Android:** instrumented tests, UI Automator, Espresso / Compose UI Test, accessibility semantics and stable identifiers, native screenshots, post-interaction state verification, connected-test and failure evidence.

**iOS:** XCTest / XCUITest, accessibility identifiers and labels, native screenshots, `.xcresult` retention, equivalent workflow coverage.

**Verification:** Product release QA suites and N78-QA-001 enforcement matrix (where adopted) — executed device/simulator evidence. **Not** `verify-n78-ocr-first-family.ps1` Stage-4 mobile OCR.

**Registry:** `mobileNativeUiAutomation` and `mobileOptionalOcrDiagnostic` in `NIVO78_OCR_PLATFORM_APPLICABILITY.json`.

### 2.4 Unified Consolidation (single-file law)
* Each visible interaction assertion emits a discrete pass/fail record.
* ALL lanes compile into `Desktop\Results\N78-{Product}\ALL-RESULTS.html`.
* ONE master table lists every individual test/scenario row with lane, class, name, time, PASS/FAIL.

---

## 3. Product Evidence
* `docs/QA_RELEASE_SUITE.md` — lane order and override notes.
* `docs/GATE_EVIDENCE_MAP.md` — verifier paths.
* Cursor projection: `.cursor/rules/11-testing-quality.mdc` § 11.4.
