import { NextRequest, NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'
import type { UserType, RecommendationResponse } from '@parkatbalboa/shared'

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

    const response: RecommendationResponse = {
      recommendations: data ?? [],
      enforcementActive: false,
      queryTime,
    }

    // Check enforcement status
    const { data: enforcement } = await supabase
      .from('enforcement_periods')
      .select('*')
      .limit(1)

    if (enforcement && enforcement.length > 0) {
      const now = new Date(queryTime)
      const dayOfWeek = now.getDay()
      const currentMinutes = now.getHours() * 60 + now.getMinutes()

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

    return NextResponse.json(response)
  } catch (err) {
    console.error('Recommendation error:', err)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
