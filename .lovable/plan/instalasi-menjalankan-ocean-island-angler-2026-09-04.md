# Instalasi & Menjalankan "Ocean Island Angler"

File `go-fish-main.zip` berisi game memancing 3D lengkap (TanStack Start + React Three Fiber + Three.js): lautan luas, pulau kecil, karakter, mekanik lempar pancing, animasi ikan, cuaca, dan audio.

## Langkah

1. **Salin kode sumber ke proyek**
   - Ekstrak zip (sudah diverifikasi tidak mengandung `.git`).
   - Salin `src/`, `public/`, `plugins/`, `vite.config.ts`, `bunfig.toml`, `tsconfig.json`, `eslint.config.js`, `components.json` ke proyek, menimpa file template placeholder.
2. **Gabungkan dependensi**
   - Ganti `package.json` proyek dengan versi dari zip (menambah `three`, `@react-three/fiber`, `@react-three/drei`, `postprocessing`, `zustand`, dsb) dan sinkronkan `bun.lock`/`package-lock.json` via `bun install`.
3. **Verifikasi aset**
   - Pastikan aset pointer (`boat.glb.asset.json`, audio `.asset.json`) dan `public/audio/` termuat; jika pointer asset gagal, salin aset binary yang diperlukan.
4. **Jalankan & uji**
   - Dev server restart otomatis setelah instalasi; buka preview dan verifikasi dengan Playwright: halaman game termuat, canvas 3D tampil, tidak ada error konsol.
5. **Perbaiki jika ada error** build/runtime (mis. konflik versi TanStack dengan template).

## Detail teknis

- Route utama game ada di `src/routes/index.tsx` (menggantikan placeholder).
- Plugin kustom `plugins/worldAssetsDev.ts` akan didaftarkan di `vite.config.ts`.
- Tidak memakai database/backend — game murni frontend (state via zustand), jadi Lovable Cloud tidak diperlukan.
