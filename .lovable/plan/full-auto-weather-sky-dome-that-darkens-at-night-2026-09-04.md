# Full-auto weather + sky dome that darkens at night

## 1. Remove the unused Auto/Manual switch

Confirmed: nothing in the UI reads `auto` or calls `setAuto` — it is dead code.

- `src/hooks/useDayNight.ts`: drop `auto` and `setAuto` from the store interface and implementation. `hour` and `advance` stay.
- `src/components/game/WeatherCycleController.tsx`: keep advancing the clock and rolling weather every interval, unconditionally. Remove the `auto` read, the `wasAuto` ref, and the elapsed-reset branch tied to toggling.

Weather stays fully automatic and permanent — no manual controls anywhere.

## 2. Sky dome darkens at night

Approach: extend the existing `<Sky>` shader patch. It is a single `useEffect` that already injects one uniform and one replacement into the fragment shader, guarded by an `includes("uSaturation")` check, so adding a second uniform to the same injected block is low risk and needs no extra geometry, draw call, or transparency ordering. A separate dark dome would have to sit between the sky and the scene and would fight fog and render order — higher risk for the same result.

In `Atmosphere` (`src/components/game/Weather.tsx`):

- Add `uNightMix: { value: 0 }` next to `uSaturation` in the shader patch, plus a `uniform vec3 uNightColor;` so the tint colour can be pushed in per frame.
- In the injected snippet, after the saturation step, mix the final colour toward the night colour by `uNightMix` at full weight, before `#include <colorspace_fragment>`.
- Per frame, after `dayNightAt` gives `brightness` and `tint`:
  - saturation uniform = damped `target.skySaturation` multiplied by `brightness`, so the dome desaturates as it darkens.
  - `uNightMix` = `1 - brightness`.
  - `uNightColor` copies the current day tint (deep blue `#1d2c5c` at the darkest anchor).

Full weight here is intentional: the sky dome is the night sky itself, not a 30% mood tint like fog and sun colour.

## 3. Unchanged

`sunPosition`, `turbidity`, `rayleigh`, `mieCoefficient`, clouds, rain, wind, lightning, and every weather preset field stay exactly as they are. The sun does not travel across the sky — it only dims.

## Verification

Typecheck, then load the preview and capture the scene at a couple of in-game hours to confirm the sky goes dark blue at night and returns to blue by day.
