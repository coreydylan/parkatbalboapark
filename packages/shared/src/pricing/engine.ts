import type { ParkingLot, LotTier, LotTierAssignment } from '../types/lots';
import type { LotDestinationDistance } from '../types/destinations';
import type { UserType, PricingRule, EnforcementPeriod, Holiday } from '../types/pricing';
import type { RecommendationRequest, ParkingRecommendation } from '../types/recommendations';

export interface PricingData {
  lots: ParkingLot[];
  tierAssignments: LotTierAssignment[];
  pricingRules: PricingRule[];
  enforcementPeriods: EnforcementPeriod[];
  holidays: Holiday[];
  distances: LotDestinationDistance[] | null;
  destinationId: string | null;
  tramScheduleFrequencyMinutes: number | null;
}

export interface CostResult {
  costCents: number;
  costDisplay: string;
  isFree: boolean;
  tips: string[];
}

/**
 * Format a cost in cents to a display string.
 * 0 -> 'FREE', whole dollars -> '$X', otherwise '$X.XX'
 */
export function formatCost(cents: number): string {
  if (cents <= 0) return 'FREE';
  const dollars = cents / 100;
  if (cents % 100 === 0) return `$${dollars}`;
  return `$${dollars.toFixed(2)}`;
}

/**
 * Format walking time in seconds to a human-readable string.
 */
export function formatWalkTime(seconds: number): string {
  const minutes = Math.round(seconds / 60);
  if (minutes <= 0) return '1 min walk';
  return `${minutes} min walk`;
}

/**
 * Parse a time string like '08:00' into total minutes since midnight.
 */
function parseTimeToMinutes(time: string): number {
  const parts = time.split(':').map(Number);
  return (parts[0] ?? 0) * 60 + (parts[1] ?? 0);
}

/**
 * Check if a date string matches a holiday.
 */
function isHoliday(date: Date, holidays: Holiday[]): boolean {
  const month = date.getMonth() + 1;
  const day = date.getDate();
  const fullDateStr = date.toISOString().split('T')[0]!;

  return holidays.some((h) => {
    if (h.isRecurring) {
      const parts = h.date.split('-').map(Number);
      const hMonth = parts[1];
      const hDay = parts[2];
      return month === hMonth && day === hDay;
    }
    return h.date === fullDateStr;
  });
}

/**
 * Get the current tier for a lot based on tier assignments and date.
 */
export function getCurrentTier(
  lotId: string,
  tierAssignments: LotTierAssignment[],
  date: Date
): LotTier {
  const dateStr = date.toISOString().split('T')[0]!;

  const applicable = tierAssignments
    .filter(
      (ta) =>
        ta.lotId === lotId &&
        ta.effectiveDate <= dateStr &&
        (ta.endDate === null || ta.endDate >= dateStr)
    )
    .sort((a, b) => b.effectiveDate.localeCompare(a.effectiveDate));

  if (applicable.length === 0) return 0;
  return applicable[0]!.tier;
}

/**
 * Check if parking enforcement is active at a given time.
 */
export function isEnforcementActive(
  time: Date,
  enforcement: EnforcementPeriod[],
  holidays: Holiday[]
): boolean {
  if (isHoliday(time, holidays)) return false;

  const dayOfWeek = time.getDay();
  const currentMinutes = time.getHours() * 60 + time.getMinutes();
  const dateStr = time.toISOString().split('T')[0]!;

  return enforcement.some((ep) => {
    if (ep.effectiveDate > dateStr) return false;
    if (ep.endDate !== null && ep.endDate < dateStr) return false;
    if (!ep.daysOfWeek.includes(dayOfWeek)) return false;

    const startMinutes = parseTimeToMinutes(ep.startTime);
    const endMinutes = parseTimeToMinutes(ep.endTime);
    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  });
}

/**
 * Find the applicable pricing rule for a given tier, user type, and date.
 */
function findPricingRule(
  tier: LotTier,
  userType: UserType,
  rules: PricingRule[],
  date: Date
): PricingRule | null {
  const dateStr = date.toISOString().split('T')[0]!;

  const applicable = rules
    .filter(
      (r) =>
        r.tier === tier &&
        r.userType === userType &&
        r.effectiveDate <= dateStr &&
        (r.endDate === null || r.endDate >= dateStr)
    )
    .sort((a, b) => b.effectiveDate.localeCompare(a.effectiveDate));

  return applicable.length > 0 ? (applicable[0] ?? null) : null;
}

/**
 * Compute the cost for parking at a specific lot.
 */
export function computeLotCost(
  lot: ParkingLot,
  tier: LotTier,
  userType: UserType,
  hasPass: boolean,
  visitHours: number,
  rules: PricingRule[],
  enforced: boolean,
  queryDate: Date
): CostResult {
  const tips: string[] = [];

  // Free tier is always free
  if (tier === 0) {
    tips.push('This lot is always free');
    return { costCents: 0, costDisplay: 'FREE', isFree: true, tips };
  }

  // Not enforced means free
  if (!enforced) {
    tips.push('Parking is free outside enforcement hours');
    return { costCents: 0, costDisplay: 'FREE', isFree: true, tips };
  }

  // Pass holders park free
  if (hasPass) {
    tips.push('Your parking pass covers this lot');
    return { costCents: 0, costDisplay: 'FREE', isFree: true, tips };
  }

  // ADA: free everywhere (official policy since launch)
  if (userType === 'ada') {
    tips.push('ADA parking is free at all lots');
    return { costCents: 0, costDisplay: 'FREE', isFree: true, tips };
  }

  // Staff and volunteers park free in tier 0, 2, 3
  if ((userType === 'staff' || userType === 'volunteer') && tier !== 1) {
    tips.push('Staff and volunteers park free in Free, Standard, and Economy lots');
    return { costCents: 0, costDisplay: 'FREE', isFree: true, tips };
  }

  // Residents at tier 2/3: free when no active paid rule exists
  if (userType === 'resident' && (tier === 2 || tier === 3)) {
    const rule = findPricingRule(tier, 'resident', rules, queryDate);
    if (!rule || rule.rateCents === 0) {
      tips.push('Free for verified residents');
      return { costCents: 0, costDisplay: 'FREE', isFree: true, tips };
    }
  }

  // Check lot-specific special rules (e.g. first N hours free)
  if (lot.specialRules) {
    const dateStr = queryDate.toISOString().split('T')[0]!;
    const applicableRule = lot.specialRules.find(
      (sr) =>
        sr.freeMinutes > 0 &&
        sr.effectiveDate <= dateStr &&
        (sr.endDate === null || sr.endDate >= dateStr)
    );
    if (applicableRule && visitHours <= applicableRule.freeMinutes / 60) {
      tips.push(applicableRule.description);
      return { costCents: 0, costDisplay: 'FREE', isFree: true, tips };
    }
  }

  // Look up the pricing rule
  const rule = findPricingRule(tier, userType, rules, queryDate);

  if (!rule) {
    // Fallback: try nonresident rate if no specific rate found
    const fallbackRule = findPricingRule(tier, 'nonresident', rules, queryDate);
    if (!fallbackRule) {
      tips.push('Pricing information unavailable');
      return { costCents: 0, costDisplay: 'FREE', isFree: true, tips };
    }
    return computeCostFromRule(fallbackRule, visitHours, tips);
  }

  return computeCostFromRule(rule, visitHours, tips);
}

/**
 * Compute cost from a specific pricing rule.
 */
function computeCostFromRule(
  rule: PricingRule,
  visitHours: number,
  tips: string[]
): CostResult {
  let costCents: number;

  switch (rule.durationType) {
    case 'block': {
      // Flat rate for up to 4 hours, max_daily for longer visits
      if (visitHours <= 4) {
        costCents = rule.rateCents;
        tips.push(`${formatCost(rule.rateCents)} for up to 4 hours`);
      } else {
        costCents = rule.maxDailyCents ?? rule.rateCents;
        tips.push(`${formatCost(costCents)} full day`);
      }
      break;
    }
    case 'hourly': {
      const hours = Math.ceil(visitHours);
      costCents = rule.rateCents * hours;
      if (rule.maxDailyCents !== null && costCents > rule.maxDailyCents) {
        costCents = rule.maxDailyCents;
        tips.push(`Daily max of ${formatCost(rule.maxDailyCents)} applied`);
      }
      tips.push(`${formatCost(rule.rateCents)}/hr`);
      break;
    }
    case 'daily': {
      costCents = rule.rateCents;
      tips.push('Flat daily rate');
      break;
    }
    case 'event': {
      costCents = rule.rateCents;
      tips.push('Event rate applies');
      break;
    }
    default:
      costCents = 0;
  }

  return {
    costCents,
    costDisplay: formatCost(costCents),
    isFree: costCents === 0,
    tips,
  };
}

/**
 * Rank recommendations by weighted score.
 * Normalizes cost and walking distance to 0-1 range and applies weights.
 */
export function rankRecommendations(
  recs: ParkingRecommendation[]
): ParkingRecommendation[] {
  if (recs.length === 0) return [];

  const COST_WEIGHT = 0.4;
  const WALK_WEIGHT = 0.35;
  const TRAM_WEIGHT = 0.1;
  const TIER_WEIGHT = 0.1;
  const ADA_WEIGHT = 0.05;

  // Find max values for normalization
  const maxCost = Math.max(...recs.map((r) => r.costCents), 1);
  const maxWalk = Math.max(
    ...recs.map((r) => r.walkingDistanceMeters ?? 0),
    1
  );

  const scored = recs.map((rec) => {
    const costNorm = rec.costCents / maxCost;
    const walkNorm = (rec.walkingDistanceMeters ?? maxWalk) / maxWalk;
    const tramBonus = rec.hasTram ? 1 : 0;
    const tierNorm = rec.tier / 3;

    const score =
      COST_WEIGHT * (1 - costNorm) +
      WALK_WEIGHT * (1 - walkNorm) +
      TRAM_WEIGHT * tramBonus +
      TIER_WEIGHT * (1 - tierNorm) +
      ADA_WEIGHT; // ADA spaces info not on recommendation, give baseline

    return { ...rec, score: Math.round(score * 1000) / 1000 };
  });

  return scored.sort((a, b) => b.score - a.score);
}

/**
 * Compute parking recommendations for all lots given a request and pricing data.
 */
export function computeRecommendations(
  request: RecommendationRequest,
  data: PricingData
): ParkingRecommendation[] {
  const queryTime =
    typeof request.queryTime === 'string'
      ? new Date(request.queryTime)
      : request.queryTime;

  const enforced = isEnforcementActive(
    queryTime,
    data.enforcementPeriods,
    data.holidays
  );

  const recommendations: ParkingRecommendation[] = data.lots.map((lot) => {
    const tier = getCurrentTier(lot.id, data.tierAssignments, queryTime);

    const costResult = computeLotCost(
      lot,
      tier,
      request.userType,
      request.hasPass,
      request.visitHours,
      data.pricingRules,
      enforced,
      queryTime
    );

    // Find walking distance to requested destination
    let walkingDistanceMeters: number | null = null;
    let walkingTimeSeconds: number | null = null;
    let walkingTimeDisplay: string | null = null;

    if (data.distances && request.destinationSlug) {
      // Filter by both lotId and destinationId to get the correct distance
      // when distances for multiple destinations are present
      const distance = data.distances.find(
        (d) =>
          d.lotId === lot.id &&
          (data.destinationId === null || d.destinationId === data.destinationId)
      );
      if (distance) {
        walkingDistanceMeters = distance.walkingDistanceMeters;
        walkingTimeSeconds = distance.walkingTimeSeconds;
        walkingTimeDisplay = formatWalkTime(distance.walkingTimeSeconds);
      }
    }

    // Tram info: compute estimated wait as (frequency / 2) + 5 min ride,
    // falling back to 5 min default when schedule data is unavailable
    const hasTram = lot.hasTramStop;
    const tramTimeMinutes = hasTram
      ? data.tramScheduleFrequencyMinutes !== null
        ? Math.round(data.tramScheduleFrequencyMinutes / 2) + 5
        : 5 // default when tram schedule data is unavailable
      : null;

    // Add contextual tips
    if (lot.hasEvCharging) {
      costResult.tips.push('EV charging available');
    }
    if (lot.hasAdaSpaces) {
      costResult.tips.push('ADA accessible spaces available');
    }
    if (hasTram) {
      costResult.tips.push('Free tram stop at this lot');
    }

    return {
      lotSlug: lot.slug,
      lotName: lot.name,
      lotDisplayName: lot.displayName,
      lat: lot.lat,
      lng: lot.lng,
      tier,
      costCents: costResult.costCents,
      costDisplay: costResult.costDisplay,
      isFree: costResult.isFree,
      walkingDistanceMeters,
      walkingTimeSeconds,
      walkingTimeDisplay,
      hasTram,
      tramTimeMinutes,
      score: 0,
      tips: costResult.tips,
    };
  });

  return rankRecommendations(recommendations);
}
