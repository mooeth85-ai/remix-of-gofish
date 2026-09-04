# Plan: Run the `gofish` repo in this project's preview

## Goal
The user shared `https://github.com/lockhoodfun-sys/gofish.git` — a 3D fishing game. They
want it downloaded and **run** in this project's live preview. The repo uses the exact same
stack as this project (TanStack Start v1, React 19, Tailwind v4, shadcn/ui), so we can swap
this project's source for the repo's source, install, and run — no stack conversion needed.

## What the repo contains
- Same template structure: `src/routes/__root.tsx`, `src/routes/index.tsx`, `src/router.tsx`,
  `src/styles.css`, `src/server.ts`, `src/start.ts`.
- Game code under `src/components/game/` (Angler, Boat, Fish, MonsterFish, Ocean, Weather,
  HUD, GameCanvas, WorldObjects, WorldEditor, RainImpacts, MonsterBurst).
- State hooks: `useGameStore`, `useWorldStore`, `usePlayer`, `useBoat`, `useWeather`.
- 3D assets in `public/models/*.glb` and `src/assets/*.glb` plus audio in `public/audio/`.
- World layout data in `src/data/worldLayout.json`.
- Extra deps vs. current project: `@react-three/fiber`, `@react-three/drei`,
  `@react-three/postprocessing`, `postprocessing`, `embla-carousel-react`, `cmdk`,
  `input-otp`, `date-fns`, and the full Radix UI + shadcn set.

## Steps (build mode)

1. **Fetch the repo tarball** (no `.git` metadata, avoids the git-state corruption risk):
   `curl -L https://github.com/lockhoodfun-sys/gofish/archive/refs/heads/main.tar.gz -o /tmp/gofish.tar.gz`
   and extract to `/tmp/gofish`.

2. **Overwrite project files** from the extracted repo into the project root — `src/`,
   `public/`, `plugins/`, plus root config: `package.json`, `bun.lock`, `bunfig.toml`,
   `vite.config.ts`, `tsconfig.json`, `components.json`, `eslint.config.js`,
   `.prettierignore`, `.prettierrc`, `AGENTS.md`, `README.md`, `src/routeTree.gen.ts`,
   `src/styles.css`. Use rsync excluding `.git`. Skip the committed `gofish-main.zip`
   (unneeded bulk). Preserve `.lovable/` (project identity + this plan) and `.gitignore`.

3. **Install dependencies** with `bun install`.

4. **Verify build/dev**: check `/tmp/observability/build-errors.log`, then load the preview
   and confirm the game canvas renders (no console/runtime errors). Run a Playwright check
   if needed to confirm the 3D scene loads.

## Notes / risks
- Replaces the current placeholder app entirely — that is the intent.
- The repo carries large `.glb` binaries; dev server should still serve them fine.
- `routeTree.gen.ts` is committed in the repo, so it will regenerate cleanly.
- If the preview needs a backend (none observed — game is client-side), we won't enable one.

## Out of scope
No feature changes, no new gameplay. Only: get the existing `gofish` code running here.
