/* Offline shell. Same-origin GETs are cached; Supabase and any CDN call goes
   straight to the network so nothing stale is ever served for live data. */
const CACHE = 'sat-practice-v1';
const SHELL = [
  './', './index.html', './manifest.webmanifest',
  './vendor/pdf.min.js', './vendor/pdf.worker.min.js',
  './icons/icon-180.png', './icons/icon-192.png',
  './icons/icon-512.png', './icons/icon-512-maskable.png',
  './icons/favicon-32.png', './icons/favicon-16.png'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => Promise.allSettled(SHELL.map(u => c.add(u))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;

  // The page itself: fresh when possible, cached copy when offline.
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then(r => { const c = r.clone(); caches.open(CACHE).then(x => x.put('./index.html', c)); return r; })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }

  e.respondWith(
    caches.match(req).then(hit => hit || fetch(req).then(r => {
      if (r.ok) { const c = r.clone(); caches.open(CACHE).then(x => x.put(req, c)); }
      return r;
    }))
  );
});
