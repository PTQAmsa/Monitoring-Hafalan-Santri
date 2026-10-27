/* Service worker: menyimpan aplikasi di HP agar bisa dibuka tanpa internet
   setelah pemasangan pertama. Naikkan VERSI setiap kali file HTML diperbarui
   supaya HP para guru mengambil versi terbaru saat online. */
const VERSI = "hafalan-v14";
const BERKAS = [
  "./Monitoring%20Hafalan%20Santri.html",
  "./manifest.webmanifest",
  "./icon-192.png",
  "./icon-512.png"
];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(VERSI).then(c => c.addAll(BERKAS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== VERSI).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});

/* Strategi: coba jaringan dulu (agar pembaruan cepat terambil), kalau gagal pakai salinan tersimpan. */
self.addEventListener("fetch", e => {
  if (e.request.method !== "GET") return;
  if (new URL(e.request.url).origin !== self.location.origin) return; // data Supabase tidak pernah di-cache
  e.respondWith(
    fetch(e.request).then(r => { const copy = r.clone(); caches.open(VERSI).then(c => c.put(e.request, copy)); return r; })
      .catch(() => caches.match(e.request, { ignoreSearch: true }))
  );
});
