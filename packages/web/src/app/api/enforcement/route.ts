import { NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'

export async function GET() {
  try {
    const supabase = getSupabase()
    const now = new Date()
    const dayOfWeek = now.getDay()
    const currentMinutes = now.getHours() * 60 + now.getMinutes()
    const todayStr = now.toISOString().split('T')[0]!

    // Check enforcement periods
    const { data: periods } = await supabase
      .from('enforcement_periods')
      .select('*')
      .lte('effective_date', todayStr)
      .or(`end_date.is.null,end_date.gte.${todayStr}`)

    let active = false
    let startTime = '08:00'
    let endTime = '18:00'

    if (periods) {
      for (const ep of periods) {
        if (!ep.days_of_week.includes(dayOfWeek)) continue
        const parts = (ep.start_time as string).split(':').map(Number)
        const endParts = (ep.end_time as string).split(':').map(Number)
        const startMin = (parts[0] ?? 0) * 60 + (parts[1] ?? 0)
        const endMin = (endParts[0] ?? 0) * 60 + (endParts[1] ?? 0)
        if (currentMinutes >= startMin && currentMinutes < endMin) {
          active = true
          startTime = ep.start_time
          endTime = ep.end_time
          break
        }
        startTime = ep.start_time
        endTime = ep.end_time
      }
    }

    // Check for upcoming holiday
    const { data: holidays } = await supabase
      .from('holidays')
      .select('*')
      .gte('date', todayStr)
      .order('date')
      .limit(1)

    const firstHoliday = holidays?.[0]
    const nextHoliday = firstHoliday
      ? { name: firstHoliday.name, date: firstHoliday.date }
      : null

    // If today is a holiday, enforcement is not active
    if (nextHoliday && nextHoliday.date === todayStr) {
      active = false
    }

    return NextResponse.json({
      active,
      startTime,
      endTime,
      nextHoliday,
    })
  } catch (err) {
    console.error('Enforcement error:', err)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
