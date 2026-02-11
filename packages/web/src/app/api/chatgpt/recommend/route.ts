import { NextRequest, NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'
import type { UserType, ParkingRecommendation } from '@parkatbalboa/shared'
import { formatWalkTime, formatDistance } from '@/lib/utils'

function formatRecommendationForChatGPT(rec: ParkingRecommendation) {
  const walkDisplay = rec.walkingTimeSeconds
    ? formatWalkTime(rec.walkingTimeSeconds)
    : null
  const distDisplay = rec.walkingDistanceMeters
    ? formatDistance(rec.walkingDistanceMeters)
    : null

  return {
    lot_name: rec.lotDisplayName,
    cost: rec.costDisplay,
    is_free: rec.isFree,
    walking_time: walkDisplay,
    walking_distance: distDisplay,
    tram_available: rec.hasTram,
    tram_time: rec.tramTimeMinutes ? `${rec.tramTimeMinutes} min` : null,
    tips: rec.tips,
    score: rec.score,
    lat: rec.lat,
    lng: rec.lng,
  }
}

function generateSummary(
  recs: ParkingRecommendation[],
  _userType: UserType,
  destinationSlug: string | null
): string {
  if (recs.length === 0) {
    return 'No parking recommendations are available at this time.'
  }

  const top = recs[0]!
  const freeCount = recs.filter((r) => r.isFree).length

  let summary = `I recommend parking at ${top.lotDisplayName}`

  if (top.isFree) {
    summary += ' (free parking)'
  } else {
    summary += ` (${top.costDisplay})`
  }

  if (top.walkingTimeSeconds) {
    summary += `, about a ${formatWalkTime(top.walkingTimeSeconds)}`
  }

  if (destinationSlug) {
    summary += ' to your destination'
  }

  summary += '.'

  if (top.hasTram) {
    summary += ' A free tram is also available from this lot.'
  }

  if (freeCount > 1) {
    summary += ` There are ${freeCount} free parking options available.`
  }

  return summary
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
      { error: 'user_type is required. Options: resident, nonresident, staff, volunteer, ada' },
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

    const recs: ParkingRecommendation[] = data ?? []
    const formatted = recs.map(formatRecommendationForChatGPT)
    const summary = generateSummary(recs, userType, destinationSlug)

    return NextResponse.json({
      summary,
      recommendations: formatted,
      query: {
        user_type: userType,
        has_pass: hasPass,
        destination: destinationSlug,
        visit_hours: visitHours,
        query_time: queryTime,
      },
    })
  } catch (err) {
    console.error('ChatGPT recommend error:', err)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
