/* Sehari Selembar service worker: works offline, refreshes in the background. */
const CACHE = 'sehari-v4';
const FONTS = ['HTx3L3I-JCGChYJ8VI-L6OO_au7B2xY', 'HTxwL3I-JCGChYJ8VI-L6OO_au7B4-Lw_3E', 'HTxwL3I-JCGChYJ8VI-L6OO_au7B4873_3E', 'HTxwL3I-JCGChYJ8VI-L6OO_au7B46r2_3E', 'HTxwL3I-JCGChYJ8VI-L6OO_au7B47b1_3E', 'HTxwL3I-JCGChYJ8VI-L6OO_au7B45L0_3E', '-nFnOHM81r4j6k0gjAW3mujVU2B2K_c', '-F63fjptAgt5VM-kVkqdyU8n5ig', '-F6qfjptAgt5VM-kVkqdyU8n3twJ8lc', '-F6qfjptAgt5VM-kVkqdyU8n3vAO8lc', 'Gg8lN4UfRSqiPg7Jn2ZI12V4DCEwkj1E4LVeHbau', 'Gg8gN4UfRSqiPg7Jn2ZI12V4DCEwkj1E4LVeHY5a64vr', 'Gg8gN4UfRSqiPg7Jn2ZI12V4DCEwkj1E4LVeHY527Ivr', 'Gg8gN4UfRSqiPg7Jn2ZI12V4DCEwkj1E4LVeHY4S7Yvr'].map(f => `assets/fonts/${f}.ttf`);
const SHELL = [
  './', 'index.html', 'design.css', 'styles.css', 'app.js', 'import.js',
  'data/holidays.js', 'data/facts.js', 'data/peribahasa.js',
  'assets/fonts.css', 'assets/paper-grain.webp', 'assets/print-atlas.webp', 'assets/postcard-street.webp', 'assets/batik-strip.webp',
  'manifest.webmanifest', 'icons/icon.svg', 'icons/icon-192.png',
  ...FONTS,
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Stale-while-revalidate for the app's own files. Calendar feeds (/api/ics) always go to the network.
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin || url.pathname.startsWith('/api/')) return;
  e.respondWith(
    caches.open(CACHE).then(async cache => {
      const cached = await cache.match(req, { ignoreSearch: true });
      const network = fetch(req)
        .then(res => { if (res && res.ok) cache.put(req, res.clone()); return res; })
        .catch(() => cached);
      return cached || network;
    })
  );
});
