export type DestinationArea =
  | 'central_mesa'
  | 'palisades'
  | 'east_mesa'
  | 'florida_canyon'
  | 'morley_field'
  | 'pan_american';

export type DestinationType =
  | 'museum'
  | 'garden'
  | 'theater'
  | 'landmark'
  | 'recreation'
  | 'dining'
  | 'zoo'
  | 'other';

export interface Destination {
  id: string;
  slug: string;
  name: string;
  displayName: string;
  area: DestinationArea;
  type: DestinationType;
  address: string | null;
  lat: number;
  lng: number;
  websiteUrl: string | null;
  createdAt: string;
}

export interface LotDestinationDistance {
  id: string;
  lotId: string;
  destinationId: string;
  walkingDistanceMeters: number;
  walkingTimeSeconds: number;
  routeGeojson: Record<string, unknown> | null;
}
