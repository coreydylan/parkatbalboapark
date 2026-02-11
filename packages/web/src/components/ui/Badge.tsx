interface BadgeProps {
  cost: number
  label: string
}

export function Badge({ cost, label }: BadgeProps) {
  let bgClass: string
  let textClass: string

  if (cost <= 0) {
    bgClass = 'bg-green-100'
    textClass = 'text-green-800'
  } else if (cost <= 800) {
    bgClass = 'bg-yellow-100'
    textClass = 'text-yellow-800'
  } else {
    bgClass = 'bg-red-100'
    textClass = 'text-red-800'
  }

  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold ${bgClass} ${textClass}`}
    >
      {label}
    </span>
  )
}
