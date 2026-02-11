import type { LotTier } from './lots';

export type UserType = 'resident' | 'nonresident' | 'staff' | 'volunteer' | 'ada';

export type DurationType = 'hourly' | 'daily' | 'event';

export interface PricingRule {
  id: string;
  tier: LotTier;
  userType: UserType;
  durationType: DurationType;
  rateCents: number;
  maxDailyCents: number | null;
  effectiveDate: string;
  endDate: string | null;
}

export interface EnforcementPeriod {
  id: string;
  startTime: string;
  endTime: string;
  daysOfWeek: number[];
  effectiveDate: string;
  endDate: string | null;
}

export interface Holiday {
  id: string;
  name: string;
  date: string;
  isRecurring: boolean;
}

export type PassType = 'monthly' | 'quarterly' | 'annual';

export interface ParkingPass {
  id: string;
  name: string;
  type: PassType;
  priceCents: number;
  userType: UserType;
  effectiveDate: string;
  endDate: string | null;
}
