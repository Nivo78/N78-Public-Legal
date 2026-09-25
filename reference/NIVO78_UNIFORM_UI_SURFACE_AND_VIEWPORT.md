# Nivo78 Uniform UI Surface and Main Viewport (Mandatory)

**Rule ID:** `APP-UI-UNIFORM-SURFACE-VIEWPORT` **[GATE]**  
**Authority:** Canonical product standard (`NIVO78_APP_STANDARD.txt` v1.38+).  
**Primary projection:** `13-accessibility-i18n-performance.mdc`, `uniform-ui-surface-viewport.mdc`  
**Reference implementation (do not reinvent):** `N78-Estimate` — `AppUiScaling.vb`, `CompactMainViewportHost.vb`, `WorksheetHighDpiPolicy.vb`, `docs/UI_SCALING_SPEC.md`, shared `AppUiScaling.kt` / `WorksheetHighDpiPolicy.kt`.

---

## 1. Purpose

Dense Nivo78 **desktop workstation** apps (worksheets, grids, takeoff, quoting) must scale predictably on HiDPI displays **without reflow, hidden totals, or mystery margins** at scroll home. This document is the **single family contract** for that behavior. New products **port or share** this pattern — they do not design a one-off scroll or DPI scheme.

**Out of scope (different rules apply):** phone/tablet Compose shells (fluid layout, dp), web pages (`WEB-SEO-VIEWPORT`), products with an approved override (e.g. documented WinForms exceptions in N78-Frame).

---

## 2. Canonical design surface

| Constant | Value | Meaning |
| -------- | ----- | ------- |
| `BaseWidth` | **1920** | Logical application width at 100% |
| `BaseHeight` | **1080** | Logical application height at 100% |

At display scale 200% (device DPI **192**, scale **2.0**):

```text
SCALED_WIDTH  = 3840
SCALED_HEIGHT = 2160
```

One global scale factor drives **all** layout numbers (margins, fonts, control heights). No mixed “toolbar scale” and “worksheet scale” unless an approved override documents why.

---

## 3. Scaling math (mandatory)

1. **`ScaleFactor(deviceDpi) = deviceDpi / 96.0`** (minimum clamp as implemented in `AppUiScaling`).
2. **`ScaleLogical(baselinePx, deviceDpi) = round(baselinePx × ScaleFactor)`** — single API for integers; WinForms helpers (`ScalePx`, `ScaledPointSize`) must delegate here.
3. **`AutoScaleMode = None`** on WinForms main forms after PerMonitorV2 (or equivalent) is enabled **before** UI creation. Do not stack WinForms auto-DPI on top of logical scaling.
4. **No hardcoded 96-DPI layout** on interactive chrome (see `APP-A11Y-TEXT-SCALING`).

---

## 4. Layout model (mandatory)

1. **One logical layout** at the canonical surface — no separate “compact reflow” tree that drops columns or hides money fields.
2. **One primary main viewport** per top-level window showing a **window onto** the scaled surface (pan when the window is smaller than `SCALED_WIDTH` × `SCALED_HEIGHT`).
3. **Child panes** (worksheet, blueprint split) size to **pane client width**, not the full 3840 canvas width, unless the whole surface is intentionally scrolled as one unit. Prevents clip where inner panels cannot reveal content the outer scroll already owns.
4. **Row labels and controls** follow family row alignment (`row-text-vertical-alignment`).

---

## 5. Main viewport scroll (mandatory — WinForms)

**Do not** use `Panel.AutoScroll` / `ScrollableControl.AutoScroll` as the **primary** host for the full application surface. Family reference: **`CompactMainViewportHost`**.

| Requirement | Detail |
| ----------- | ------ |
| Explicit scrollbars | Dedicated `HScrollBar` / `VScrollBar`; content offset `Location = (-scrollX, -scrollY)`. |
| Scroll home | When both bars at minimum, **(0,0)** of the scaled surface is **flush** with the viewport **top-left** — no gray gutter from AutoScroll drift. |
| Wheel delta | Parse `WM_MOUSEWHEEL` high word as **signed** 16-bit (never `CShort` on unsigned 0xFFxx under Option Strict). |
| Inner hosts | Disable competing `AutoScroll` on nested hosts in compact mode; pin inner shells to `(0,0)` after layout. |
| Extents | `SetContentExtent(scaledW, scaledH)` ≥ measured content; minimum width/height at least `ScaledSurfaceWidth/Height` when product uses full canvas. |

---

## 6. Acceptance checklist (GATE evidence)

Before shipping a desktop build that uses this pattern:

- [ ] At **192 DPI** (200% Windows scale), full surface width/height match `AppUiScaling` (e.g. 3840×2160).
- [ ] Horizontal and vertical scrollbars appear when the window is smaller than the surface.
- [ ] Scroll bars at **minimum**: toolbar/content **left and top** align with the viewport — no large empty margin.
- [ ] Money/totals and grid **Total** column remain visible or reachable by horizontal pan (no pane-only clip).
- [ ] Mouse wheel and scrollbar drag do not crash (signed delta, clamped scroll values).
- [ ] Guardrail or unit tests cover scale round-trip and viewport scroll-home pinning (see N78-Estimate tests).

---

## 7. New products (N78Kit)

When stamping a **desktop-dense** utility:

1. Copy **`AppUiScaling`** (+ shared Kotlin mirror if KMP) and **`CompactMainViewportHost`** (or extract to `Common` when a second consumer exists).
2. Link this doc and `APP-UI-UNIFORM-SURFACE-VIEWPORT` in the product README / `reference/`.
3. Do **not** ship an alternate “simpler” AutoScroll panel for the main window.

---

## 8. Relationship to other rules

- **`APP-A11Y-TEXT-SCALING`** — general HiDPI and dynamic sizing; this rule **specializes** desktop fixed-surface + viewport behavior.
- **`APP-DESKTOP-MODERN-STYLE`** — toolbar chrome; surface/viewport rules apply **below** the family toolbar shell.

---

## 9. Changelog

| Date | Note |
| ---- | ---- |
| 2026-09-14 | Canonical spec from N78-Estimate compact viewport work (`CompactMainViewportHost`, scroll-home, wheel fix). |
