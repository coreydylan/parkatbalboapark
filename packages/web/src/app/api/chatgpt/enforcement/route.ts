import { NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'

function getPacificDate(): Date {
  return new Date(new Date().toLocaleString('en-US', { timeZone: 'America/Los_Angeles' }))
}

export async function GET() {
  try {
    const supabase = getSupabase()
    const now = getPacificDate()
    const dayOfWeek = now.getDay()
    const currentMinutes = now.getHours() * 60 + now.getMinutes()
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`

    // Check enforcement periods
    const { data: periods } = await supabase
      .from('enforcement_periods')
      .select('*')
      .lte('effective_date', todayStr)
      .or(`end_date.is.null,end_date.gte.${todayStr}`)

    let active = false
    let hours = '8:00 AM - 6:00 PM' // default display

    if (periods) {
      for (const ep of periods) {
        if (!ep.days_of_week.includes(dayOfWeek)) continue
        const parts = (ep.start_time as string).split(':').map(Number)
        const endParts = (ep.end_time as string).split(':').map(Number)
        const startMin = (parts[0] ?? 0) * 60 + (parts[1] ?? 0)
        const endMin = (endParts[0] ?? 0) * 60 + (endParts[1] ?? 0)

        // Format hours for display
        const startHour = parts[0] ?? 8
        const endHour = endParts[0] ?? 18
        hours = `${startHour > 12 ? startHour - 12 : startHour}:${String(parts[1] ?? 0).padStart(2, '0')} ${startHour >= 12 ? 'PM' : 'AM'} - ${endHour > 12 ? endHour - 12 : endHour}:${String(endParts[1] ?? 0).padStart(2, '0')} ${endHour >= 12 ? 'PM' : 'AM'}`

        if (currentMinutes >= startMin && currentMinutes < endMin) {
          active = true
          break
        }
      }
    }

    // Check holidays
    const { data: todayHoliday } = await supabase
      .from('holidays')
      .select('*')
      .eq('date', todayStr)
      .limit(1)

    const isHoliday = todayHoliday && todayHoliday.length > 0
    const holidayName = isHoliday ? todayHoliday[0]?.name : null

    if (isHoliday) active = false

    // Next free day (next holiday)
    const { data: nextHolidays } = await supabase
      .from('holidays')
      .select('*')
      .gt('date', todayStr)
      .order('date')
      .limit(1)

    const nextFreeDay = nextHolidays?.[0]
      ? { name: nextHolidays[0].name, date: nextHolidays[0].date }
      : null

    // Build message
    let message: string
    if (isHoliday) {
      message = `Parking is FREE today (${holidayName}). Happy holiday!`
    } else if (active) {
      message = `Parking enforcement is active today from ${hours}. Paid parking is in effect.`
    } else {
      message = `Parking is currently free (outside enforcement hours: ${hours}).`
    }

    return NextResponse.json({
      active,
      hours,
      is_holiday: isHoliday ?? false,
      holiday_name: holidayName ?? null,
      next_free_day: nextFreeDay,
      message,
    })
  } catch (err) {
    console.error('ChatGPT enforcement error:', err)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
