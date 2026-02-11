'use client'

import type { ReactNode } from 'react'
import { useAppStore } from '@/store/app-store'
import { Chip } from '@/components/ui/Chip'
import type { UserType } from '@parkatbalboa/shared'
import { UserCircle, Briefcase, Heart, Accessibility, Ticket } from 'lucide-react'

const USER_OPTIONS: { type: UserType; label: string; icon: ReactNode }[] = [
  { type: 'resident', label: 'SD Resident', icon: <UserCircle className="w-4 h-4" /> },
  { type: 'nonresident', label: 'Visitor', icon: <UserCircle className="w-4 h-4" /> },
  { type: 'staff', label: 'Staff', icon: <Briefcase className="w-4 h-4" /> },
  { type: 'volunteer', label: 'Volunteer', icon: <Heart className="w-4 h-4" /> },
  { type: 'ada', label: 'ADA', icon: <Accessibility className="w-4 h-4" /> },
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
      <label className="text-base font-semibold text-stone-800 mb-3 block">
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
        <div className="mt-3 bg-stone-50 rounded-xl p-3">
          <label className="text-xs font-semibold text-stone-500 mb-2 block">
            For this visit, I&apos;m going as...
          </label>
          <div className="flex flex-wrap gap-2">
            {activeOptions.map((opt) => (
              <button
                key={opt.type}
                type="button"
                onClick={() => setActiveCapacity(opt.type)}
                className={`
                  inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-medium
                  transition-all duration-200 cursor-pointer border
                  ${
                    activeCapacity === opt.type
                      ? 'bg-park-green/10 text-park-green border-park-green/30 shadow-sm'
                      : 'bg-white text-stone-500 border-stone-200 hover:border-stone-300'
                  }
                `}
              >
                <span className="flex items-center [&>svg]:w-3.5 [&>svg]:h-3.5">{opt.icon}</span>
                {opt.label}
              </button>
            ))}
          </div>
        </div>
      )}

      <label className="flex items-center gap-3 mt-3 cursor-pointer group">
        <div className="relative inline-flex items-center">
          <input
            type="checkbox"
            checked={hasPass}
            onChange={(e) => setHasPass(e.target.checked)}
            className="sr-only peer"
          />
          <div className="w-9 h-5 bg-stone-200 rounded-full peer-checked:bg-park-green transition-all duration-200" />
          <div className="absolute top-0.5 left-0.5 w-4 h-4 bg-white rounded-full shadow-sm transition-all duration-200 peer-checked:translate-x-4" />
        </div>
        <span className="flex items-center gap-1.5 text-sm text-stone-600 group-hover:text-stone-800 transition-colors duration-200">
          <Ticket className="w-4 h-4 text-stone-400" />
          I have a parking pass
        </span>
      </label>
    </div>
  )
}
