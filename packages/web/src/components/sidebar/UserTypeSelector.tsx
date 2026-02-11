'use client'

import { useAppStore } from '@/store/app-store'
import { Chip } from '@/components/ui/Chip'
import type { UserType } from '@parkatbalboa/shared'

const USER_OPTIONS: { type: UserType; label: string; icon: string }[] = [
  { type: 'resident', label: 'SD Resident', icon: '\u{1F3E0}' },
  { type: 'nonresident', label: 'Visitor', icon: '\u{1F30D}' },
  { type: 'staff', label: 'Staff', icon: '\u{1F4BC}' },
  { type: 'volunteer', label: 'Volunteer', icon: '\u{1F91D}' },
  { type: 'ada', label: 'ADA', icon: '\u267F' },
]

export function UserTypeSelector() {
  const userRoles = useAppStore((s) => s.userRoles)
  const activeCapacity = useAppStore((s) => s.activeCapacity)
  const hasPass = useAppStore((s) => s.hasPass)
  const toggleRole = useAppStore((s) => s.toggleRole)
  const setActiveCapacity = useAppStore((s) => s.setActiveCapacity)
  const setHasPass = useAppStore((s) => s.setHasPass)

  const activeOptions = USER_OPTIONS.filter((opt) =>
    userRoles.includes(opt.type),
  )

  return (
    <div>
      <label className="text-sm font-medium text-stone-700 mb-2 block">
        I am a...
      </label>
      <div className="flex flex-wrap gap-2">
        {USER_OPTIONS.map((opt) => (
          <Chip
            key={opt.type}
            label={opt.label}
            icon={opt.icon}
            selected={userRoles.includes(opt.type)}
            onClick={() => toggleRole(opt.type)}
          />
        ))}
      </div>

      {activeOptions.length > 1 && (
        <div className="mt-3">
          <label className="text-xs font-medium text-stone-500 mb-1.5 block">
            For this visit, I'm going as...
          </label>
          <div className="flex flex-wrap gap-1.5">
            {activeOptions.map((opt) => (
              <button
                key={opt.type}
                type="button"
                onClick={() => setActiveCapacity(opt.type)}
                className={`
                  inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-medium
                  transition-colors cursor-pointer border
                  ${
                    activeCapacity === opt.type
                      ? 'bg-park-green/10 text-park-green border-park-green'
                      : 'bg-stone-50 text-stone-500 border-stone-200 hover:border-stone-400'
                  }
                `}
              >
                <span>{opt.icon}</span>
                {opt.label}
              </button>
            ))}
          </div>
        </div>
      )}

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
