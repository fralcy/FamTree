// Service worker CỦA APP tự viết — Flutter SDK hiện tại (từ bản dùng
// flutter_bootstrap.js) sinh flutter_service_worker.js RỖNG, chỉ tự
// unregister() ngay khi activate (Flutter đang bỏ dần cơ chế cache SW cũ,
// xem https://github.com/flutter/flutter/issues/156910) — không còn cache
// gì cả nếu chỉ dựa vào mặc định, app không dùng offline được.
//
// Chiến lược: network-first, fallback cache khi mất mạng — luôn lấy bản
// mới nhất khi còn mạng (ghi đè cache mỗi lần fetch thành công), chỉ dùng
// cache khi fetch thất bại (offline). Nhờ vậy không cần tự tăng version
// cache thủ công mỗi lần deploy như chiến lược cache-first thường thấy.
const CACHE_NAME = 'fam-tree-offline-v1';

// "Khung" ứng dụng — PHẢI có sẵn trong cache trước khi offline lần đầu,
// nếu không main.dart.js sẽ fetch lỗi và Flutter không boot được (trang
// trắng). KHÔNG thể trông chờ cache tự lấp đầy qua fetch handler bên dưới
// vì trang đầu tiên tải các file này TRƯỚC KHI service worker kịp kiểm
// soát (client bị "claim" chỉ ảnh hưởng các lần fetch SAU đó).
const APP_SHELL = [
  './',
  'index.html',
  'main.dart.js',
  'flutter.js',
  'flutter_bootstrap.js',
  // File này do Flutter tự sinh và RỖNG (chỉ tự unregister), nhưng
  // flutter_bootstrap.js vẫn cố tải nó mỗi lần mở app — precache luôn để
  // khỏi báo lỗi network vô hại khi offline (không ảnh hưởng gì vì file
  // này không làm gì cả, chỉ đỡ ồn console).
  'flutter_service_worker.js',
  'manifest.json',
  'favicon.png',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'assets/AssetManifest.bin',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  'assets/assets/branding/icon.png',
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      // addAll() sẽ fail toàn bộ nếu 1 file lỗi — thêm từng file riêng để 1
      // file thiếu (vd đổi tên asset sau này quên cập nhật list) không làm
      // hỏng cache của TOÀN BỘ khung ứng dụng.
      await Promise.all(
        APP_SHELL.map((url) => cache.add(url).catch((err) => console.warn('Precache lỗi:', url, err))),
      );
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  // Bỏ qua request khác origin (vd canvaskit tải từ gstatic.com CDN) —
  // không can thiệp, tránh lỗi CORS/opaque response khi ghi cache.
  if (url.origin !== self.location.origin) return;

  event.respondWith(
    (async () => {
      try {
        const response = await fetch(request);
        if (response && response.ok) {
          const cache = await caches.open(CACHE_NAME);
          cache.put(request, response.clone());
        }
        return response;
      } catch (err) {
        const cached = await caches.match(request, { ignoreSearch: true });
        if (cached) return cached;
        throw err;
      }
    })(),
  );
});
