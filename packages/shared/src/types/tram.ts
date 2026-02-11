export interface TramStop {
  id: string;
  name: string;
  lotId: string | null;
  lat: number;
  lng: number;
  stopOrder: number;
}

export interface TramSchedule {
  id: string;
  startTime: string;
  endTime: string;
  frequencyMinutes: number;
  daysOfWeek: number[];
  effectiveDate: string;
  endDate: string | null;
}
