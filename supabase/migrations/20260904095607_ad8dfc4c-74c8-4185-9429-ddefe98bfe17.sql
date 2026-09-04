CREATE OR REPLACE FUNCTION public.set_updated_at() RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE TABLE public.rarity_base_weights (
  rarity text PRIMARY KEY,
  base_weight numeric NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.rarity_base_weights TO anon, authenticated;
GRANT ALL ON public.rarity_base_weights TO service_role;
ALTER TABLE public.rarity_base_weights ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Rarity weights are publicly readable" ON public.rarity_base_weights FOR SELECT USING (true);

CREATE TABLE public.fish_species (
  id text PRIMARY KEY,
  name text NOT NULL,
  color text NOT NULL,
  rarity text REFERENCES public.rarity_base_weights(rarity),
  min_weight_kg numeric NOT NULL,
  max_weight_kg numeric NOT NULL,
  is_monster boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.fish_species TO anon, authenticated;
GRANT ALL ON public.fish_species TO service_role;
ALTER TABLE public.fish_species ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Fish species are publicly readable" ON public.fish_species FOR SELECT USING (true);

CREATE TABLE public.rod_tiers (
  id text PRIMARY KEY,
  name text NOT NULL,
  max_catch_weight_kg numeric NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.rod_tiers TO anon, authenticated;
GRANT ALL ON public.rod_tiers TO service_role;
ALTER TABLE public.rod_tiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Rod tiers are publicly readable" ON public.rod_tiers FOR SELECT USING (true);

CREATE TABLE public.bait_tiers (
  id text PRIMARY KEY,
  name text NOT NULL,
  rarity_multiplier jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.bait_tiers TO anon, authenticated;
GRANT ALL ON public.bait_tiers TO service_role;
ALTER TABLE public.bait_tiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Bait tiers are publicly readable" ON public.bait_tiers FOR SELECT USING (true);

CREATE TABLE public.weather_effects (
  weather_kind text PRIMARY KEY,
  bite_window_seconds numeric NOT NULL,
  rarity_multiplier jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.weather_effects TO anon, authenticated;
GRANT ALL ON public.weather_effects TO service_role;
ALTER TABLE public.weather_effects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Weather effects are publicly readable" ON public.weather_effects FOR SELECT USING (true);

CREATE TABLE public.game_config (
  key text PRIMARY KEY,
  value numeric NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.game_config TO anon, authenticated;
GRANT ALL ON public.game_config TO service_role;
ALTER TABLE public.game_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Game config is publicly readable" ON public.game_config FOR SELECT USING (true);

CREATE TRIGGER rarity_base_weights_set_updated_at BEFORE UPDATE ON public.rarity_base_weights FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER fish_species_set_updated_at BEFORE UPDATE ON public.fish_species FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER rod_tiers_set_updated_at BEFORE UPDATE ON public.rod_tiers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER bait_tiers_set_updated_at BEFORE UPDATE ON public.bait_tiers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER weather_effects_set_updated_at BEFORE UPDATE ON public.weather_effects FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER game_config_set_updated_at BEFORE UPDATE ON public.game_config FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

INSERT INTO public.rarity_base_weights (rarity, base_weight) VALUES
  ('common', 100), ('rare', 45), ('epic', 18), ('legendary', 6), ('mythic', 2);

INSERT INTO public.fish_species (id, name, color, rarity, min_weight_kg, max_weight_kg, is_monster) VALUES
  ('clownfish', 'Clownfish', '#f5a623', 'common', 5, 40, false),
  ('mackerel', 'Mackerel', '#8fd0e8', 'rare', 35, 120, false),
  ('scad', 'Scad', '#a7e0b0', 'epic', 100, 300, false),
  ('red_snapper', 'Red Snapper', '#e8734a', 'legendary', 280, 650, false),
  ('baby_tuna', 'Baby Tuna', '#5b7fa6', 'mythic', 600, 1300, false),
  ('ancient_leviathan', 'Ancient Leviathan', '#1e46b4', 'mythic', 1200, 3000, true);

INSERT INTO public.rod_tiers (id, name, max_catch_weight_kg) VALUES
  ('common', 'Common Rod', 100),
  ('rare', 'Rare Rod', 300),
  ('epic', 'Epic Rod', 600),
  ('legendary', 'Legendary Rod', 1000),
  ('mythic', 'Mythic Rod', 2500);

INSERT INTO public.bait_tiers (id, name, rarity_multiplier) VALUES
  ('basic_bait', 'Basic Bait', '{"common":1,"rare":1,"epic":1,"legendary":1,"mythic":1}'::jsonb);

INSERT INTO public.weather_effects (weather_kind, bite_window_seconds, rarity_multiplier) VALUES
  ('cerah', 1.6, '{"common":1,"rare":1,"epic":1,"legendary":1,"mythic":1}'::jsonb),
  ('berawan', 1.6, '{"common":1,"rare":1,"epic":1,"legendary":1,"mythic":1}'::jsonb),
  ('berkabut', 1.3, '{"epic":1.3,"legendary":1.3,"mythic":1.3}'::jsonb),
  ('hujan', 1.1, '{"epic":1.3,"legendary":1.5,"mythic":1.5}'::jsonb),
  ('badai', 0.9, '{"legendary":1.8,"mythic":2.5}'::jsonb);

INSERT INTO public.game_config (key, value) VALUES ('monster_catch_chance', 0.02);