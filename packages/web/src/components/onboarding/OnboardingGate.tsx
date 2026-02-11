'use client'

import { useOnboarding } from './useOnboarding'
import { OnboardingModal } from './OnboardingModal'

export function OnboardingGate() {
  const { showOnboarding, completeOnboarding } = useOnboarding()

  if (!showOnboarding) return null

  return <OnboardingModal onComplete={completeOnboarding} />
}
