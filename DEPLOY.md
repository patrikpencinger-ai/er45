# Going live — er45.com (memorial) + archive.er45.com (archive)

Both sites are **static** (HTML + JSON + images), so hosting is simple and can be
free. The shape we need:

| Hostname | Serves | Document root |
|----------|--------|---------------|
| `er45.com` and `www.er45.com` | the **memorial** | repo root (`er45.html` as the index) |
| `archive.er45.com` | the **archive** | the `archive/` folder |

The cross-links already auto-switch: in production the memorial points at
`https://archive.er45.com/` and the archive's back-link at `https://er45.com/`;
on localhost they stay path-based. So nothing in the code needs to change to deploy.

Because the two hostnames serve **different folders**, the clean pattern is
**two static sites/projects from this one repo** — one rooted at the repo, one
rooted at `archive/`.

---

## Recommended: Cloudflare Pages (free, HTTPS, easy subdomains)

Prereq: er45.com using **Cloudflare nameservers** (Cloudflare → Add a site →
follow the nameserver change at your registrar). Then DNS + hosting are in one place.

**Site 1 — memorial (er45.com + www):**
1. Push this repo to GitHub/GitLab (see "Push the repo" below), or use *Direct Upload*.
2. Cloudflare → **Workers & Pages → Create → Pages →** connect the repo.
   - Build command: *(none)* · Build output directory: **`/`** (repo root).
3. Pages project → **Custom domains** → add `er45.com` **and** `www.er45.com`.
   Cloudflare creates the records and certs automatically.
4. Set the index: a Pages root serves `index.html` by default, but ours is
   `er45.html`. Either rename/copy it to `index.html`, or add a `_redirects`
   line (already provided below) so `/` serves the memorial.

**Site 2 — archive (archive.er45.com):**
1. Create a **second** Pages project from the same repo.
2. Build output directory: **`archive`**.
3. Custom domain → add `archive.er45.com`.

That's it — `archive/index.html` is the subdomain's index automatically.

> If you'd rather not move nameservers to Cloudflare: same two-project setup works
> on **Netlify** (set each site's *base/publish* dir to `/` and `archive`
> respectively, add the custom domains, and at your current DNS add the records
> Netlify shows — typically a CNAME for `www`/`archive` and an ALIAS/A for the apex).

---

## Alternative: your own server (the old site ran on IIS)

Serve two roots. **nginx:**

```nginx
server {                                   # memorial
  server_name er45.com www.er45.com;
  root /var/www/er45;                       # this repo
  index er45.html index.html;
  location / { try_files $uri $uri/ /er45.html; }
}
server {                                   # archive
  server_name archive.er45.com;
  root /var/www/er45/archive;               # the archive/ folder
  index index.html;
}
```

**IIS:** create two sites — bindings `er45.com`,`www.er45.com` → repo folder
(set Default Document to `er45.html`); binding `archive.er45.com` → the `archive`
subfolder. Add HTTPS via *Let's Encrypt (win-acme)*. The `.mdb`/ASP bits are NOT
needed — this is plain static content.

DNS for the own-server path (replace `<IP>` with the server's public IP):

```
er45.com.          A      <IP>
www.er45.com.      CNAME  er45.com.
archive.er45.com.  CNAME  er45.com.
```

---

## Push the repo (needed for the git-connected hosts)

```powershell
# create an empty repo on GitHub first (e.g. er45), then:
git remote add origin https://github.com/<you>/er45.git
git push -u origin main
```

## Cloudflare/Netlify root redirect (serve er45.html at /)

A `_redirects` file is included at the repo root:

```
/    /er45.html    200
```

This makes `/` serve the memorial without renaming the file. (Ignored by hosts
that don't use it; harmless.)
