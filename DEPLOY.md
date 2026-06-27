# Going live on Cloudflare — er45.com (memorial) + archiv.er45.com (archive)

Both sites are **static** (HTML + JSON + images) and are served by **one**
Cloudflare static-asset Worker (`er45`), routed by hostname in `worker.js`:

| Hostname | Serves |
|----------|--------|
| `er45.com` + `www.er45.com` | the memorial (`index.html`) |
| `archiv.er45.com` | the archive — `worker.js` rewrites it onto the `/archive/` subtree |

`run_worker_first = true` (in `wrangler.toml`) lets the script run before static
assets are matched, so it can map `archiv.er45.com/<path>` → `/archive/<path>`.
The cross-links also auto-switch in production; on localhost they stay path-based.

Repo: **github.com/patrikpencinger-ai/er45** (`main`).

---

## Setup (mostly done)

**1. The worker** — already deployed as `er45`, live at
`er45.patrik-pencinger.workers.dev`.

**2. Custom domains** — on the `er45` worker → **Settings → Domains** →
**Add Domain**, add all three (these are already added):
`er45.com`, `www.er45.com`, `archiv.er45.com`.

> Apex/`www` first needed the old IONOS `A` records (→ 216.250.121.143) deleted
> from the er45.com DNS zone so Cloudflare could create the Worker records. The
> `MX` (Google Workspace email) and other subdomain records were left untouched.

**3. Redeploy after the `worker.js` change** — the host-routing script + the
`wrangler.toml` `[assets]` `run_worker_first/binding` change must be deployed:
- If the worker is connected to the GitHub repo (Workers Builds), a `git push`
  to `main` redeploys automatically.
- Otherwise deploy from the terminal:

  ```powershell
  npm i -g wrangler     # once
  wrangler login        # once, opens browser
  wrangler deploy       # from the repo root
  ```

After it deploys: `https://er45.com` and `https://www.er45.com` show the memorial;
`https://archiv.er45.com` shows the archive.

---

## Fallback: your own server
Two roots, **nginx:**

```nginx
server { server_name er45.com www.er45.com; root /var/www/er45;        index index.html; }
server { server_name archiv.er45.com;        root /var/www/er45/archive; index index.html; }
```
(No Worker script needed here — each vhost points straight at its folder.)
