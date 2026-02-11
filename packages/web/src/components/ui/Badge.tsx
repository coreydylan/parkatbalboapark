import { CheckCircle } from 'lucide-react'

interface BadgeProps {
  cost: number
  label: string
}

export function Badge({ cost, label }: BadgeProps) {
  if (cost <= 0) {
    return (
      <span className="inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-bold text-park-green bg-park-green/10">
        <CheckCircle className="w-3 h-3" />
        {label}
      </span>
    )
  }

  let colorClasses: string
  if (cost <= 800) {
    colorClasses = 'bg-amber-50 text-amber-700'
  } else {
    colorClasses = 'bg-rose-50 text-rose-700'
  }

  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold ${colorClasses}`}
    >
      {label}
    </span>
  )
}
