CREATE TABLE public.weather_cycle_config (
  id text PRIMARY KEY,
  change_interval_seconds numeric NOT NULL DEFAULT 240,
  weights jsonb NOT NULL DEFAULT '{"cerah":40,"berawan":25,"berkabut":15,"hujan":12,"badai":8}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT ON public.weather_cycle_config TO anon, authenticated;
GRANT ALL ON public.weather_cycle_config TO service_role;

ALTER TABLE public.weather_cycle_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Weather cycle config is publicly readable"
  ON public.weather_cycle_config FOR SELECT USING (true);

CREATE TRIGGER weather_cycle_config_set_updated_at
  BEFORE UPDATE ON public.weather_cycle_config
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

INSERT INTO public.weather_cycle_config (id) VALUES ('default');

INSERT INTO public.game_config (key, value) VALUES ('day_length_seconds', 720)
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;