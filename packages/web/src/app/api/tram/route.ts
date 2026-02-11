import { NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'

export async function GET() {
  try {
    const supabase = getSupabase()

    // Fetch tram stops
    const { data: stops } = await supabase
      .from('tram_stops')
      .select('*')
      .order('stop_order')

    // Fetch tram schedule
    const { data: schedule } = await supabase
      .from('tram_schedule')
      .select('*')
      .limit(1)

    const tramStops = (stops ?? []).map((s) => ({
      id: s.id,
      name: s.name,
      lotId: s.lot_id,
      lat: s.lat,
      lng: s.lng,
      stopOrder: s.stop_order,
    }))

    // Build route GeoJSON from stops
    const routeCoords = tramStops.map((s) => [s.lng, s.lat])
    if (routeCoords.length > 0) {
      routeCoords.push(routeCoords[0]!) // close the loop
    }

    const routeGeojson = {
      type: 'Feature' as const,
      properties: {},
      geometry: {
        type: 'LineString' as const,
        coordinates: routeCoords,
      },
    }

    const first = schedule?.[0]
    const tramSchedule = first
      ? {
          id: first.id,
          startTime: first.start_time,
          endTime: first.end_time,
          frequencyMinutes: first.frequency_minutes,
          daysOfWeek: first.days_of_week,
          effectiveDate: first.effective_date,
          endDate: first.end_date,
        }
      : null

    return NextResponse.json({
      stops: tramStops,
      schedule: tramSchedule,
      routeGeojson,
    })
  } catch (err) {
    console.error('Tram error:', err)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
