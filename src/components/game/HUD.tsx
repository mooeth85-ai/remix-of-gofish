import { useGameStore } from "@/hooks/useGameStore";
import type { Rarity } from "@/lib/fishRules";

const RARITY_BADGE: Record<Rarity, string> = {
  common: "border-slate-400/40 bg-slate-400/20 text-slate-100",
  rare: "border-sky-400/50 bg-sky-500/20 text-sky-100",
  epic: "border-violet-400/50 bg-violet-500/20 text-violet-100",
  legendary: "border-orange-400/50 bg-orange-500/20 text-orange-100",
  mythic: "border-amber-300/60 bg-gradient-to-r from-amber-500/30 to-red-500/30 text-amber-100",
};

export function HUD() {
  const { phase, message, score, totalWeight, last } = useGameStore();
  const bite = phase === "bite";
  const rarity = (last?.isMonster ? "mythic" : last?.rarity) as Rarity | undefined;


  return (
    <div className="pointer-events-none fixed inset-0 z-10 select-none">
      {phase === "caught" && last?.isMonster && (
        <div
          key={score}
          className="animate-monster-flash fixed inset-0 z-50"
          aria-hidden="true"
        />
      )}
      <div className="flex items-start justify-between p-4 sm:p-6">
        <div className="rounded-2xl border border-white/25 bg-slate-900/45 px-4 py-3 text-slate-50 shadow-lg backdrop-blur-md">
          <h1 className="text-base font-semibold tracking-tight sm:text-lg">Fishing Island</h1>
          <p className="mt-1 text-xs text-slate-200/80">
            Caught <span className="font-semibold text-slate-50">{score}</span> · Total{" "}
            <span className="font-semibold text-slate-50">{totalWeight} kg</span>
          </p>
        </div>

        <div className="flex flex-col items-end gap-2">
          {last && (
            <div className="rounded-2xl border border-white/25 bg-slate-900/45 px-4 py-3 text-right text-slate-50 shadow-lg backdrop-blur-md">
              <p className="text-[11px] uppercase tracking-widest text-slate-300/80">Latest</p>
              <p className="text-sm font-semibold">{last.name}</p>
              <p className="text-xs text-slate-200/80">{last.weight} kg</p>
              {rarity && (
                <span
                  className={`mt-1 inline-block rounded-full border px-2 py-0.5 text-[10px] font-semibold uppercase tracking-widest ${RARITY_BADGE[rarity]}`}
                >
                  {rarity}
                </span>
              )}

            </div>
          )}
        </div>
      </div>

      <div className="absolute inset-x-0 bottom-6 flex flex-col items-center gap-3 px-4">
        {bite && (
          <div className="animate-pulse rounded-full bg-red-500/90 px-6 py-2 text-lg font-bold tracking-wide text-white shadow-xl">
            ! BITE !
          </div>
        )}
        <div className="rounded-full border border-white/25 bg-slate-900/50 px-5 py-2 text-center text-sm text-slate-50 shadow-lg backdrop-blur-md">
          {message}
        </div>
        <p className="text-[11px] text-slate-900/60">
          WASD = move · SPACE = jump · ENTER / left click = cast &amp; reel · E = board/leave boat · R = stow/draw rod · right click = rotate
          camera · scroll = zoom
        </p>
      </div>
    </div>
  );
}
