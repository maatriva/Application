export interface TelemetryPayload {
  deviceId: string;
  timestamp: string; // ISO DateTime string
  heartRate?: number | null;
  respirationRate?: number | null;
  bodyTemperature?: number | null;
  roomTemperature?: number | null;
  humidity?: number | null;
  movementDetected?: boolean | null;
  cryDetected?: boolean | null;
  sleepStage?: string | null;
  airQuality?: number | null;
  batteryLevel?: number | null;
}

export interface TelemetryHistoryQuery {
  from?: string; // ISO date string
  to?: string;   // ISO date string
  limit?: string;  // number as string from request query
}
