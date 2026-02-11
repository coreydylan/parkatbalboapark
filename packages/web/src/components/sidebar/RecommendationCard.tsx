'use client'

import { useAppStore } from '@/store/app-store'
import { Badge } from '@/components/ui/Badge'
import type { ParkingRecommendation } from '@parkatbalboa/shared'

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

  function handleClick() {
    const lot = lots.find((l) => l.slug === rec.lotSlug) ?? null
    selectLot(isSelected ? null : lot)
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
        </div>
        <Badge cost={rec.costCents} label={rec.costDisplay} />
      </div>

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
