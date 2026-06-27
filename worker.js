// ER45 — one Worker, two sites, routed by hostname.
//   archiv.er45.com           -> the archive (the /archive/ folder)
//   er45.com / www.er45.com   -> the memorial (repo root)
// Static assets are bound as env.ASSETS; run_worker_first lets this run on every
// request so we can rewrite the archive subdomain onto the /archive/ subtree.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.hostname === 'archiv.er45.com' && !url.pathname.startsWith('/archive/')) {
      url.pathname = '/archive' + (url.pathname === '/' ? '/' : url.pathname);
      return env.ASSETS.fetch(new Request(url, request));
    }
    return env.ASSETS.fetch(request);
  }
};
