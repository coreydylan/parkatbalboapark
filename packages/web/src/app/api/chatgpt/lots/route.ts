import { NextResponse } from 'next/server'
import { getSupabase } from '@/lib/supabase'
import { formatCost } from '@parkatbalboa/shared'

function getPacificDate(): Date {
  return new Date(new Date().toLocaleString('en-US', { timeZone: 'America/Los_Angeles' }))
}

export async function GET() {
  try {
    const supabase = getSupabase()
    const now = getPacificDate()
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`

    // Fetch lots
    const { data: lots } = await supabase.from('parking_lots').select('*').order('name')

    // Fetch current tier assignments
    const { data: tiers } = await supabase
      .from('lot_tier_assignments')
      .select('*')
      .lte('effective_date', todayStr)
      .or(`end_date.is.null,end_date.gte.${todayStr}`)
      .order('effective_date', { ascending: false })

    // Fetch pricing rules
    const { data: rules } = await supabase
      .from('pricing_rules')
      .select('*')
      .lte('effective_date', todayStr)
      .or(`end_date.is.null,end_date.gte.${todayStr}`)

    // Fetch payment methods
    const { data: payments } = await supabase.from('payment_methods').select('*')

    // Build response
    const result = (lots ?? []).map(lot => {
      const tier = tiers?.find(t => t.lot_id === lot.id)
      const lotTier = tier?.tier ?? 0

      // Get pricing for each user type
      const pricing: Record<string, string> = {}
      for (const userType of ['resident', 'nonresident', 'staff', 'ada']) {
        const rule = rules?.find(r => r.tier === lotTier && r.user_type === userType)
        if (!rule || rule.rate_cents === 0) {
          pricing[userType] = 'FREE'
        } else if (rule.duration_type === 'hourly') {
          pricing[userType] = `${formatCost(rule.rate_cents)}/hr (max ${formatCost(rule.max_daily_cents ?? rule.rate_cents)})`
        } else {
          pricing[userType] = `${formatCost(rule.rate_cents)}/day`
        }
      }

      const lotPayments = payments?.filter(p => p.lot_id === lot.id).map(p => p.method) ?? []

      return {
        name: lot.display_name,
        slug: lot.slug,
        tier: lotTier,
        capacity: lot.capacity,
        has_tram_stop: lot.has_tram_stop,
        has_ev_charging: lot.has_ev_charging,
        has_ada_spaces: lot.has_ada_spaces,
        notes: lot.notes,
        pricing,
        payment_methods: lotPayments,
      }
    })

    return NextResponse.json({ lots: result })
  } catch (err) {
    console.error('ChatGPT lots error:', err)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
