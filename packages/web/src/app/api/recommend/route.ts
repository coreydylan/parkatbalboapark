import { NextRequest, NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'
import type { UserType, ParkingRecommendation, RecommendationResponse } from '@parkatbalboa/shared'

// The Supabase RPC returns snake_case column names; the frontend expects camelCase.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function transformRecommendation(row: any): ParkingRecommendation {
  return {
    lotSlug: row.lot_slug,
    lotName: row.lot_name,
    lotDisplayName: row.lot_display_name,
    lat: row.lat,
    lng: row.lng,
    tier: row.tier,
    costCents: row.cost_cents,
    costDisplay: row.cost_display,
    isFree: row.is_free,
    walkingDistanceMeters: row.walking_distance_meters,
    walkingTimeSeconds: row.walking_time_seconds,
    walkingTimeDisplay: row.walking_time_display,
    hasTram: row.has_tram,
    tramTimeMinutes: row.tram_time_minutes,
    score: row.score,
    tips: row.tips ?? [],
  }
}

export async function GET(request: NextRequest) {
  const params = request.nextUrl.searchParams

  const userType = params.get('user_type') as UserType | null
  const hasPass = params.get('has_pass') === 'true'
  const destinationSlug = params.get('destination') || null
  const visitHours = Number(params.get('visit_hours')) || 2
  const queryTime = params.get('time') || new Date().toISOString()

  if (!userType) {
    return NextResponse.json(
      { error: 'user_type is required' },
      { status: 400 }
    )
  }

  try {
    const supabase = getSupabase()
    const { data, error } = await supabase.rpc('get_parking_recommendations', {
      p_user_type: userType,
      p_has_pass: hasPass,
      p_destination_slug: destinationSlug,
      p_visit_hours: visitHours,
      p_query_time: queryTime,
    })

    if (error) {
      console.error('Supabase RPC error:', error)
      return NextResponse.json(
        { error: 'Failed to fetch recommendations' },
        { status: 500 }
      )
    }

    // Transform snake_case RPC results to camelCase for the frontend
    const recommendations: ParkingRecommendation[] = (data ?? []).map(transformRecommendation)

    const response: RecommendationResponse = {
      recommendations,
      enforcementActive: false,
      queryTime,
    }

    // Check enforcement status using Pacific time
    const pacificNow = new Date(
      new Date(queryTime).toLocaleString('en-US', { timeZone: 'America/Los_Angeles' })
    )
    const todayStr = `${pacificNow.getFullYear()}-${String(pacificNow.getMonth() + 1).padStart(2, '0')}-${String(pacificNow.getDate()).padStart(2, '0')}`

    const { data: enforcement } = await supabase
      .from('enforcement_periods')
      .select('*')
      .lte('effective_date', todayStr)
      .or(`end_date.is.null,end_date.gte.${todayStr}`)

    if (enforcement && enforcement.length > 0) {
      const dayOfWeek = pacificNow.getDay()
      const currentMinutes = pacificNow.getHours() * 60 + pacificNow.getMinutes()

      // Check if today is a holiday
      const { data: holidays } = await supabase
        .from('holidays')
        .select('*')
        .eq('date', todayStr)
        .limit(1)

      const isHoliday = holidays && holidays.length > 0

      if (!isHoliday) {
        for (const ep of enforcement) {
          if (!ep.days_of_week.includes(dayOfWeek)) continue
          const parts = (ep.start_time as string).split(':').map(Number)
          const endParts = (ep.end_time as string).split(':').map(Number)
          const startMin = (parts[0] ?? 0) * 60 + (parts[1] ?? 0)
          const endMin = (endParts[0] ?? 0) * 60 + (endParts[1] ?? 0)
          if (currentMinutes >= startMin && currentMinutes < endMin) {
            response.enforcementActive = true
            break
          }
        }
      }
    }

    return NextResponse.json(response)
  } catch (err) {
    console.error('Recommendation error:', err)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
