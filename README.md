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

## Local preview
From this folder, start the static server and open the page:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .claude/serve.ps1
# then browse to http://127.0.0.1:8200/
```

(Port 8200 — chosen so it never clashes with the daily-dashboard server on 8100.)

## Notes
- This project is **independent** of `daily-dashboard`; they only ever shared a
  parent folder by accident.
- Source material (original-site archive: photos, articles, forum, databases)
  lives separately at `C:\Users\patri\OneDrive\Backup\ER45` and is **not** part
  of this repo.
