# Data-Driven Fish Catch System

Move catch logic out of hardcoded constants into database-backed tables: per-species rarity, rod weight caps, bait multipliers, and weather that changes both bite window and rarity odds. Same 6 fish, same 3D models, same colors.

## 1. Database (new read-only tables)

- `fish_species` — id, name, color, rarity, min/max weight, is_monster. Seeded with the existing 6 entries (clownfish 5-40 common, mackerel 35-120 rare, scad 100-300 epic, red_snapper 280-650 legendary, baby_tuna 600-1300 mythic, ancient_leviathan 1200-3000 monster).
- `rarity_base_weights` — common 100, rare 45, epic 18, legendary 6, mythic 2.
- `rod_tiers` — common 100, rare 300, epic 600, legendary 1000, mythic 2500 kg cap.
- `bait_tiers` — one row `basic_bait`, all multipliers 1.
- `weather_effects` — keyed by the existing weather keys (`cerah`, `berawan`, `berkabut`, `hujan`, `badai`), with bite window seconds and rarity multipliers as specified.
- `game_config` — `monster_catch_chance = 0.02`.

Access: anyone can read these tables; nobody can write from the app. Rows are managed manually for now.

A matching SQL file is also added under `supabase/migrations/` so a fresh clone can recreate everything (that folder is currently empty).

## 2. Catch logic

New `src/lib/fishData.functions.ts` + a `useFishData()` react-query hook fetch all six tables once on game load and cache them.

`rollFish()` in `useGameStore.ts` becomes a pure function taking `{ data, weather, rodTierId, baitTierId }`:

1. Roll `monster_catch_chance` → Ancient Leviathan, then jump to step 5.
2. Read the active rod's `max_catch_weight_kg`.
3. Drop every non-monster species whose `min_weight_kg` exceeds that cap.
4. Weight each survivor = rarity base × bait multiplier × weather multiplier (missing tiers = 1.0), then weighted-random pick.
5. Roll actual weight inside the chosen species' range.

`FishCatch` gains a `rarity` field; `color` keeps coming from the data as-is.

Active gear stays constants (`ACTIVE_ROD_TIER = "common"`, `ACTIVE_BAIT_TIER = "basic_bait"`) but all numbers come from the tables, so a future shop only swaps the ids.

Until the tables load, a small in-code snapshot of the same seed values is used as fallback so a cast never breaks.

## 3. Angler.tsx — exactly two touch points

- line ~474: `rollFish()` call now passes the cached table data plus the current weather and active rod/bait.
- line ~491: hardcoded `1.6` replaced by the active weather's `bite_window_seconds`.

The bite delay at line ~448, animation, physics, and the phase machine are untouched.

## 4. Profile sync

New server function `recordCatch` increments `fish_{rarity}` on `profiles`, verified with the existing wallet signature proof (no new signing prompt). Monster catches count as `fish_mythic`. Fired after the `caught` phase lands a fish, fire-and-forget: no wallet connected or a failed call never blocks gameplay.

## 5. HUD

The "Latest" panel gains a small rarity badge under name and weight — grey common, blue rare, purple epic, orange legendary, gold/red mythic. No extra message when the rod is too weak for high tiers.

## Technical notes

- Tables are fetched through a public server function using the publishable-key client (SSR-safe), cached with react-query `staleTime: Infinity`.
- Weather table keys deliberately stay the Indonesian `WeatherKind` keys used by `useWeather.ts`; only labels are English.
- `MONSTER_CHANCE = 0.5` is removed in favour of `game_config.monster_catch_chance`.
- No changes to Fish/MonsterFish geometry, materials, or the boat/player code.
