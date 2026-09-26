# Nivo78 Git branching

> **Canonical (edit there):** `Desktop\Nivo78\N78-Ops\docs\GIT_BRANCHING.md`  
> Regenerate this mirror: `N78-Ops\tools\maintain\sync-git-branching-doc.ps1`
> **This repo:** `N78-Public-Legal` — work on **main** (current line); use **2**, **3**, … only for the next product generation.

# Nivo78 Git branching (all product repos)

> **Canonical:** `N78-Ops/docs/GIT_BRANCHING.md`  
> **Mirrors:** run `tools/maintain/sync-git-branching-doc.ps1` to refresh `docs/GIT_BRANCHING.md` in every local Nivo78 repo.

**Effective:** 2026-09-26

## Policy

| Branch | Meaning |
| ------ | ------- |
| **`main`** | **Current product line** — live in the store, **release-candidate**, or **pre-release** (first launch still on `main`). Hotfixes and day-to-day shipping prep merge here. |
| **`v2`, `v3`, …** | **Next major generations** — parallel or follow-on lines. Merge into **`main`** when that generation becomes the current line. |

- **GitHub `default_branch`** must be **`main`** for every `Nivo78/*` repo.
- **Legacy names** (`master`, `development`, `Development`, `release`, `ios-release`, **`V2`** on Windows) — do not use for new work; see table below.
- **Product generation** (app v1, v2) is in `docs/ROADMAP.md` where applicable; git **`main`** is not “store-only.”

## Workflow

1. **Current line:** branch from **`main`** → merge → **`main`** → build / ship from **`main`**.
2. **Next generation:** branch from **`v2`** (or `v3`) → merge there → at cutover, merge **`v2` → `main`** and tag.
3. **`main` = the line you own today** — whether or not it is in the store yet.

## Family repo map (local `Desktop\Nivo78`)

| Repo | **`main`** | **`v2`+** | Legacy (retired for new work) |
| ---- | ---------- | --------- | ----------------------------- |
| **N78-Ops** | Ops v1 (Play) | **`v2`** — quote ingest, air-gap | `release`, `development` |
| **N78-Estimate** | MSIX / desktop v1 | **`v2`** — Ops handoff, utility paste | `Development` |
| **N78-Electrical** | v1 (pre-release Store OK) | *(none until gen 2)* | — |
| **N78-Machining** | v1 line | **`v2`** on GitHub (local branch may show **`V2`** on Windows) | — |
| **N78-APA** | current line | as needed | — |
| **N78-Frame** | current line | as needed | `development` (behind `main`) |
| **N78-Life** | current line | as needed | `development`, `ios-release` |
| **N78-Track** | current line | as needed | `development` (merged into `main` 2026-09-26) |
| **N78-Dash**, **N78-Book**, **N78-Probe**, **N78-StlLite**, **N78-Public-Legal**, **N78-Website** | current line | as needed | `master` → use **`main`** |
| **N78-QRTest** | QR experiments | as needed | `master` → **`main`** |
| **N78-Kit**, **N78-Template**, **N78-Successor**, **N78-Standards** | family infra | as needed | `master` → **`main`** (Standards) |

## Legacy branch quick reference

| Legacy | Use instead |
| ------ | ----------- |
| `master` | **`main`** (same commit; `master` may remain on remote until deleted) |
| `release` (Ops) | **`main`** |
| `development` / `Development` | **`main`** (current line) or **`v2`** (next gen) |
| `ios-release` (Life) | **`main`** |
| `V2` (Machining, Windows) | **`v2`** on GitHub; prefer checking out **`main`** for v1 work |

## Maintenance

```powershell
# Refresh mirrors after editing this file:
pwsh -NoProfile -File C:\Users\Mike\Desktop\Nivo78\N78-Ops\tools\maintain\sync-git-branching-doc.ps1
```

New repos from **N78-Kit** should start with **`main`** only; add **`v2`** when a second product generation needs a long-lived branch.

