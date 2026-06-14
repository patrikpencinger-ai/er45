# ER45 — memorial site

A dynamic, interactive memorial for **er45.com**, a Croatian techno/clubbing
webzine (~2002 era). The domain is being revived through subdomains; anyone who
lands on the bare `er45.com` root gets this memorial.

> "The lights went out, but the bass remains."

## Files
- **`er45.html`** — the whole thing, self-contained (no build step):
  - Pixel-art club scene rendered into a low-res canvas buffer (turntables,
    mixer, speaker stack with beat-punching woofers, moving-head lights, disco
    ball, fog, heartbeat lines).
  - **Music**: the real *DJ Rolando — Knights of the Jaguar (beatless edit)* via
    a SoundCloud embed; a self-contained Web-Audio synth (no kick) is the fallback.
    Swap the track via the `TRACK` constant near the top of the script.
  - **Interactive**: "Pay Respects" raises a neon **glowstick** (count persisted
    in `localStorage`); mute + fullscreen controls.
- **`favicon.svg`** — pixel **ER / 45** tile.

## archive.er45.com — the first real subdomain
The memorial's tagline ("the infrastructure continues in the subdomains") is now
literally true: **`archive/`** is a self-contained static site reconstructed from
the original `er45` database.

- **`archive/index.html`** — searchable app with three views:
  - **Chronology** — the full party calendar (3,246 parties, 1991–2003), venues
    resolved, filterable by year and free-text search.
  - **Articles** — 144 DJ interviews / artist bios / reports, by category, click to read.
  - **Flyers** — 57 original event flyers (thumbnailed into `archive/assets/flyers/`).
- **`archive/data/*.json`** — the data it runs on (copied from `data/`).
- Linked from the memorial dock; locally it lives at `/archive/`.

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
# memorial:  http://127.0.0.1:8200/
# archive:   http://127.0.0.1:8200/archive/
```

(Port 8200 — chosen so it never clashes with the daily-dashboard server on 8100.)

## Notes
- This project is **independent** of `daily-dashboard`; they only ever shared a
  parent folder by accident.
- Source material (original-site archive: photos, articles, forum, databases)
  lives separately at `C:\Users\patri\OneDrive\Backup\ER45` and is **not** part
  of this repo.
