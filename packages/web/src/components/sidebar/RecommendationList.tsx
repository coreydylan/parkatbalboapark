'use client'

import { useAppStore } from '@/store/app-store'
import { RecommendationCard } from './RecommendationCard'
import { Sparkles, ShieldAlert, CircleParking, Search } from 'lucide-react'

export function RecommendationList() {
  const recommendations = useAppStore((s) => s.recommendations)
  const isLoading = useAppStore((s) => s.isLoading)
  const userType = useAppStore((s) => s.userType)
  const enforcementActive = useAppStore((s) => s.enforcementActive)

  if (!userType) {
    return (
      <div className="text-center py-10">
        <div className="text-stone-200 mb-3">
          <CircleParking className="w-12 h-12 mx-auto" strokeWidth={1.5} />
        </div>
        <p className="text-sm text-stone-400">
          Select who you are and where you&apos;re going
        </p>
        <p className="text-xs text-stone-300 mt-1">
          We&apos;ll find the best parking for you
        </p>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div>
        <div className="flex items-center justify-between mb-3">
          <h3 className="flex items-center gap-2 text-lg font-semibold text-stone-800">
            <Sparkles className="w-4 h-4 text-park-gold" />
            Recommended Parking
          </h3>
        </div>
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="rounded-2xl border border-stone-100 bg-white p-4 animate-pulse"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div className="h-7 w-7 bg-stone-200 rounded-full" />
                  <div className="h-5 bg-stone-200 rounded-lg w-28" />
                </div>
                <div className="h-5 bg-stone-200 rounded-full w-14" />
              </div>
              <div className="flex gap-4">
                <div className="h-4 bg-stone-100 rounded-lg w-20" />
                <div className="h-4 bg-stone-100 rounded-lg w-24" />
              </div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <h3 className="flex items-center gap-2 text-lg font-semibold text-stone-800">
          <Sparkles className="w-4 h-4 text-park-gold" />
          Recommended Parking
        </h3>
        <div className="flex items-center gap-2">
          {enforcementActive ? (
            <span className="inline-flex items-center gap-1 text-xs font-medium text-amber-700 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-full">
              <ShieldAlert className="w-3 h-3" />
              Enforcement active
            </span>
          ) : (
            <span className="inline-flex items-center gap-1 text-xs font-medium text-park-green bg-park-green/10 px-2 py-0.5 rounded-full">
              Free parking hours
            </span>
          )}
          <span className="text-xs text-stone-400">
            {recommendations.length} lot{recommendations.length !== 1 ? 's' : ''}
          </span>
        </div>
      </div>

      {recommendations.length === 0 ? (
        <div className="text-center py-10">
          <Search className="w-10 h-10 mx-auto text-stone-200 mb-3" strokeWidth={1.5} />
          <p className="text-sm text-stone-400">
            No parking recommendations available
          </p>
          <p className="text-xs text-stone-300 mt-1">
            Try adjusting your destination or visit details
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {recommendations.map((rec, index) => (
            <RecommendationCard key={rec.lotSlug} recommendation={rec} rank={index + 1} />
          ))}
        </div>
      )}
    </div>
  )
}
