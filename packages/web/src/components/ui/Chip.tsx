'use client'

import type { ReactNode } from 'react'

interface ChipProps {
  label: string
  selected: boolean
  onClick: () => void
  icon?: ReactNode
}

export function Chip({ label, selected, onClick, icon }: ChipProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`
        inline-flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm font-medium
        transition-all duration-200 cursor-pointer
        ${
          selected
            ? 'bg-park-green text-white border-park-green shadow-sm'
            : 'bg-white text-stone-600 border-stone-200 hover:border-stone-300 hover:bg-stone-50'
        }
      `}
    >
      {icon && <span className="flex items-center justify-center [&>svg]:w-4 [&>svg]:h-4">{icon}</span>}
      {label}
    </button>
  )
}
