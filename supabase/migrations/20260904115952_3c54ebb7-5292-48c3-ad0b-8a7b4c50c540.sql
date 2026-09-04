ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS coins numeric NOT NULL DEFAULT 0;

CREATE TABLE public.mutations (
  key text PRIMARY KEY,
  label text NOT NULL,
  multiplier numeric NOT NULL,
  drop_weight numeric NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.mutations TO anon, authenticated;
GRANT ALL ON public.mutations TO service_role;
ALTER TABLE public.mutations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Mutations are publicly readable" ON public.mutations FOR SELECT USING (true);
CREATE TRIGGER mutations_set_updated_at BEFORE UPDATE ON public.mutations FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

INSERT INTO public.mutations (key, label, multiplier, drop_weight) VALUES
  ('none', 'Normal', 1, 55),
  ('big', 'Big', 1.2, 15),
  ('dark', 'Dark', 1.3, 10),
  ('albino', 'Albino', 1.4, 7),
  ('sparkling', 'Sparkling', 1.5, 5),
  ('glossy', 'Glossy', 1.6, 3.5),
  ('shiny', 'Shiny', 1.85, 2),
  ('midas', 'Midas', 2.5, 1.2),
  ('sunken', 'Sunken', 4, 0.7),
  ('abyssal', 'Abyssal', 5.5, 0.4),
  ('mythical', 'Mythical', 6, 0.2);

ALTER TABLE public.fish_species ADD COLUMN IF NOT EXISTS base_price_per_kg numeric;

UPDATE public.fish_species s
SET base_price_per_kg = round((
  CASE
    WHEN s.is_monster THEN 57000
    WHEN s.rarity = 'common' THEN 100
    WHEN s.rarity = 'rare' THEN 350
    WHEN s.rarity = 'epic' THEN 1000
    WHEN s.rarity = 'legendary' THEN 4000
    WHEN s.rarity = 'mythic' THEN 38000
    ELSE 100
  END
) / GREATEST((s.min_weight_kg + s.max_weight_kg) / 2, 0.01), 4);

ALTER TABLE public.fish_species ALTER COLUMN base_price_per_kg SET NOT NULL;
ALTER TABLE public.fish_species ALTER COLUMN base_price_per_kg SET DEFAULT 1;

CREATE TABLE public.fish_inventory_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_address text NOT NULL,
  species_id text NOT NULL REFERENCES public.fish_species(id),
  weight_kg numeric NOT NULL,
  mutation_key text NOT NULL DEFAULT 'none' REFERENCES public.mutations(key),
  caught_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX fish_inventory_items_wallet_idx ON public.fish_inventory_items (wallet_address);
GRANT SELECT ON public.fish_inventory_items TO authenticated;
GRANT ALL ON public.fish_inventory_items TO service_role;
ALTER TABLE public.fish_inventory_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owners can read their own fish" ON public.fish_inventory_items
  FOR SELECT TO authenticated
  USING (lower(wallet_address) = lower(coalesce(auth.jwt() ->> 'wallet_address', '')));

CREATE OR REPLACE FUNCTION public.record_catch(
  _wallet text,
  _rarity text,
  _species_id text,
  _weight_kg numeric,
  _mutation_key text
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  col text;
  result public.profiles;
BEGIN
  IF _rarity NOT IN ('common', 'rare', 'epic', 'legendary', 'mythic') THEN
    RAISE EXCEPTION 'Invalid rarity: %', _rarity;
  END IF;

  INSERT INTO public.fish_inventory_items (wallet_address, species_id, weight_kg, mutation_key)
  VALUES (lower(_wallet), _species_id, _weight_kg, coalesce(_mutation_key, 'none'));

  col := quote_ident('fish_' || _rarity);
  EXECUTE format(
    'UPDATE public.profiles SET %1$s = %1$s + 1 WHERE wallet_address = $1 RETURNING *',
    col
  ) INTO result USING lower(_wallet);
  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION public.record_catch(text, text, text, numeric, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_catch(text, text, text, numeric, text) TO service_role;

CREATE OR REPLACE FUNCTION public.sell_fish(
  _wallet text,
  _item_id uuid,
  _species_id text,
  _sell_all boolean
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  total numeric := 0;
  result public.profiles;
BEGIN
  WITH sold AS (
    DELETE FROM public.fish_inventory_items i
    WHERE i.wallet_address = lower(_wallet)
      AND (
        (_item_id IS NOT NULL AND i.id = _item_id)
        OR (_item_id IS NULL AND _species_id IS NOT NULL AND i.species_id = _species_id)
        OR (_item_id IS NULL AND _species_id IS NULL AND coalesce(_sell_all, false))
      )
    RETURNING i.species_id, i.weight_kg, i.mutation_key
  )
  SELECT coalesce(sum(round(s.base_price_per_kg * sold.weight_kg * m.multiplier)), 0)
  INTO total
  FROM sold
  JOIN public.fish_species s ON s.id = sold.species_id
  JOIN public.mutations m ON m.key = sold.mutation_key;

  UPDATE public.profiles
  SET coins = coins + total
  WHERE wallet_address = lower(_wallet)
  RETURNING * INTO result;

  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION public.sell_fish(text, uuid, text, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sell_fish(text, uuid, text, boolean) TO service_role;