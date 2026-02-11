'use client'

import { useAppStore } from '@/store/app-store'
import { Chip } from '@/components/ui/Chip'

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
      <label className="text-sm font-medium text-stone-700 mb-2 block">
        How long will you be visiting?
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
    </div>
  )
}
