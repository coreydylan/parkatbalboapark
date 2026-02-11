'use client'

import { useState, useEffect } from 'react'
import { useAppStore } from '@/store/app-store'

const STORAGE_KEY = 'balboa_onboarding_complete'

export function useOnboarding() {
  const [showOnboarding, setShowOnboarding] = useState(false)
  const userRoles = useAppStore((s) => s.userRoles)

  useEffect(() => {
    const done = localStorage.getItem(STORAGE_KEY)
    if (!done && userRoles.length === 0) {
      setShowOnboarding(true)
    }
  }, [userRoles.length])

  function completeOnboarding() {
    localStorage.setItem(STORAGE_KEY, 'true')
    setShowOnboarding(false)
  }

  return { showOnboarding, completeOnboarding }
}
