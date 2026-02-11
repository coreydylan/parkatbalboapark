import { describe, it, expect } from 'vitest'
import {
  formatCost,
  formatWalkTime,
  getCurrentTier,
  isEnforcementActive,
  computeLotCost,
  rankRecommendations,
} from './engine'
import type { ParkingLot, LotTierAssignment } from '../types/lots'
import type { PricingRule, EnforcementPeriod, Holiday } from '../types/pricing'

describe('formatCost', () => {
  it('returns FREE for zero', () => expect(formatCost(0)).toBe('FREE'))
  it('returns FREE for negative', () => expect(formatCost(-100)).toBe('FREE'))
  it('formats whole dollars', () => expect(formatCost(500)).toBe('$5'))
  it('formats cents', () => expect(formatCost(550)).toBe('$5.50'))
  it('formats large amounts', () => expect(formatCost(1600)).toBe('$16'))
})

describe('formatWalkTime', () => {
  it('returns 1 min for 0 seconds', () => expect(formatWalkTime(0)).toBe('1 min walk'))
  it('rounds to nearest minute', () => expect(formatWalkTime(150)).toBe('3 min walk'))
  it('handles exact minutes', () => expect(formatWalkTime(300)).toBe('5 min walk'))
})

describe('getCurrentTier', () => {
  const assignments: LotTierAssignment[] = [
    { id: '1', lotId: 'lot-1', tier: 1, effectiveDate: '2026-01-05', endDate: null },
    { id: '2', lotId: 'lot-2', tier: 2, effectiveDate: '2026-01-05', endDate: '2026-03-01' },
    { id: '3', lotId: 'lot-2', tier: 0, effectiveDate: '2026-03-02', endDate: null },
  ]

  it('returns tier for a lot', () => {
    expect(getCurrentTier('lot-1', assignments, new Date('2026-02-01'))).toBe(1)
  })
  it('returns 0 when no assignment', () => {
    expect(getCurrentTier('lot-999', assignments, new Date('2026-02-01'))).toBe(0)
  })
  it('respects date ranges', () => {
    expect(getCurrentTier('lot-2', assignments, new Date('2026-02-01'))).toBe(2)
    expect(getCurrentTier('lot-2', assignments, new Date('2026-03-15'))).toBe(0)
  })
})

describe('isEnforcementActive', () => {
  const enforcement: EnforcementPeriod[] = [{
    id: '1',
    startTime: '08:00',
    endTime: '18:00',
    daysOfWeek: [1, 2, 3, 4, 5, 6, 0],
    effectiveDate: '2026-01-05',
    endDate: null,
  }]
  const holidays: Holiday[] = [{
    id: '1',
    name: 'Christmas',
    date: '2026-12-25',
    isRecurring: true,
  }]

  it('returns true during enforcement hours', () => {
    // Wednesday at 10am
    const time = new Date('2026-01-07T10:00:00')
    expect(isEnforcementActive(time, enforcement, holidays)).toBe(true)
  })
  it('returns false outside hours', () => {
    const time = new Date('2026-01-07T19:00:00')
    expect(isEnforcementActive(time, enforcement, holidays)).toBe(false)
  })
  it('returns false on holidays', () => {
    const time = new Date('2026-12-25T10:00:00')
    expect(isEnforcementActive(time, enforcement, holidays)).toBe(false)
  })
})

describe('computeLotCost', () => {
  const baseLot: ParkingLot = {
    id: 'lot-1', slug: 'test-lot', name: 'Test', displayName: 'Test Lot',
    address: '123 Test', lat: 32.73, lng: -117.14, capacity: 100,
    boundaryGeojson: null, hasEvCharging: false, hasAdaSpaces: true,
    hasTramStop: false, notes: null, createdAt: '2026-01-01',
  }
  const rules: PricingRule[] = [
    { id: '1', tier: 1, userType: 'resident', durationType: 'hourly', rateCents: 500, maxDailyCents: 800, effectiveDate: '2026-01-05', endDate: null },
    { id: '2', tier: 1, userType: 'nonresident', durationType: 'hourly', rateCents: 500, maxDailyCents: 1600, effectiveDate: '2026-01-05', endDate: null },
    { id: '3', tier: 1, userType: 'ada', durationType: 'daily', rateCents: 500, maxDailyCents: 800, effectiveDate: '2026-01-05', endDate: '2026-03-01' },
    { id: '4', tier: 1, userType: 'ada', durationType: 'daily', rateCents: 0, maxDailyCents: 0, effectiveDate: '2026-03-02', endDate: null },
  ]
  const queryDate = new Date('2026-02-01')

  it('tier 0 is always free', () => {
    const result = computeLotCost(baseLot, 0, 'nonresident', false, 2, rules, true, queryDate)
    expect(result.isFree).toBe(true)
  })

  it('not enforced is free', () => {
    const result = computeLotCost(baseLot, 1, 'nonresident', false, 2, rules, false, queryDate)
    expect(result.isFree).toBe(true)
  })

  it('pass holder is free', () => {
    const result = computeLotCost(baseLot, 1, 'nonresident', true, 2, rules, true, queryDate)
    expect(result.isFree).toBe(true)
  })

  it('charges hourly with max daily cap', () => {
    const result = computeLotCost(baseLot, 1, 'resident', false, 2, rules, true, queryDate)
    expect(result.costCents).toBe(800) // $5/hr * 2hr = $10, but max $8
  })

  it('charges nonresident hourly', () => {
    const result = computeLotCost(baseLot, 1, 'nonresident', false, 2, rules, true, queryDate)
    expect(result.costCents).toBe(1000) // $5/hr * 2hr = $10, under $16 max
  })

  it('charges ADA $5/day before March 2', () => {
    const result = computeLotCost(baseLot, 1, 'ada', false, 2, rules, true, new Date('2026-02-15'))
    expect(result.costCents).toBe(500)
    expect(result.isFree).toBe(false)
  })

  it('ADA is free after March 2', () => {
    const result = computeLotCost(baseLot, 1, 'ada', false, 2, rules, true, new Date('2026-03-15'))
    expect(result.costCents).toBe(0)
    expect(result.isFree).toBe(true)
  })

  it('staff is free at tier 2', () => {
    const result = computeLotCost(baseLot, 2, 'staff', false, 2, rules, true, queryDate)
    expect(result.isFree).toBe(true)
  })

  it('volunteer is free at tier 3', () => {
    const result = computeLotCost(baseLot, 3, 'volunteer', false, 2, rules, true, queryDate)
    expect(result.isFree).toBe(true)
  })
})

describe('rankRecommendations', () => {
  it('returns empty array for empty input', () => {
    expect(rankRecommendations([])).toEqual([])
  })

  it('ranks free lots higher than paid lots', () => {
    const recs = [
      {
        lotSlug: 'paid', lotName: 'Paid', lotDisplayName: 'Paid Lot',
        lat: 32.73, lng: -117.14, tier: 1 as const, costCents: 1600,
        costDisplay: '$16', isFree: false,
        walkingDistanceMeters: 200, walkingTimeSeconds: 180,
        walkingTimeDisplay: '3 min walk', hasTram: false, tramTimeMinutes: null,
        score: 0, tips: [],
      },
      {
        lotSlug: 'free', lotName: 'Free', lotDisplayName: 'Free Lot',
        lat: 32.73, lng: -117.14, tier: 0 as const, costCents: 0,
        costDisplay: 'FREE', isFree: true,
        walkingDistanceMeters: 200, walkingTimeSeconds: 180,
        walkingTimeDisplay: '3 min walk', hasTram: false, tramTimeMinutes: null,
        score: 0, tips: [],
      },
    ]
    const ranked = rankRecommendations(recs)
    expect(ranked[0]!.lotSlug).toBe('free')
  })
})
