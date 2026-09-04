CREATE OR REPLACE FUNCTION public.increment_fish_catch(_wallet text, _rarity text)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  col text;
  result public.profiles;
BEGIN
  IF _rarity NOT IN ('common', 'rare', 'epic', 'legendary', 'mythic') THEN
    RAISE EXCEPTION 'Invalid rarity: %', _rarity;
  END IF;
  col := quote_ident('fish_' || _rarity);
  EXECUTE format(
    'UPDATE public.profiles SET %1$s = %1$s + 1 WHERE wallet_address = $1 RETURNING *',
    col
  ) INTO result USING lower(_wallet);
  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION public.increment_fish_catch(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_fish_catch(text, text) TO service_role;