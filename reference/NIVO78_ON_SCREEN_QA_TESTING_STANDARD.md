# NIVO78 FAMILY QA TESTING STANDARD
## Document ID: NIVO78-QA-STD-2026-V1.53
## Classification: Architecture Governance & Universal Testing Standard
## Target: Universal Nivo78 Mobile, Desktop, and KMP Codebases

Canonical companion: `reference/NIVO78_FAMILY_QA_TESTING_STANDARD.txt` (full lanes, ALL-RESULTS, vault matrix).

---

## 1. Governance Rules (Rules 160–162)

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
  4. Watchable On-Screen Exploration (`:desktop:visibleUiQa` when visual desktop shell exists).
  5. Native Host Subsystem Tests (e.g., `dotnet test` for WinForms or platform-specific CLI harnesses).
  6. Text Scenario Orchestrator (`tools/text-tests/run-text-scenarios.ps1`).

### RULE 162: APP-TEST-VAULT-BACKUP-QA
Every application must implement deterministic verification of its security boundary and data persistence lifecycle:
* Security / Passcode / Vault:
  - If a Master Passcode or Encrypted Vault exists: Automated tests must assert empty input rejection, invalid passcode locking/throttling, and valid passcode unlock.
  - If an Approved "No-Vault Override" is active: Automated tests must verify the legal/privacy gate ("accept only when confirmed") and assert the complete absence of vault chrome, prompts, or unauthorized lock screens.
* Backup & Restore Verification:
  - Automated engine tests must execute full in-memory serialization round-trips and file export/import parity checks.
  - UI tests must verify the on-screen display of restored data fields.

---

## 2. On-Screen Exhaustive Interaction Specification (§ 3d)

### 2.1 Interaction Requirements
Superficial slideshows or non-interactive step-throughs are strictly prohibited. When `:desktop:visibleUiQa` runs, the automation agent must explore every visible interactive component:

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
* Implementation: Use `runDesktopComposeUiTest` (Compose Desktop) or the product's native visible shell (WinForms exe harness).
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

### 2.4 Unified Consolidation (single-file law)
* Each visible interaction assertion emits a discrete pass/fail record.
* ALL lanes compile into `Desktop\Results\N78-{Product}\ALL-RESULTS.html`.
* ONE master table lists every individual test/scenario row with lane, class, name, time, PASS/FAIL.

---

## 3. Product Evidence
* `docs/QA_RELEASE_SUITE.md` — lane order and override notes.
* `docs/GATE_EVIDENCE_MAP.md` — verifier paths.
* Cursor projection: `.cursor/rules/11-testing-quality.mdc` § 11.4.
