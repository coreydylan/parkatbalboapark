'use client'

import { useState } from 'react'
import { useAppStore } from '@/store/app-store'
import type { UserType } from '@parkatbalboa/shared'

const TOTAL_STEPS = 5

const ROLE_LABELS: Record<string, string> = {
  resident: 'SD Resident',
  nonresident: 'Visitor',
  staff: 'Staff',
  volunteer: 'Volunteer',
  ada: 'ADA',
}

interface OnboardingModalProps {
  onComplete: () => void
}

export function OnboardingModal({ onComplete }: OnboardingModalProps) {
  const [step, setStep] = useState(0)
  const userRoles = useAppStore((s) => s.userRoles)
  const hasPass = useAppStore((s) => s.hasPass)
  const toggleRole = useAppStore((s) => s.toggleRole)
  const setHasPass = useAppStore((s) => s.setHasPass)

  const next = () => setStep((s) => Math.min(s + 1, TOTAL_STEPS - 1))
  const back = () => setStep((s) => Math.max(s - 1, 0))

  const hasRole = (role: UserType) => userRoles.includes(role)

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden flex flex-col max-h-[90vh]">
        {/* Progress dots */}
        <div className="flex justify-center gap-2 pt-6 pb-2">
          {Array.from({ length: TOTAL_STEPS }).map((_, i) => (
            <div
              key={i}
              className={`h-2 rounded-full transition-all duration-300 ${
                i === step
                  ? 'w-6 bg-park-green'
                  : i < step
                    ? 'w-2 bg-park-green/40'
                    : 'w-2 bg-stone-200'
              }`}
            />
          ))}
        </div>

        {/* Step content */}
        <div className="flex-1 px-6 py-6 overflow-y-auto">
          {step === 0 && <StepWelcome onStart={next} />}
          {step === 1 && (
            <StepResidency
              isResident={hasRole('resident')}
              hasPass={hasPass}
              onToggleResident={() => toggleRole('resident')}
              onTogglePass={(v) => setHasPass(v)}
            />
          )}
          {step === 2 && (
            <StepAffiliation
              isStaff={hasRole('staff')}
              isVolunteer={hasRole('volunteer')}
              onToggleStaff={() => toggleRole('staff')}
              onToggleVolunteer={() => toggleRole('volunteer')}
            />
          )}
          {step === 3 && (
            <StepAccessibility
              isAda={hasRole('ada')}
              onToggleAda={() => toggleRole('ada')}
            />
          )}
          {step === 4 && (
            <StepDone roles={userRoles} hasPass={hasPass} onFinish={onComplete} />
          )}
        </div>

        {/* Navigation */}
        {step > 0 && step < TOTAL_STEPS - 1 && (
          <div className="flex items-center justify-between px-6 pb-6">
            <button
              type="button"
              onClick={back}
              className="text-sm text-stone-500 hover:text-stone-700 transition-colors"
            >
              Back
            </button>
            <div className="flex gap-3">
              <button
                type="button"
                onClick={next}
                className="text-sm text-stone-400 hover:text-stone-600 transition-colors"
              >
                Skip
              </button>
              <button
                type="button"
                onClick={next}
                className="rounded-full bg-park-green px-5 py-2 text-sm font-medium text-white hover:bg-park-green/90 transition-colors"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

/* ------------------------------------------------------------------ */
/*  Step sub-components                                                */
/* ------------------------------------------------------------------ */

function StepWelcome({ onStart }: { onStart: () => void }) {
  return (
    <div className="flex flex-col items-center text-center gap-4">
      <div className="text-5xl">&#x1F17F;&#xFE0F;</div>
      <h2 className="text-xl font-semibold text-stone-800">
        Help us find your best parking at Balboa Park
      </h2>
      <p className="text-sm text-stone-500">
        Answer a few quick questions so we can show you the lots, rates, and
        tips that matter most.
      </p>
      <button
        type="button"
        onClick={onStart}
        className="mt-2 rounded-full bg-park-green px-8 py-3 text-sm font-medium text-white hover:bg-park-green/90 transition-colors"
      >
        Get started
      </button>
    </div>
  )
}

function StepResidency({
  isResident,
  hasPass,
  onToggleResident,
  onTogglePass,
}: {
  isResident: boolean
  hasPass: boolean
  onToggleResident: () => void
  onTogglePass: (v: boolean) => void
}) {
  return (
    <div className="flex flex-col gap-5">
      <h2 className="text-lg font-semibold text-stone-800">
        Are you a San Diego resident?
      </h2>
      <p className="text-sm text-stone-500">
        Residents often qualify for free or discounted parking.
      </p>
      <div className="flex gap-3">
        <ToggleButton
          label="Yes"
          active={isResident}
          onClick={() => { if (!isResident) onToggleResident() }}
        />
        <ToggleButton
          label="No"
          active={!isResident}
          onClick={() => { if (isResident) onToggleResident() }}
        />
      </div>
      {isResident && (
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={hasPass}
            onChange={(e) => onTogglePass(e.target.checked)}
            className="w-4 h-4 rounded border-stone-300 text-park-green focus:ring-park-green"
          />
          <span className="text-sm text-stone-600">I have a parking pass</span>
        </label>
      )}
    </div>
  )
}

function StepAffiliation({
  isStaff,
  isVolunteer,
  onToggleStaff,
  onToggleVolunteer,
}: {
  isStaff: boolean
  isVolunteer: boolean
  onToggleStaff: () => void
  onToggleVolunteer: () => void
}) {
  return (
    <div className="flex flex-col gap-5">
      <h2 className="text-lg font-semibold text-stone-800">
        Do you work or volunteer at Balboa Park?
      </h2>
      <p className="text-sm text-stone-500">
        Staff and volunteers have access to reserved lots with special rates.
      </p>
      <div className="flex flex-col gap-3">
        <ToggleRow label="Staff" active={isStaff} onToggle={onToggleStaff} />
        <ToggleRow label="Volunteer" active={isVolunteer} onToggle={onToggleVolunteer} />
      </div>
    </div>
  )
}

function StepAccessibility({
  isAda,
  onToggleAda,
}: {
  isAda: boolean
  onToggleAda: () => void
}) {
  return (
    <div className="flex flex-col gap-5">
      <h2 className="text-lg font-semibold text-stone-800">
        Do you have an ADA placard or plate?
      </h2>
      <p className="text-sm text-stone-500">
        We will highlight accessible parking spaces nearest your destination.
      </p>
      <div className="flex gap-3">
        <ToggleButton
          label="Yes"
          active={isAda}
          onClick={() => { if (!isAda) onToggleAda() }}
        />
        <ToggleButton
          label="No"
          active={!isAda}
          onClick={() => { if (isAda) onToggleAda() }}
        />
      </div>
    </div>
  )
}

function StepDone({
  roles,
  hasPass,
  onFinish,
}: {
  roles: UserType[]
  hasPass: boolean
  onFinish: () => void
}) {
  return (
    <div className="flex flex-col items-center text-center gap-4">
      <div className="text-5xl">&#x2705;</div>
      <h2 className="text-xl font-semibold text-stone-800">You're all set!</h2>
      {roles.length > 0 ? (
        <div className="flex flex-wrap justify-center gap-2">
          {roles.map((r) => (
            <span
              key={r}
              className="inline-flex items-center rounded-full bg-park-green/10 px-3 py-1 text-sm font-medium text-park-green"
            >
              {ROLE_LABELS[r] ?? r}
            </span>
          ))}
          {hasPass && (
            <span className="inline-flex items-center rounded-full bg-park-green/10 px-3 py-1 text-sm font-medium text-park-green">
              Parking Pass
            </span>
          )}
        </div>
      ) : (
        <p className="text-sm text-stone-500">
          No preferences selected — you can always update these later in the
          sidebar.
        </p>
      )}
      <button
        type="button"
        onClick={onFinish}
        className="mt-2 rounded-full bg-park-green px-8 py-3 text-sm font-medium text-white hover:bg-park-green/90 transition-colors"
      >
        Start exploring
      </button>
    </div>
  )
}

/* ------------------------------------------------------------------ */
/*  Shared small components                                            */
/* ------------------------------------------------------------------ */

function ToggleButton({
  label,
  active,
  onClick,
}: {
  label: string
  active: boolean
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex-1 rounded-xl border py-3 text-sm font-medium transition-colors ${
        active
          ? 'bg-park-green text-white border-park-green'
          : 'bg-white text-stone-600 border-stone-300 hover:border-park-green hover:text-park-green'
      }`}
    >
      {label}
    </button>
  )
}

function ToggleRow({
  label,
  active,
  onToggle,
}: {
  label: string
  active: boolean
  onToggle: () => void
}) {
  return (
    <button
      type="button"
      onClick={onToggle}
      className={`flex items-center justify-between rounded-xl border px-4 py-3 text-sm font-medium transition-colors ${
        active
          ? 'bg-park-green/10 text-park-green border-park-green'
          : 'bg-white text-stone-600 border-stone-300 hover:border-park-green'
      }`}
    >
      <span>{label}</span>
      <span
        className={`inline-block w-10 h-6 rounded-full relative transition-colors ${
          active ? 'bg-park-green' : 'bg-stone-300'
        }`}
      >
        <span
          className={`absolute top-1 h-4 w-4 rounded-full bg-white transition-transform ${
            active ? 'translate-x-5' : 'translate-x-1'
          }`}
        />
      </span>
    </button>
  )
}
