// Service worker: deixa o app abrir sem internet.
const C = 'treino-v2';
const SHELL = ['./', 'index.html', 'manifest.webmanifest', 'icon-192.png', 'icon-512.png', 'apple-touch-icon.png'];
const EXTERNOS = ['cdn.jsdelivr.net', 'fonts.googleapis.com', 'fonts.gstatic.com'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(C).then((c) => c.addAll(SHELL)).catch(() => {}));
  self.skipWaiting();
});
self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((ks) => Promise.all(ks.filter((k) => k !== C).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// responde do cache e atualiza em segundo plano
function swr(r) {
  return caches.open(C).then((c) =>
    c.match(r).then((hit) => {
      const net = fetch(r)
        .then((res) => { if (res && (res.ok || res.type === 'opaque')) c.put(r, res.clone()); return res; })
        .catch(() => hit);
      return hit || net;
    })
  );
}

// página: tenta a internet (até 4 s); se falhar, usa a última versão guardada
function pagina(r) {
  const net = fetch(r).then((res) => {
    if (res && res.ok) {
      caches.open(C).then((c) => { c.put(r, res.clone()); c.put('index.html', res.clone()); });
    }
    return res;
  });
  const limite = new Promise((_, rej) => setTimeout(rej, 4000));
  return Promise.race([net, limite])
    .catch(() => caches.match(r, { ignoreSearch: true })
      .then((m) => m || caches.match('index.html') || caches.match('./')))
    .then((m) => m || net);
}

self.addEventListener('fetch', (e) => {
  const r = e.request;
  if (r.method !== 'GET') return;
  const u = new URL(r.url);
  if (r.mode === 'navigate') { e.respondWith(pagina(r)); return; }
  if (u.origin === self.location.origin || EXTERNOS.includes(u.hostname)) { e.respondWith(swr(r)); }
  // todo o resto (a API do Supabase) passa direto, sem cache
});
