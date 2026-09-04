# Player Profile System + English Localization

Two separate pieces of work, both additive: a new wallet-based player profile layer, and a full translation of the existing UI text to English. The game loop (GameCanvas, useGameStore behaviour, physics, world) stays functionally untouched.

## 1. Wallet connect (Robinhood Chain)

- Add `wagmi` + `viem` + `@tanstack/react-query` wiring (Query is already installed).
- Define a custom chain: id `4663`, name `Robinhood Chain`, RPC `https://rpc.mainnet.chain.robinhood.com`, native currency ETH, explorer `https://robinhoodchain.blockscout.com`.
- Wrap the app in a `WagmiProvider` inside `src/routes/__root.tsx` (client-only, so nothing breaks during SSR).
- A small `WalletButton` in a screen corner, outside the existing HUD layout, with states: Connect Wallet → shortened address → menu with Disconnect.
- If the connected wallet is on another network, show a "Switch to Robinhood Chain" prompt that calls switch/add chain.
- Connector: injected/browser wallet (MetaMask and similar).

## 2. Backend (Lovable Cloud)

Enable Cloud, then one migration creating `profiles`:

| column | type |
| --- | --- |
| wallet_address | text, primary key, stored lowercase |
| username | text, unique |
| display_name | text |
| avatar_url | text, nullable |
| level | integer, default 1 |
| fish_common / fish_rare / fish_epic / fish_legendary / fish_mythic | integer, default 0 |
| created_at / updated_at | timestamptz, default now() |

Plus: grants, RLS enabled, a public read policy (profiles are public game data), and **no** direct anon write policy — writes go through server functions so a wallet cannot overwrite someone else's row.

A public storage bucket `avatars` holds profile pictures.

Fish rarity columns are created only; nothing in gameplay writes to them yet.

## 3. Ownership: how we know the wallet is really the caller

A wallet address alone is not proof of identity. So:

- On connect, the client asks the wallet to sign a short message containing the address and a timestamp.
- Server functions verify that signature with viem before creating or updating the row, then write with elevated privileges.
- The signature is cached in the profile store for the session, so the user signs once, not on every save.
- Read paths (loading a profile, checking username availability) stay public and unsigned.

Server functions: `getProfile`, `ensureProfile` (auto-create with defaults on first connect), `updateProfile` (username/display name/avatar, with unique-username error surfaced), `uploadAvatar`.

## 4. Profile UI

- `useProfileStore` (zustand, separate from `useGameStore`): wallet address, chain status, profile row, signature, loading/saving flags.
- Profile icon button next to the wallet button; opens `ProfilePanel` as a modal dialog (shadcn Dialog).
- Panel contents: round avatar with default fallback and upload control, username input with inline "already taken" validation, display name input, read-only Level, and five rarity rows — Common, Rare, Epic, Legendary, Mythic — each with its count, then a Save button with success/error toasts (sonner Toaster mounted in root).

## 5. English localization

Every user-visible string becomes English; code comments and identifiers stay as they are.

- `HUD.tsx`: "Press SPACE to cast", Catches / Total / Latest, "! BITE !", control hints (WASD = move, SPACE = jump, ENTER / left click = cast & reel, E = board/leave boat, R = stow/draw rod, right click = rotate camera, scroll = zoom).
- `LoadingScreen.tsx`: "Loading the island…", subtitle, image alt text.
- `routes/index.tsx`: title, description, og:title, og:description (English, still unique and descriptive).
- `useGameStore.ts` species names → natural English: Mackerel, Red Snapper, Clownfish, Baby Tuna, Scad — and the monster as Ancient Leviathan. Only the display strings change; rarity/weight/logic untouched.
- `Weather.tsx` / `useWeather.ts` / `WorldEditor.tsx` and any other UI strings, plus `<html lang>` switched to `en`.
- Sweep for remaining Indonesian strings afterwards; all new profile UI is written in English from the start.

## Technical notes

- New packages: `wagmi`, `viem`.
- New files: `src/lib/chains.ts`, `src/lib/wagmi.ts`, `src/components/wallet/WalletButton.tsx`, `src/components/profile/ProfilePanel.tsx`, `src/hooks/useProfileStore.ts`, `src/lib/profile.functions.ts`.
- Wallet/profile UI renders outside the R3F canvas, layered over it — no changes to canvas internals or input handling; the profile modal disables game key handling while open only if that turns out to conflict.
