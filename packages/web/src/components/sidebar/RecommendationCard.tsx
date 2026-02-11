'use client'

import { useMemo } from 'react'
import { useAppStore } from '@/store/app-store'
import { Badge } from '@/components/ui/Badge'
import { TIER_NAMES } from '@parkatbalboa/shared'
import type { ParkingRecommendation, LotTier } from '@parkatbalboa/shared'

const TIER_STYLE: Record<LotTier, { bg: string; text: string }> = {
  0: { bg: 'bg-green-100', text: 'text-green-700' },
  1: { bg: 'bg-red-100', text: 'text-red-700' },
  2: { bg: 'bg-amber-100', text: 'text-amber-700' },
  3: { bg: 'bg-blue-100', text: 'text-blue-700' },
}

function deriveFreeReason(tips: string[]): string | null {
  for (const tip of tips) {
    const lower = tip.toLowerCase()
    if (lower.includes('resident')) return 'Free — resident parking'
    if (lower.includes('enforce') || lower.includes('hours'))
      return 'Free — outside enforcement hours'
    if (lower.includes('free lot')) return 'Free — no-cost lot'
    if (lower.includes('pass')) return 'Free — valid pass'
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

  function handleClick() {
    selectLot(isSelected ? null : lot ?? null)
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      className={`
        w-full text-left rounded-xl border p-4 transition-all cursor-pointer
        hover:shadow-md
        ${
          isSelected
            ? 'ring-2 ring-park-green border-park-green shadow-md'
            : 'border-stone-200 shadow-sm'
        }
      `}
    >
      <div className="flex items-start justify-between mb-2">
        <div className="flex items-center gap-2">
          <span className="text-xs font-bold text-stone-400 w-5 h-5 flex items-center justify-center bg-stone-100 rounded-full">
            {rank}
          </span>
          <h4 className="font-semibold text-stone-800 text-sm">
            {rec.lotDisplayName}
          </h4>
          <span className={`text-[10px] font-medium px-1.5 py-0.5 rounded-full ${tierStyle.bg} ${tierStyle.text}`}>
            {TIER_NAMES[rec.tier]}
          </span>
        </div>
        <Badge cost={rec.costCents} label={rec.costDisplay} />
      </div>

      {rec.isFree && (
        <p className="text-xs text-green-600 mb-1.5">
          {deriveFreeReason(rec.tips)}
        </p>
      )}

      <div className="flex items-center gap-3 text-xs text-stone-500 mb-2">
        {rec.walkingTimeDisplay && (
          <span className="flex items-center gap-1">
            <svg
              className="w-3.5 h-3.5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M13 4v3.5l2 2" />
              <circle cx="13" cy="3" r="1" />
              <path d="M7 21l3-7" />
              <path d="M10 14l-2-2.5" />
              <path d="M17 21l-2-5" />
              <path d="m15 16-1.5-3.5" />
            </svg>
            {rec.walkingTimeDisplay}
          </span>
        )}

        {rec.hasTram && (
          <span className="flex items-center gap-1 text-orange-600">
            <svg
              className="w-3.5 h-3.5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <rect x="4" y="3" width="16" height="14" rx="2" />
              <path d="M8 21h8" />
              <path d="m12 17 0 4" />
              <path d="M8 3v4" />
              <path d="M16 3v4" />
              <line x1="4" y1="10" x2="20" y2="10" />
            </svg>
            Tram available
          </span>
        )}

        {lot?.hasAdaSpaces && (
          <span className="flex items-center gap-1 text-blue-600" title="ADA accessible spaces">
            <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2a3 3 0 1 1 0 6 3 3 0 0 1 0-6Zm-1 8h2l1 5h3l1 2h-5l-.5-2H8.5a4.5 4.5 0 1 1 0-9h1v2h-1a2.5 2.5 0 1 0 0 5h2.5L11 10Z" />
            </svg>
            ADA
          </span>
        )}

        {lot?.hasEvCharging && (
          <span className="flex items-center gap-1 text-emerald-600" title="EV charging available">
            <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
            </svg>
            EV
          </span>
        )}
      </div>

      {rec.tips.length > 0 && (
        <div className="space-y-0.5">
          {rec.tips.slice(0, 2).map((tip, i) => (
            <p key={i} className="text-xs text-stone-400">
              {tip}
            </p>
          ))}
        </div>
      )}
    </button>
  )
}
