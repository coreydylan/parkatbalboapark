'use client'

import { useAppStore } from '@/store/app-store'
import { Chip } from '@/components/ui/Chip'
import { Clock } from 'lucide-react'

const DURATION_OPTIONS: { hours: number; label: string }[] = [
  { hours: 1, label: '1 hr' },
  { hours: 2, label: '2 hr' },
  { hours: 3, label: '3 hr' },
  { hours: 4, label: '4 hr' },
  { hours: 8, label: 'All Day' },
]

export function VisitDurationPicker() {
  const visitHours = useAppStore((s) => s.visitHours)
  const setVisitHours = useAppStore((s) => s.setVisitHours)

  return (
    <div>
      <div className="border-t border-stone-100 pt-4 -mt-1" />
      <label className="flex items-center gap-2 text-base font-semibold text-stone-800 mb-3">
        <Clock className="w-4 h-4 text-stone-400" />
        How long will you visit?
      </label>
      <div className="flex flex-wrap gap-2">
        {DURATION_OPTIONS.map((opt) => (
          <Chip
            key={opt.hours}
            label={opt.label}
            selected={visitHours === opt.hours}
            onClick={() => setVisitHours(opt.hours)}
          />
        ))}
      </div>
      <div className="border-b border-stone-100 pb-0 mt-4" />
    </div>
  )
}
