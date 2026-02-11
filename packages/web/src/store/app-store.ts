import { create } from 'zustand'
import type {
  UserType,
  Destination,
  ParkingLot,
  ParkingRecommendation,
} from '@parkatbalboa/shared'

interface AppState {
  // User selections
  userType: UserType | null
  hasPass: boolean
  selectedDestination: Destination | null
  visitHours: number

  // Data
  lots: ParkingLot[]
  destinations: Destination[]
  recommendations: ParkingRecommendation[]
  selectedLot: ParkingLot | null

  // UI state
  isLoading: boolean
  enforcementActive: boolean
  mapCenter: [number, number]
  mapZoom: number
  sidebarOpen: boolean

  // Actions
  setUserType: (type: UserType) => void
  setHasPass: (hasPass: boolean) => void
  setDestination: (dest: Destination | null) => void
  setVisitHours: (hours: number) => void
  selectLot: (lot: ParkingLot | null) => void
  setMapView: (center: [number, number], zoom: number) => void
  fetchLots: () => Promise<void>
  fetchDestinations: () => Promise<void>
  fetchRecommendations: () => Promise<void>
  fetchEnforcement: () => Promise<void>
}

export const useAppStore = create<AppState>((set, get) => ({
  // Default state
  userType: null,
  hasPass: false,
  selectedDestination: null,
  visitHours: 2,

  lots: [],
  destinations: [],
  recommendations: [],
  selectedLot: null,

  isLoading: false,
  enforcementActive: false,
  mapCenter: [-117.1446, 32.7341],
  mapZoom: 14.5,
  sidebarOpen: true,

  // Actions
  setUserType: (type) => {
    set({ userType: type })
    get().fetchRecommendations()
  },

  setHasPass: (hasPass) => {
    set({ hasPass })
    get().fetchRecommendations()
  },

  setDestination: (dest) => {
    set({ selectedDestination: dest, selectedLot: null })
    get().fetchRecommendations()
  },

  setVisitHours: (hours) => {
    set({ visitHours: hours })
    get().fetchRecommendations()
  },

  selectLot: (lot) => {
    set({ selectedLot: lot })
    if (lot) {
      set({ mapCenter: [lot.lng, lot.lat], mapZoom: 16 })
    }
  },

  setMapView: (center, zoom) => {
    set({ mapCenter: center, mapZoom: zoom })
  },

  fetchLots: async () => {
    try {
      const res = await fetch('/api/lots')
      if (!res.ok) return
      const data = await res.json()
      set({ lots: data.lots ?? data })
    } catch {
      // silently fail — data will be empty
    }
  },

  fetchDestinations: async () => {
    try {
      const res = await fetch('/api/destinations')
      if (!res.ok) return
      const data = await res.json()
      set({ destinations: data.destinations ?? data })
    } catch {
      // silently fail
    }
  },

  fetchRecommendations: async () => {
    const { userType, selectedDestination, hasPass, visitHours } = get()
    if (!userType) return

    set({ isLoading: true })

    try {
      const params = new URLSearchParams({
        user_type: userType,
        has_pass: String(hasPass),
        visit_hours: String(visitHours),
      })
      if (selectedDestination) {
        params.set('destination', selectedDestination.slug)
      }

      const res = await fetch(`/api/recommend?${params}`)
      if (!res.ok) {
        set({ isLoading: false })
        return
      }
      const data = await res.json()
      set({
        recommendations: data.recommendations ?? [],
        enforcementActive: data.enforcementActive ?? false,
        isLoading: false,
      })
    } catch {
      set({ isLoading: false })
    }
  },

  fetchEnforcement: async () => {
    try {
      const res = await fetch('/api/enforcement')
      if (!res.ok) return
      const data = await res.json()
      set({ enforcementActive: data.active ?? false })
    } catch {
      // silently fail
    }
  },
}))
