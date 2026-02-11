'use client'

import { useMemo } from 'react'
import { useAppStore } from '@/store/app-store'
import { Badge } from '@/components/ui/Badge'
import { TIER_NAMES } from '@parkatbalboa/shared'
import type { ParkingRecommendation, LotTier } from '@parkatbalboa/shared'
import { PersonStanding, TramFront, Accessibility, Zap, Info } from 'lucide-react'

const TIER_STYLE: Record<LotTier, string> = {
  0: 'bg-park-green/10 text-park-green',
  1: 'bg-amber-50 text-amber-700',
  2: 'bg-blue-50 text-blue-700',
  3: 'bg-stone-100 text-stone-600',
}

function deriveFreeReason(tips: string[]): string | null {
  for (const tip of tips) {
    const lower = tip.toLowerCase()
    if (lower.includes('resident')) return 'Free -- resident parking'
    if (lower.includes('enforce') || lower.includes('hours'))
      return 'Free -- outside enforcement hours'
    if (lower.includes('free lot')) return 'Free -- no-cost lot'
    if (lower.includes('pass')) return 'Free -- valid pass'
  }
  return 'Free parking'
}

interface RecommendationCardProps {
  recommendation: ParkingRecommendation
  rank: number
}

export function RecommendationCard({
  recommendation: rec,
  rank,
}: RecommendationCardProps) {
  const selectedLot = useAppStore((s) => s.selectedLot)
  const lots = useAppStore((s) => s.lots)
  const selectLot = useAppStore((s) => s.selectLot)

  const isSelected = selectedLot?.slug === rec.lotSlug
  const lot = useMemo(() => lots.find((l) => l.slug === rec.lotSlug), [lots, rec.lotSlug])
  const tierStyle = TIER_STYLE[rec.tier]
  const isTopThree = rank <= 3

  function handleClick() {
    selectLot(isSelected ? null : lot ?? null)
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      className={`
        w-full text-left rounded-2xl border p-4 transition-all duration-200 cursor-pointer
        hover:shadow-md bg-white
        ${
          isSelected
            ? 'ring-2 ring-park-green border-park-green/30 shadow-md'
            : 'border-stone-100 shadow-sm'
        }
      `}
    >
      <div className="flex items-start justify-between mb-2">
        <div className="flex items-center gap-2">
          <span
            className={`
              text-xs font-bold w-7 h-7 flex items-center justify-center rounded-full shrink-0
              ${isTopThree ? 'bg-park-green text-white' : 'bg-stone-200 text-stone-600'}
            `}
          >
            {rank}
          </span>
          <div className="flex items-center gap-2 flex-wrap">
            <h4 className="font-semibold text-stone-800 text-base leading-tight">
              {rec.lotDisplayName}
            </h4>
            <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${tierStyle}`}>
              {TIER_NAMES[rec.tier]}
            </span>
          </div>
        </div>
        <Badge cost={rec.costCents} label={rec.costDisplay} />
      </div>

      {rec.isFree && (
        <div className="bg-park-green/5 rounded-lg px-2 py-1 mb-2 inline-flex items-center gap-1">
          <Info className="w-3 h-3 text-park-green" />
          <span className="text-xs text-park-green font-medium">
            {deriveFreeReason(rec.tips)}
          </span>
        </div>
      )}

      <div className="flex items-center gap-3 text-sm text-stone-500 mb-2 flex-wrap">
        {rec.walkingTimeDisplay && (
          <span className="flex items-center gap-1">
            <PersonStanding className="w-3.5 h-3.5" />
            {rec.walkingTimeDisplay}
          </span>
        )}

        {rec.hasTram && (
          <span className="flex items-center gap-1 text-park-gold">
            <TramFront className="w-3.5 h-3.5" />
            Tram available
          </span>
        )}

        {lot?.hasAdaSpaces && (
          <span className="flex items-center gap-1 text-blue-600" title="ADA accessible spaces">
            <Accessibility className="w-3.5 h-3.5" />
            ADA
          </span>
        )}

        {lot?.hasEvCharging && (
          <span className="flex items-center gap-1 text-emerald-600" title="EV charging available">
            <Zap className="w-3.5 h-3.5" />
            EV
          </span>
        )}
      </div>

      {rec.tips.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {rec.tips.slice(0, 2).map((tip, i) => (
            <span
              key={i}
              className="inline-flex items-center text-[11px] text-stone-500 bg-stone-50 rounded-full px-2 py-0.5"
            >
              {tip}
            </span>
          ))}
        </div>
      )}
    </button>
  )
}
