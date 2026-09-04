# Day/Night Cycle + Automatic Weather Cycle

A new visual and timing layer on top of the existing weather system. Weather presets in `useWeather.ts` stay exactly as they are — the day cycle only multiplies brightness and blends a small color tint over the final result.

## 1. Time of day

New store `src/hooks/useDayNight.ts`:
- `hour` (0-24 float), starts at 7.0 on every load, advances each frame: `hour += dt / dayLengthSeconds * 24`, wrapping past 24.
- `dayLengthSeconds` read from `game_config` key `day_length_seconds` (new row, value 720), with 720 as in-code fallback.
- Four anchors as code constants (visual tuning, not game balance):
  - hour 0 — brightness 0.35, deep blue tint
  - hour 6 — brightness 0.70, warm orange tint
  - hour 12 — brightness 1.00, neutral white
  - hour 18 — brightness 0.70, warm orange tint
  - back down to midnight
- Brightness and tint interpolate with smoothstep between anchors, so the transition is continuous.
- A tiny driver component advances `hour` from the r3f frame loop.

## 2. Applying it in Weather.tsx

Only in the `Atmosphere` damp block:
- After damping to the weather target, multiply `s.ambient`, `s.hemi`, `s.sun` by `brightness`.
- Blend `fogColor` and `sunColor` toward the tint at 30% weight (weather stays dominant).
- The page backdrop in `GameCanvas.tsx` gets the same 30% tint blend so the sky behind the canvas matches.

Untouched: `sunPosition`, `turbidity`, `rayleigh`, `mieCoefficient`, cloud fields, rain, wind, lightning.

## 3. Automatic weather cycle

New read-only table `weather_cycle_config` (single row `default`):
- `change_interval_seconds` numeric, default 240
- `weights` jsonb, default `{"cerah":40,"berawan":25,"berkabut":15,"hujan":12,"badai":8}`

Public read access, no writes from the app — same policy shape as the other game tables. Fetched alongside the existing tables in `fishData.functions.ts`, with an in-code fallback mirroring the defaults.

New `WeatherCycleController.tsx` mounted in `GameCanvas` (renders nothing):
- Timer runs continuously; every `change_interval_seconds` it does a weighted random pick and calls `setKind` — but only while Auto mode is on.
- In Manual mode the timer keeps running silently; switching back to Auto resets the timer so it doesn't snap mid-interval.

## 4. HUD

- "Auto" toggle next to the existing weather buttons. Default ON. Clicking any manual weather button switches to Manual (Auto badge dims); clicking Auto returns to automatic.
- Time-of-day indicator in a HUD corner: label from hour range — Dawn (5-7), Day (7-17), Dusk (17-19), Night (19-5) — with a lucide icon (Sunrise / Sun / Sunset / Moon).

## Technical notes

- Auto/manual flag lives in the day-night store (or the weather store) so both HUD and controller share it.
- No changes to `rollFish`, rod caps, bait, or rarity logic — they already read `useWeather.getState().kind` live.
- The new `game_config` row and `weather_cycle_config` table go in one migration.
