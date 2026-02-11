import { NextRequest, NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'

export async function GET(request: NextRequest) {
  const area = request.nextUrl.searchParams.get('area')

  try {
    const supabase = getSupabase()
    let query = supabase
      .from('destinations')
      .select(`
        id,
        slug,
        name,
        display_name,
        area,
        type,
        address,
        lat,
        lng,
        website_url,
        created_at
      `)
      .order('area')
      .order('name')

    if (area) {
      query = query.eq('area', area)
    }

    const { data: destinations, error } = await query

    if (error) {
      console.error('Error fetching destinations:', error)
      return NextResponse.json(
        { error: 'Failed to fetch destinations' },
        { status: 500 }
      )
    }

    const transformed = (destinations ?? []).map((d) => ({
      id: d.id,
      slug: d.slug,
      name: d.name,
      displayName: d.display_name,
      area: d.area,
      type: d.type,
      address: d.address,
      lat: d.lat,
      lng: d.lng,
      websiteUrl: d.website_url,
      createdAt: d.created_at,
    }))

    return NextResponse.json({ destinations: transformed })
  } catch (err) {
    console.error('Destinations error:', err)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
