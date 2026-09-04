REVOKE ALL ON FUNCTION public.record_catch(text, text, text, numeric, text) FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION public.sell_fish(text, uuid, text, boolean) FROM anon, authenticated, PUBLIC;
REVOKE ALL ON FUNCTION public.increment_fish_catch(text, text) FROM anon, authenticated, PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_catch(text, text, text, numeric, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.sell_fish(text, uuid, text, boolean) TO service_role;
GRANT EXECUTE ON FUNCTION public.increment_fish_catch(text, text) TO service_role;