import type { LotTier } from './lots';
import type { UserType } from './pricing';

export interface RecommendationRequest {
  userType: UserType;
  hasPass: boolean;
  destinationSlug: string | null;
  queryTime: string | Date;
  visitHours: number;
}

export interface ParkingRecommendation {
  lotSlug: string;
  lotName: string;
  lotDisplayName: string;
  lat: number;
  lng: number;
  tier: LotTier;
  costCents: number;
  costDisplay: string;
  isFree: boolean;
  walkingDistanceMeters: number | null;
  walkingTimeSeconds: number | null;
  walkingTimeDisplay: string | null;
  hasTram: boolean;
  tramTimeMinutes: number | null;
  score: number;
  tips: string[];
}

export interface RecommendationResponse {
  recommendations: ParkingRecommendation[];
  enforcementActive: boolean;
  queryTime: string;
}
