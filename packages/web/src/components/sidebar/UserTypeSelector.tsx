'use client'

import { useAppStore } from '@/store/app-store'
import { Chip } from '@/components/ui/Chip'
import type { UserType } from '@parkatbalboa/shared'

const USER_OPTIONS: { type: UserType; label: string; icon: string }[] = [
  { type: 'resident', label: 'SD Resident', icon: '\u{1F3E0}' },
  { type: 'nonresident', label: 'Visitor', icon: '\u{1F30D}' },
  { type: 'staff', label: 'Staff / Volunteer', icon: '\u{1F4BC}' },
  { type: 'ada', label: 'ADA / Disabled', icon: '\u267F' },
]

export function UserTypeSelector() {
  const userType = useAppStore((s) => s.userType)
  const hasPass = useAppStore((s) => s.hasPass)
  const setUserType = useAppStore((s) => s.setUserType)
  const setHasPass = useAppStore((s) => s.setHasPass)

  return (
    <div>
      <label className="text-sm font-medium text-stone-700 mb-2 block">
        I am a...
      </label>
      <div className="grid grid-cols-2 gap-2">
        {USER_OPTIONS.map((opt) => (
          <Chip
            key={opt.type}
            label={opt.label}
            icon={opt.icon}
            selected={userType === opt.type}
            onClick={() => setUserType(opt.type)}
          />
        ))}
      </div>
      <label className="flex items-center gap-2 mt-3 cursor-pointer">
        <input
          type="checkbox"
          checked={hasPass}
          onChange={(e) => setHasPass(e.target.checked)}
          className="w-4 h-4 rounded border-stone-300 text-park-green focus:ring-park-green"
        />
        <span className="text-sm text-stone-600">I have a parking pass</span>
      </label>
    </div>
  )
}
