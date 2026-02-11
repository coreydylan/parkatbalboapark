import type { LotTier } from '../types/lots';

export const TIER_NAMES: Record<LotTier, string> = {
  0: 'Free',
  1: 'Premium',
  2: 'Standard',
  3: 'Economy',
};

export const TIER_DESCRIPTIONS: Record<LotTier, string> = {
  0: 'Free parking for everyone',
  1: 'Paid parking - closest to main attractions',
  2: 'Lower cost parking',
  3: 'Budget-friendly parking',
};

export const TIER_COLORS: Record<LotTier, string> = {
  0: '#22c55e',
  1: '#ef4444',
  2: '#f59e0b',
  3: '#3b82f6',
};
