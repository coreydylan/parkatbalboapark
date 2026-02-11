import { NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'

export async function GET() {
  try {
    const supabase = getSupabase()
    const todayStr = new Date().toISOString().split('T')[0]!

    const { data: passes, error } = await supabase
      .from('parking_passes')
      .select('*')
      .lte('effective_date', todayStr)
      .or(`end_date.is.null,end_date.gte.${todayStr}`)
      .order('price_cents')

    if (error) {
      console.error('Error fetching passes:', error)
      return NextResponse.json(
        { error: 'Failed to fetch passes' },
        { status: 500 }
      )
    }

    const transformed = (passes ?? []).map((p) => ({
      id: p.id,
      name: p.name,
      type: p.type,
      priceCents: p.price_cents,
      userType: p.user_type,
      effectiveDate: p.effective_date,
      endDate: p.end_date,
    }))

    return NextResponse.json({ passes: transformed })
  } catch (err) {
    console.error('Passes error:', err)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
