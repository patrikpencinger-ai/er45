// ER45 — one Worker, two sites, routed by hostname.
//   archiv.er45.com           -> the archive (the /archive/ folder)
//   er45.com / www.er45.com   -> the front page: ONE RANDOM of the four covers
//                                (covers/pixel|voxel|diorama|cartoon.html)
// Static assets are bound as env.ASSETS; run_worker_first lets this run on every
// request so we can (a) rewrite the archive subdomain onto the /archive/ subtree
// and (b) pick a cover for "/" without a redirect (the address bar stays er45.com).
//
// Front page ("/" and "/index.html"):
//   ?c=pixel|voxel|diorama|cartoon (or 1-4) forces a cover (used by the dot menu);
//   otherwise random, never the same cover twice in a row (cookie er45c = last shown).
// Retired pages (old memorial, dynamic, loop, cover chooser) 302 to "/".
// Direct /covers/<name> URLs keep working.
const COVERS = ['pixel', 'voxel', 'diorama', 'cartoon'];

const RETIRED = new Set([
  '/rip', '/rip.html', '/dynamic', '/dynamic.html', '/er45-loop', '/er45-loop.html',
  '/covers', '/covers/', '/covers/index', '/covers/index.html'
]);

function readCookie(request, name) {
  const header = request.headers.get('Cookie') || '';
  for (const part of header.split(';')) {
    const i = part.indexOf('=');
    if (i > 0 && part.slice(0, i).trim() === name) return part.slice(i + 1).trim();
  }
  return '';
}

function pickCover(url, request) {
  const q = (url.searchParams.get('c') || '').trim().toLowerCase();
  if (COVERS.includes(q)) return q;
  if (/^[1-4]$/.test(q)) return COVERS[Number(q) - 1];
  const last = readCookie(request, 'er45c');
  const pool = COVERS.filter(n => n !== last); // unknown/empty cookie leaves all four
  return pool[Math.floor(Math.random() * pool.length)];
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.hostname === 'archiv.er45.com' && !url.pathname.startsWith('/archive/')) {
      url.pathname = '/archive' + (url.pathname === '/' ? '/' : url.pathname);
      return env.ASSETS.fetch(new Request(url, request));
    }

    if (RETIRED.has(url.pathname)) {
      return Response.redirect(new URL('/', url).toString(), 302);
    }

    if ((url.pathname === '/' || url.pathname === '/index.html') &&
        (request.method === 'GET' || request.method === 'HEAD')) {
      const name = pickCover(url, request);
      // Extensionless: Cloudflare serves /covers/x.html at /covers/x (and 307s the .html form).
      const res = await env.ASSETS.fetch(new Request(new URL('/covers/' + name, url), request));
      if (res.status !== 200) return res;
      const headers = new Headers();
      headers.set('Content-Type', 'text/html; charset=utf-8');
      headers.set('Cache-Control', 'no-store');
      headers.set('Set-Cookie', 'er45c=' + name + '; Path=/; Max-Age=31536000; SameSite=Lax');
      return new Response(res.body, { status: 200, headers });
    }

    return env.ASSETS.fetch(request);
  }
};
