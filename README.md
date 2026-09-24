# N78-Public-Legal

Public mirror of Nivo78 product **privacy** and **terms** HTML for continuity if nivo78.com is unavailable.

## Files

Each product uses flat names under `pages/`:

- `{App display name}.privacy.html`
- `{App display name}.terms.html`

Example: `pages/N78-Machining.privacy.html`

## Refresh from N78-Website

```powershell
pwsh -NoProfile -File tools/sync-from-n78-website.ps1
```

## GitHub Pages

Publish from branch `main`, folder `/` (root). Enable Pages in repo settings after push.
