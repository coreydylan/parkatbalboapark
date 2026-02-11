export type LotTier = 0 | 1 | 2 | 3;

export interface ParkingLot {
  id: string;
  slug: string;
  name: string;
  displayName: string;
  address: string;
  lat: number;
  lng: number;
  capacity: number | null;
  boundaryGeojson: Record<string, unknown> | null;
  hasEvCharging: boolean;
  hasAdaSpaces: boolean;
  hasTramStop: boolean;
  notes: string | null;
  createdAt: string;
}

export interface LotTierAssignment {
  id: string;
  lotId: string;
  tier: LotTier;
  effectiveDate: string;
  endDate: string | null;
}

export type PaymentMethodType =
  | 'credit_card'
  | 'apple_pay'
  | 'google_pay'
  | 'coins'
  | 'parkmobile';

export interface LotPaymentMethod {
  id: string;
  lotId: string;
  method: PaymentMethodType;
}
