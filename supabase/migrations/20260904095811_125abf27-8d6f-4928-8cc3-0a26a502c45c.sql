ALTER TABLE public.profiles
  ADD COLUMN fish_common integer NOT NULL DEFAULT 0,
  ADD COLUMN fish_rare integer NOT NULL DEFAULT 0,
  ADD COLUMN fish_epic integer NOT NULL DEFAULT 0,
  ADD COLUMN fish_legendary integer NOT NULL DEFAULT 0,
  ADD COLUMN fish_mythic integer NOT NULL DEFAULT 0;