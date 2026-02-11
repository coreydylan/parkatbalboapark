import { NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'

export async function GET() {
  try {
    const supabase = getSupabase()
    const { data: lots, error } = await supabase
      .from('parking_lots')
      .select(`
        id,
        slug,
        name,
        display_name,
        address,
        lat,
        lng,
        capacity,
        boundary_geojson,
        has_ev_charging,
        has_ada_spaces,
        has_tram_stop,
        notes,
        created_at
      `)
      .order('name')

    if (error) {
      console.error('Error fetching lots:', error)
      return NextResponse.json({ error: 'Failed to fetch lots' }, { status: 500 })
    }

    // Transform snake_case to camelCase
    const transformed = (lots ?? []).map((lot) => ({
      id: lot.id,
      slug: lot.slug,
      name: lot.name,
      displayName: lot.display_name,
      address: lot.address,
      lat: lot.lat,
      lng: lot.lng,
      capacity: lot.capacity,
      boundaryGeojson: lot.boundary_geojson,
      hasEvCharging: lot.has_ev_charging,
      hasAdaSpaces: lot.has_ada_spaces,
      hasTramStop: lot.has_tram_stop,
      notes: lot.notes,
      createdAt: lot.created_at,
    }))

    return NextResponse.json({ lots: transformed })
  } catch (err) {
    console.error('Lots error:', err)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
