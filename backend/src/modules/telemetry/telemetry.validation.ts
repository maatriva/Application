import { z } from 'zod';

export const TelemetryPayloadSchema = z.object({
  deviceId: z.string().min(1, { message: 'deviceId is required.' }),
  timestamp: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: 'Invalid timestamp format.',
  }),
  heartRate: z.number().int().nonnegative().nullable().optional(),
  respirationRate: z.number().int().nonnegative().nullable().optional(),
  bodyTemperature: z.number().nonnegative().nullable().optional(),
  roomTemperature: z.number().nonnegative().nullable().optional(),
  humidity: z.number().nonnegative().nullable().optional(),
  movementDetected: z.boolean().nullable().optional(),
  cryDetected: z.boolean().nullable().optional(),
  sleepStage: z.string().nullable().optional(),
  airQuality: z.number().int().nonnegative().nullable().optional(),
  batteryLevel: z.number().int().nonnegative().nullable().optional(),
});

export const IngestTelemetrySchema = z.object({
  deviceId: z.string().min(1, { message: 'deviceId is required.' }),
  timestamp: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: 'Invalid timestamp format.',
  }),
  heartRate: z.number().int().nonnegative().nullable().optional(),
  breathingRate: z.number().int().nonnegative().nullable().optional(),
  respirationRate: z.number().int().nonnegative().nullable().optional(),
  bodyTemperature: z.number().nonnegative().nullable().optional(),
  roomTemperature: z.number().nonnegative().nullable().optional(),
  humidity: z.number().nonnegative().nullable().optional(),
  oxygenLevel: z.number().nonnegative().nullable().optional(),
  movement: z.union([z.string(), z.boolean()]).nullable().optional(),
  cryDetected: z.boolean().nullable().optional(),
  sleepStage: z.string().nullable().optional(),
  bedTemperature: z.number().nonnegative().nullable().optional(),
  batteryLevel: z.number().int().nonnegative().nullable().optional(),
  signalStrength: z.number().int().nullable().optional(),
  airQuality: z.number().int().nonnegative().nullable().optional(),
});

export const HistoryQuerySchema = z.object({
  from: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: 'Invalid from date format.',
  }).optional(),
  to: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: 'Invalid to date format.',
  }).optional(),
  limit: z.string().regex(/^\d+$/, { message: 'Limit must be a positive integer.' })
    .transform((val) => parseInt(val, 10))
    .optional(),
});
