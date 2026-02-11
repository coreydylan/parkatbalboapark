import { create } from 'zustand'
import type {
  UserType,
  Destination,
  ParkingLot,
  ParkingRecommendation,
} from '@parkatbalboa/shared'

export interface Waypoint {
  id: string
  name: string
  category: string
  lat: number
  lng: number
  onOfficialMap: boolean
}

interface AppState {
  // User selections — multi-role profile
  userRoles: UserType[]
  activeCapacity: UserType | null
  userType: UserType | null // Derived from activeCapacity — kept for backward compat
  hasPass: boolean
  selectedDestination: Destination | null
  visitHours: number

  // Data
  lots: ParkingLot[]
  destinations: Destination[]
  waypoints: Waypoint[]
  recommendations: ParkingRecommendation[]
  selectedLot: ParkingLot | null

  // UI state
  isLoading: boolean
  enforcementActive: boolean
  mapCenter: [number, number]
  mapZoom: number
  sidebarOpen: boolean
  mapFilters: Record<string, boolean>

  // Internal
  _abortController: AbortController | null

  // Actions
  toggleRole: (type: UserType) => void
  setActiveCapacity: (type: UserType) => void
  setUserType: (type: UserType) => void // Legacy — calls toggleRole + setActiveCapacity
  setHasPass: (hasPass: boolean) => void
  setDestination: (dest: Destination | null) => void
  setVisitHours: (hours: number) => void
  selectLot: (lot: ParkingLot | null) => void
  setMapView: (center: [number, number], zoom: number) => void
  fetchLots: () => Promise<void>
  fetchDestinations: () => Promise<void>
  fetchWaypoints: () => Promise<void>
  fetchRecommendations: () => Promise<void>
  fetchEnforcement: () => Promise<void>
  toggleMapFilter: (key: string) => void
}

export const useAppStore = create<AppState>((set, get) => ({
  // Default state — multi-role profile
  userRoles: [],
  activeCapacity: null,
  userType: null,
  hasPass: false,
  selectedDestination: null,
  visitHours: 2,

  lots: [],
  destinations: [],
  waypoints: [],
  recommendations: [],
  selectedLot: null,

  isLoading: false,
  enforcementActive: false,
  mapCenter: [-117.1446, 32.7341],
  mapZoom: 14.5,
  sidebarOpen: true,
  mapFilters: {
    tram: true,
    restrooms: false,
    water: false,
    ev_charging: false,
  },
  _abortController: null,

  // Actions
  toggleRole: (type) => {
    const { userRoles, activeCapacity } = get()
    const has = userRoles.includes(type)

    if (has) {
      // Remove role
      const next = userRoles.filter((r) => r !== type)
      const nextCapacity =
        activeCapacity === type ? next[0] ?? null : activeCapacity
      set({
        userRoles: next,
        activeCapacity: nextCapacity,
        userType: nextCapacity,
      })
    } else {
      // Add role
      const next = [...userRoles, type]
      const nextCapacity = next.length === 1 ? type : (activeCapacity ?? type)
      set({
        userRoles: next,
        activeCapacity: nextCapacity,
        userType: nextCapacity,
      })
    }
    get().fetchRecommendations()
  },

  setActiveCapacity: (type) => {
    set({ activeCapacity: type, userType: type })
    get().fetchRecommendations()
  },

  // Legacy — kept so any code calling setUserType still works
  setUserType: (type) => {
    const { userRoles } = get()
    if (!userRoles.includes(type)) {
      set({ userRoles: [...userRoles, type] })
    }
    set({ activeCapacity: type, userType: type })
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

  fetchWaypoints: async () => {
    try {
      const res = await fetch('/api/waypoints')
      if (!res.ok) return
      const data = await res.json()
      set({ waypoints: data.waypoints ?? [] })
    } catch {
      // silently fail
    }
  },

  fetchRecommendations: async () => {
    const { userType, selectedDestination, hasPass, visitHours } = get()
    if (!userType) return

    // Cancel any in-flight request
    const prev = get()._abortController
    if (prev) prev.abort()
    const controller = new AbortController()
    set({ _abortController: controller, isLoading: true })

    try {
      const params = new URLSearchParams({
        user_type: userType,
        has_pass: String(hasPass),
        visit_hours: String(visitHours),
      })
      if (selectedDestination) {
        params.set('destination', selectedDestination.slug)
      }

      const res = await fetch(`/api/recommend?${params}`, {
        signal: controller.signal,
      })
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
    } catch (err) {
      if (err instanceof DOMException && err.name === 'AbortError') return
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

  toggleMapFilter: (key) => {
    const { mapFilters } = get()
    set({ mapFilters: { ...mapFilters, [key]: !mapFilters[key] } })
  },
}))
