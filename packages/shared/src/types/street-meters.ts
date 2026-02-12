export interface StreetMeter {
  id: string;
  pole: string;
  zone: string | null;
  area: string | null;
  subArea: string | null;
  lat: number | null;
  lng: number | null;
  configId: number | null;
  configName: string | null;
  timeStart: string | null;
  timeEnd: string | null;
  timeLimit: string | null;
  daysInOperation: string | null;
  rateCentsPerHour: number | null;
  mobilePay: boolean;
  multiSpace: boolean;
  restrictions: string | null;
  syncedAt: string;
}

export interface StreetSegment {
  segmentId: string;
  zone: string;
  area: string;
  subArea: string;
  lat: number;
  lng: number;
  meterCount: number;
  rateCentsPerHour: number;
  rateDisplay: string;
  timeStart: string | null;
  timeEnd: string | null;
  timeLimit: string | null;
  daysInOperation: string | null;
  hasMobilePay: boolean;
}
