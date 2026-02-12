'use client'

import { useRef, useEffect, useState } from 'react'
import mapboxgl from 'mapbox-gl'
import { useAppStore } from '@/store/app-store'
import { MAPBOX_TOKEN, DEFAULT_CENTER, DEFAULT_ZOOM, MAP_STYLE } from '@/lib/mapbox'
import { useTramLayers } from './hooks/useTramLayers'
import { useLotLayers } from './hooks/useLotLayers'
import { useWalkingRoute } from './hooks/useWalkingRoute'
import { useLotPopup } from './hooks/useLotPopup'
import { useWaypointLayers } from './hooks/useWaypointLayers'
import { useStreetMeterLayers } from './hooks/useStreetMeterLayers'
import { useStreetMeterPopup } from './hooks/useStreetMeterPopup'
import { MapFilters } from './MapFilters'

export function ParkMap() {
  const mapContainer = useRef<HTMLDivElement>(null)
  const mapRef = useRef<mapboxgl.Map | null>(null)
  const [mapReady, setMapReady] = useState(false)

  const fetchLots = useAppStore((s) => s.fetchLots)
  const fetchEnforcement = useAppStore((s) => s.fetchEnforcement)
  const mapCenter = useAppStore((s) => s.mapCenter)
  const mapZoom = useAppStore((s) => s.mapZoom)
  const mapFilters = useAppStore((s) => s.mapFilters)

  // Initialize map
  useEffect(() => {
    if (!mapContainer.current || mapRef.current) return

    mapboxgl.accessToken = MAPBOX_TOKEN

    const map = new mapboxgl.Map({
      container: mapContainer.current,
      style: MAP_STYLE,
      center: DEFAULT_CENTER,
      zoom: DEFAULT_ZOOM,
    })

    map.addControl(new mapboxgl.NavigationControl(), 'top-right')
    map.addControl(
      new mapboxgl.GeolocateControl({
        positionOptions: { enableHighAccuracy: true },
        trackUserLocation: true,
      }),
      'top-right'
    )

    map.on('load', () => {
      setMapReady(true)
    })

    mapRef.current = map

    // Load initial data
    fetchLots()
    fetchEnforcement()

    return () => {
      map.remove()
      mapRef.current = null
      setMapReady(false)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Map layer hooks
  useTramLayers(mapRef.current, mapReady, !!mapFilters.tram)
  useLotLayers(mapRef.current, mapReady)
  useWalkingRoute(mapRef.current, mapReady)
  useLotPopup(mapRef.current)
  useWaypointLayers(mapRef.current, mapReady, mapFilters)
  useStreetMeterLayers(mapRef.current, mapReady, !!mapFilters.street_parking)
  useStreetMeterPopup(mapRef.current, !!mapFilters.street_parking)

  // Pan map when center/zoom changes from store
  useEffect(() => {
    const map = mapRef.current
    if (!map) return
    map.flyTo({ center: mapCenter, zoom: mapZoom, duration: 800 })
  }, [mapCenter, mapZoom])

  return (
    <div className="relative flex-1 h-full">
      <MapFilters />
      <div ref={mapContainer} className="absolute inset-0" />
    </div>
  )
}
