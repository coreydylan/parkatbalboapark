import { NextRequest, NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'
import { formatCost } from '@parkatbalboa/shared'
import type { StreetSegment } from '@parkatbalboa/shared'

function aggregateSegments(meters: Record<string, unknown>[]): StreetSegment[] {
  const groups = new Map<string, Record<string, unknown>[]>()

  for (const m of meters) {
    const zone = (m.zone as string) || 'Unknown'
    const area = (m.area as string) || 'Unknown'
    const subArea = (m.sub_area as string) || 'Unknown'
    const key = `${zone}::${area}::${subArea}`
    let group = groups.get(key)
    if (!group) {
      group = []
      groups.set(key, group)
    }
    group.push(m)
  }

  const segments: StreetSegment[] = []

  for (const [segmentId, group] of groups) {
    const parts = segmentId.split('::')
    const zone = parts[0] ?? 'Unknown'
    const area = parts[1] ?? 'Unknown'
    const subArea = parts[2] ?? 'Unknown'

    // Centroid
    let latSum = 0
    let lngSum = 0
    let geoCount = 0
    for (const m of group) {
      if (m.lat != null && m.lng != null) {
        latSum += m.lat as number
        lngSum += m.lng as number
        geoCount++
      }
    }
    if (geoCount === 0) continue // skip segments with no geo data

    // Mode rate (most frequent rate_cents_per_hour)
    const rateCounts = new Map<number, number>()
    for (const m of group) {
      const rate = (m.rate_cents_per_hour as number) ?? 0
      rateCounts.set(rate, (rateCounts.get(rate) ?? 0) + 1)
    }
    let modeRate = 0
    let modeCount = 0
    for (const [rate, count] of rateCounts) {
      if (count > modeCount) {
        modeRate = rate
        modeCount = count
      }
    }

    // OR-aggregate mobile_pay
    const hasMobilePay = group.some((m) => m.mobile_pay === true)

    // Take schedule from first meter (consistent within blocks)
    const first = group[0]!

    segments.push({
      segmentId,
      zone,
      area,
      subArea,
      lat: latSum / geoCount,
      lng: lngSum / geoCount,
      meterCount: group.length,
      rateCentsPerHour: modeRate,
      rateDisplay: modeRate === 0 ? 'FREE' : `${formatCost(modeRate)}/hr`,
      timeStart: (first.time_start as string) ?? null,
      timeEnd: (first.time_end as string) ?? null,
      timeLimit: (first.time_limit as string) ?? null,
      daysInOperation: (first.days_in_operation as string) ?? null,
      hasMobilePay,
    })
  }

  return segments
}

export async function GET(request: NextRequest) {
  try {
    const supabase = getSupabase()
    const zone = request.nextUrl.searchParams.get('zone')
    const grouped = request.nextUrl.searchParams.get('grouped') === 'true'

    let query = supabase
      .from('street_meters')
      .select(`
        id,
        pole,
        zone,
        area,
        sub_area,
        lat,
        lng,
        config_id,
        config_name,
        time_start,
        time_end,
        time_limit,
        days_in_operation,
        rate_cents_per_hour,
        mobile_pay,
        multi_space,
        restrictions,
        synced_at
      `)
      .order('zone')

    if (zone) {
      query = query.eq('zone', zone)
    }

    const { data: meters, error } = await query

    if (error) {
      console.error('Error fetching street meters:', error)
      return NextResponse.json({ error: 'Failed to fetch street meters' }, { status: 500 })
    }

    if (grouped) {
      const segments = aggregateSegments(meters ?? [])
      return NextResponse.json({ segments })
    }

    const transformed = (meters ?? []).map((m) => ({
      id: m.id,
      pole: m.pole,
      zone: m.zone,
      area: m.area,
      subArea: m.sub_area,
      lat: m.lat,
      lng: m.lng,
      configId: m.config_id,
      configName: m.config_name,
      timeStart: m.time_start,
      timeEnd: m.time_end,
      timeLimit: m.time_limit,
      daysInOperation: m.days_in_operation,
      rateCentsPerHour: m.rate_cents_per_hour,
      mobilePay: m.mobile_pay,
      multiSpace: m.multi_space,
      restrictions: m.restrictions,
      syncedAt: m.synced_at,
    }))

    return NextResponse.json({ meters: transformed })
  } catch (err) {
    console.error('Street meters error:', err)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
