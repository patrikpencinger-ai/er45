# ER45 — front page

The revived front page for **er45.com**, a Croatian techno/clubbing webzine
(~2002 era). The domain is being revived through subdomains; anyone who lands on
the bare `er45.com` root gets **one random scene out of four animated covers**.

> "The lights went out, but the bass remains."

## Files
- **`covers/`** — the four covers, each a self-contained animated scene with
  hidden easter eggs (no build step, no audio):
  - `pixel.html` — 01 *ER45: Club Quest* (16-bit pixel art)
  - `voxel.html` — 02 *ER45 Block Party* (three.js voxel club)
  - `diorama.html` — 03 *ER45 — 1:87 Scale* (tilt-shift model club)
  - `cartoon.html` — 04 *The Bass Remains* (1930s rubber-hose cartoon)
- **Front-page pick** — `worker.js` serves one of the four at `/` (no redirect,
  `Cache-Control: no-store`). It is random but never the same cover twice in a
  row (cookie `er45c` remembers the last one). `/?c=pixel|voxel|diorama|cartoon`
  (or `?c=1`–`4`) forces a specific cover. Old pages (`/rip`, `/dynamic`,
  `/er45-loop`, `/covers/`) redirect to `/`; direct `/covers/<name>` URLs work.
- **Dot menu** — top-right on every cover: four dots (01–04, each in its cover's
  accent colour, current one filled) switch scenes via `/?c=<name>`, plus an
  **ARCHIVE** link to `archiv.er45.com`.
- **`index.html`** — local-dev stand-in for the worker's pick (a static server has
  no worker): picks/validates `?c=` and redirects to `/covers/<name>.html`.
- **`favicon.svg`** — pixel **ER / 45** tile.

## archive.er45.com — the first real subdomain
The front page's tagline ("the infrastructure continues in the subdomains") is now
literally true: **`archive/`** is a self-contained static site reconstructed from
the original `er45` database.

- **`archive/index.html`** — searchable app with three views:
  - **Chronology** — the full party calendar (3,246 parties, 1991–2003), venues
    resolved, filterable by year and free-text search.
  - **Articles** — 144 DJ interviews / artist bios / reports, by category, click to read.
  - **Flyers** — 57 original event flyers (thumbnailed into `archive/assets/flyers/`).
- **`archive/data/*.json`** — the data it runs on (copied from `data/`).
- Linked from the ARCHIVE button on every cover; locally it lives at `/archive/`.

## Decoded source data (`data/` + lists)
Extracted from the original MySQL `er45` dump (Windows-1250) and the Access stores:
- **`PARTIES.md`** / **`data/parties.json`** — the party chronology (3,246 events).
- **`ARTICLES.md`** / **`data/articles.json`** — the article index (144 articles).
- **`data/locations.json`** — the 510-venue lookup.
- **`ARCHIVE.md`** — narrative analysis of the whole original-site backup.

Croatian diacritics were double-mangled in the source (č→è, ć→æ) and are
reversed during extraction — see `tools/parse-db.ps1`.

### Tools (`tools/`, all PowerShell, no deps)
- **`parse-db.ps1`** — parse the SQL/Access sources → `data/*.json`.
- **`build-markdown.ps1`** — render the readable `PARTIES.md` / `ARTICLES.md`.
- **`build-flyers.ps1`** — thumbnail the original flyers + emit `archive/flyers.json`.
- **`serve-2003.ps1`** — resurrect the **original 2003 site** locally: serves the
  static snapshot from `_backup\`, inlining ASP includes so the original page
  chrome renders (no live DB). Open `http://127.0.0.1:8201/`.

## Local preview
From this folder, start the static server and open the page:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .claude/serve.ps1
# front page: http://127.0.0.1:8200/   (random cover; /?c=voxel forces one)
# archive:   http://127.0.0.1:8200/archive/
```

(Port 8200 — chosen so it never clashes with the daily-dashboard server on 8100.)

## Deploy (Cloudflare)
**One** static-asset Worker (`er45`) serves both sites, routed by hostname in
`worker.js` (see **`DEPLOY.md`**):
- `er45.com` + `www.er45.com` → the front page: a random one of the four covers (`covers/`).
- `archiv.er45.com` → the archive (rewritten onto the `archive/` subtree).

All three are custom domains on the one worker; `git push` redeploys.

## Notes
- This project is **independent** of `daily-dashboard`; they only ever shared a
  parent folder by accident.
- Source material (original-site archive: photos, articles, forum, databases)
  lives separately at `C:\Users\patri\OneDrive\Backup\ER45` and is **not** part
  of this repo.
