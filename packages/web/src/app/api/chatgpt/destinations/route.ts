import { NextRequest, NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'

export async function GET(request: NextRequest) {
  const params = request.nextUrl.searchParams
  const area = params.get('area')
  const type = params.get('type')
  const search = params.get('search')

  try {
    const supabase = getSupabase()
    let query = supabase
      .from('destinations')
      .select('slug, name, display_name, area, type')
      .order('area')
      .order('name')

    if (area) query = query.eq('area', area)
    if (type) query = query.eq('type', type)
    if (search) query = query.ilike('name', `%${search}%`)

    const { data, error } = await query
    if (error) {
      return NextResponse.json({ error: 'Failed to fetch destinations' }, { status: 500 })
    }

    return NextResponse.json({
      destinations: (data ?? []).map(d => ({
        slug: d.slug,
        name: d.display_name,
        area: d.area,
        type: d.type,
      }))
    })
  } catch (err) {
    console.error('ChatGPT destinations error:', err)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
