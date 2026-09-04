# Fish Merchant NPC, fish mutations, and coin sales

The fish shop on the island gets a keeper you can walk up to and talk with. Every fish you catch is now stored individually with its own weight and a possible special mutation, and you can sell them for coins that show up in your wallet panel.

Note on placement: the world contains a fish shop building (`FISHSHOP.glb`, near the boardwalk at roughly x 10, z 3.8) plus a bait shop, a rod shop and a boat shop. The merchant NPC goes at the fish shop counter. If you meant a different stall, say which one and I'll move him.

There is no humanoid character model in the project (the player is built from simple shapes), so the merchant is built the same way — a seated/standing shopkeeper made of simple shapes with an apron colour, clearly readable as a person behind the counter.

## 1. Database changes (one migration)

- `profiles`: new `coins` (number, default 0).
- New `mutations` table (public read-only, same style as the other rules tables): key, label, price multiplier, drop weight. Seeded with the 11 entries given: none 1/55, big 1.2/15, dark 1.3/10, albino 1.4/7, sparkling 1.5/5, glossy 1.6/3.5, shiny 1.85/2, midas 2.5/1.2, sunken 4/0.7, abyssal 5.5/0.4, mythical 6/0.2.
- `fish_species`: new `base_price_per_kg`, filled per species as tier target ÷ that species' own average weight (common 100, rare 350, epic 1000, legendary 4000, mythic 38000, monster 57000).
- New `fish_inventory_items` table: one row per catch — owner wallet, species, weight, mutation, caught time. Readable only by its owner; writes only through server code.
- New Postgres function that records a catch atomically: bumps the lifetime rarity counter (unchanged behaviour) and inserts the inventory row in one call.
- New Postgres function that sells: deletes the chosen rows and adds the summed price to `coins` in one call, returning the updated profile.

## 2. Catch flow

- `src/lib/fishRules.ts`: `FishData` gains `mutations` (plus a fallback list mirroring the seed) and species carry `base_price_per_kg`.
- `src/lib/fishData.functions.ts`: also fetch the mutations table.
- `rollFish()` in `src/hooks/useGameStore.ts`: after species and weight are picked exactly as today, a separate weighted mutation roll (independent of rarity); `FishCatch` gains `mutationKey`.
- `recordCatch` in `src/lib/profile.functions.ts`: input gains species id, weight and mutation key; calls the new atomic function instead of the plain counter RPC.
- `syncCatchToProfile()` passes the three new fields.

## 3. Selling

New `sellFish` server function taking the existing wallet proof plus one of: a single item id, a species id (sell that species' whole stock), or a sell-everything flag. Price per fish = species base price per kg x that fish's weight x mutation multiplier, rounded. Everything runs through the atomic sell function, so rapid clicking can't double-pay. Returns the updated profile and the remaining inventory.

New `getInventory` server function (proof-verified) returning the wallet's fish with species name, weight, mutation label and computed price.

## 4. NPC and dialog

- `src/components/game/FishMerchantNPC.tsx`: static shopkeeper at the fish shop counter, per-frame distance check to the player using the same pattern as the boat's "Press E to board", showing a "Press E to talk" prompt in range and opening the dialog on E. Mounted in `GameCanvas`.
- `src/components/profile/MerchantDialog.tsx`: closed → greeting (Sell Fish / Just chat / Leave) → selling list, grouped by species with each individual fish showing weight, mutation and price, with per-fish Sell, per-species Sell All, and a global Sell All Stock. "Just chat" shows one random flavour line and returns to the greeting. Each successful sale refreshes the list and the coin balance instantly, no reload. Uses the wallet proof already held in `useProfileStore`, so no re-signing.
- While the dialog is open, game keyboard input is suspended so typing/clicking doesn't cast the rod.

## 5. Coins in the wallet panel

`WalletButton.tsx`: the COINS row reads `profile.coins` from the profile store instead of the hardcoded 0.

## Out of scope

Lifetime rarity counters stay pure collection stats and never decrease on sale. Gold, daily NPC rotation, and USDG cash-out are not part of this change.
