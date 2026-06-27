# Going live on Cloudflare — er45.com (memorial) + archive.er45.com (archive)

Both sites are **static** (HTML + JSON + images), deployed the same way as the
other projects: a Cloudflare **static-asset Worker** per site, built from the
GitHub repo. The shape:

| Hostname | Project | Project root | wrangler.toml | Serves |
|----------|---------|--------------|---------------|--------|
| `er45.com` + `www.er45.com` | **er45** | `/` (repo root) | `wrangler.toml` | the memorial (`index.html`) |
| `archive.er45.com` | **er45-archive** | `archive` | `archive/wrangler.toml` | the archive (`archive/index.html`) |

The cross-links auto-switch in production (memorial → `archive.er45.com`, archive
back-link → `er45.com`); on localhost they stay path-based. Nothing in the code
changes to deploy.

The repo is pushed to **github.com/patrikpencinger-ai/er45** (`main`).

---

## One-time setup in the Cloudflare dashboard

### Project 1 — the memorial (er45.com + www)
1. **Workers & Pages → Create → Workers → Import a repository →** pick
   `patrikpencinger-ai/er45`.
2. Leave the **root directory** as `/`. It picks up `wrangler.toml`
   (`name = "er45"`, `[assets] directory = "./"`). No build command.
3. Deploy. Then **Settings → Domains & Routes → Add → Custom domain** and add
   **both** `er45.com` and `www.er45.com`. Cloudflare adds the DNS records and
   the TLS cert automatically (er45.com is already on Cloudflare).

### Project 2 — the archive (archive.er45.com)
1. **Create → Workers → Import a repository →** pick the **same** repo
   `patrikpencinger-ai/er45` again.
2. Set the **root directory** to **`archive`** so it uses `archive/wrangler.toml`
   (`name = "er45-archive"`). No build command.
3. Deploy, then add the custom domain **`archive.er45.com`**.

That's it — pushing to `main` redeploys both projects.

> If the Cloudflare GitHub app uses "only selected repos", grant it access to the
> new `er45` repo first (GitHub → Settings → Applications → Cloudflare → repo access).

---

## CLI alternative (wrangler)
If you'd rather deploy from the terminal instead of the dashboard:

```powershell
npm i -g wrangler        # if not installed
wrangler login           # opens browser, authorises your Cloudflare account
wrangler deploy                       # from repo root  -> project "er45"
wrangler deploy -c archive/wrangler.toml   # -> project "er45-archive"
```
Custom domains still get attached once in the dashboard (or via
`wrangler deployments domains`), as above.

---

## Fallback: your own server (the old site ran on IIS)
Serve two roots — **nginx:**

```nginx
server { server_name er45.com www.er45.com; root /var/www/er45;        index index.html; }
server { server_name archive.er45.com;       root /var/www/er45/archive; index index.html; }
```

**IIS:** two sites — `er45.com`/`www` → repo folder; `archive.er45.com` → the
`archive` subfolder. HTTPS via win-acme. All plain static content (no ASP/.mdb).
