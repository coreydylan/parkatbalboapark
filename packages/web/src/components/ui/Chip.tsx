'use client'

interface ChipProps {
  label: string
  selected: boolean
  onClick: () => void
  icon?: string
}

export function Chip({ label, selected, onClick, icon }: ChipProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`
        inline-flex items-center gap-1.5 rounded-full border px-4 py-2 text-sm font-medium
        transition-colors cursor-pointer
        ${
          selected
            ? 'bg-park-green text-white border-park-green'
            : 'bg-white text-stone-700 border-stone-300 hover:border-park-green hover:text-park-green'
        }
      `}
    >
      {icon && <span className="text-base">{icon}</span>}
      {label}
    </button>
  )
}
