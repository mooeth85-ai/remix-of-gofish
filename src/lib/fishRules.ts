/** Data-driven catch rules. All numbers come from the database tables; the
 *  constants below are only a boot-time snapshot used until the fetch lands. */

export type Rarity = "common" | "rare" | "epic" | "legendary" | "mythic";

export const RARITIES: Rarity[] = ["common", "rare", "epic", "legendary", "mythic"];

export interface FishSpecies {
  id: string;
  name: string;
  color: string;
  rarity: Rarity | null;
  min_weight_kg: number;
  max_weight_kg: number;
  is_monster: boolean;
}

export interface RarityMultiplier {
  [rarity: string]: number | undefined;
}

export interface RodTier {
  id: string;
  name: string;
  max_catch_weight_kg: number;
}

export interface BaitTier {
  id: string;
  name: string;
  rarity_multiplier: RarityMultiplier;
}

export interface WeatherEffect {
  weather_kind: string;
  bite_window_seconds: number;
  rarity_multiplier: RarityMultiplier;
}

export interface FishData {
  species: FishSpecies[];
  rarityWeights: Record<string, number>;
  rods: RodTier[];
  baits: BaitTier[];
  weather: Record<string, WeatherEffect>;
  config: Record<string, number>;
}

/** Active gear. A future shop swaps these ids; the formula stays untouched. */
export const ACTIVE_ROD_TIER = "common";
export const ACTIVE_BAIT_TIER = "basic_bait";

export const DEFAULT_BITE_WINDOW = 1.6;

/** Offline fallback mirroring the seeded rows. */
export const FALLBACK_FISH_DATA: FishData = {
  species: [
    { id: "clownfish", name: "Clownfish", color: "#f5a623", rarity: "common", min_weight_kg: 5, max_weight_kg: 40, is_monster: false },
    { id: "mackerel", name: "Mackerel", color: "#8fd0e8", rarity: "rare", min_weight_kg: 35, max_weight_kg: 120, is_monster: false },
    { id: "scad", name: "Scad", color: "#a7e0b0", rarity: "epic", min_weight_kg: 100, max_weight_kg: 300, is_monster: false },
    { id: "red_snapper", name: "Red Snapper", color: "#e8734a", rarity: "legendary", min_weight_kg: 280, max_weight_kg: 650, is_monster: false },
    { id: "baby_tuna", name: "Baby Tuna", color: "#5b7fa6", rarity: "mythic", min_weight_kg: 600, max_weight_kg: 1300, is_monster: false },
    { id: "ancient_leviathan", name: "Ancient Leviathan", color: "#1e46b4", rarity: "mythic", min_weight_kg: 1200, max_weight_kg: 3000, is_monster: true },
  ],
  rarityWeights: { common: 100, rare: 45, epic: 18, legendary: 6, mythic: 2 },
  rods: [
    { id: "common", name: "Common Rod", max_catch_weight_kg: 100 },
    { id: "rare", name: "Rare Rod", max_catch_weight_kg: 300 },
    { id: "epic", name: "Epic Rod", max_catch_weight_kg: 600 },
    { id: "legendary", name: "Legendary Rod", max_catch_weight_kg: 1000 },
    { id: "mythic", name: "Mythic Rod", max_catch_weight_kg: 2500 },
  ],
  baits: [
    {
      id: "basic_bait",
      name: "Basic Bait",
      rarity_multiplier: { common: 1, rare: 1, epic: 1, legendary: 1, mythic: 1 },
    },
  ],
  weather: {
    cerah: { weather_kind: "cerah", bite_window_seconds: 1.6, rarity_multiplier: {} },
    berawan: { weather_kind: "berawan", bite_window_seconds: 1.6, rarity_multiplier: {} },
    berkabut: { weather_kind: "berkabut", bite_window_seconds: 1.3, rarity_multiplier: { epic: 1.3, legendary: 1.3, mythic: 1.3 } },
    hujan: { weather_kind: "hujan", bite_window_seconds: 1.1, rarity_multiplier: { epic: 1.3, legendary: 1.5, mythic: 1.5 } },
    badai: { weather_kind: "badai", bite_window_seconds: 0.9, rarity_multiplier: { legendary: 1.8, mythic: 2.5 } },
  },
  config: { monster_catch_chance: 0.02 },
};

/** Module-level snapshot so the render loop can read rules synchronously. */
let current: FishData = FALLBACK_FISH_DATA;

export function setFishData(data: FishData) {
  current = data;
}

export function getFishData(): FishData {
  return current;
}

export function biteWindowFor(weatherKind: string): number {
  return current.weather[weatherKind]?.bite_window_seconds ?? DEFAULT_BITE_WINDOW;
}

export function mult(map: RarityMultiplier | undefined, rarity: string): number {
  const v = map?.[rarity];
  return typeof v === "number" && v > 0 ? v : 1;
}
