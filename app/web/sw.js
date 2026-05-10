// Kill-switch service worker — substitui o SW antigo do React PWA
// (vite-plugin-pwa, /sw.js). Limpa caches, desregistra a si próprio e força
// reload das abas. Após uma única passagem, o site fica sem SW em /sw.js;
// o Flutter PWA registra seu próprio SW em /flutter_service_worker.js.

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    try {
      const names = await caches.keys();
      await Promise.all(names.map((n) => caches.delete(n)));
    } catch (_) {}
    try {
      await self.registration.unregister();
    } catch (_) {}
    try {
      const clients = await self.clients.matchAll({ type: 'window' });
      for (const c of clients) {
        c.navigate(c.url);
      }
    } catch (_) {}
  })());
});
