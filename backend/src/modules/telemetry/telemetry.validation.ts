import { z } from 'zod';

const deviceIdRegex = /^[A-Za-z0-9\-_]{3,100}$/;

const isFiniteNumber = (val: number | null | undefined) =>
  val === null || val === undefined || (typeof val === 'number' && Number.isFinite(val));

const isValidTimestamp = (val: string) => {
  const parsed = Date.parse(val);
  if (isNaN(parsed)) return false;
  const now = Date.now();
  const time = new Date(val).getTime();
  // Timestamp cannot be more than 24 hours in the future or older than 30 days
  const futureLimit = now + 24 * 60 * 60 * 1000;
  const pastLimit = now - 30 * 24 * 60 * 60 * 1000;
  return time <= futureLimit && time >= pastLimit;
};

export const TelemetryPayloadSchema = z.object({
  deviceId: z.string().min(3).max(100).regex(deviceIdRegex, { message: 'deviceId contains invalid characters.' }),
  timestamp: z.string().refine(isValidTimestamp, { message: 'Invalid timestamp: must be valid ISO string within past 30 days and future 24h.' }),
  heartRate: z
    .number()
    .int()
    .min(0, { message: 'heartRate cannot be negative.' })
    .max(300, { message: 'heartRate exceeds realistic physiological limits.' })
    .refine(isFiniteNumber, { message: 'heartRate must be a finite number.' })
    .nullable()
    .optional(),
  respirationRate: z
    .number()
    .int()
    .min(0, { message: 'respirationRate cannot be negative.' })
    .max(150, { message: 'respirationRate exceeds realistic limits.' })
    .refine(isFiniteNumber, { message: 'respirationRate must be a finite number.' })
    .nullable()
    .optional(),
  bodyTemperature: z
    .number()
    .min(20, { message: 'bodyTemperature below minimum range.' })
    .max(50, { message: 'bodyTemperature exceeds maximum range.' })
    .refine(isFiniteNumber, { message: 'bodyTemperature must be a finite number.' })
    .nullable()
    .optional(),
  roomTemperature: z
    .number()
    .min(-20, { message: 'roomTemperature below minimum range.' })
    .max(60, { message: 'roomTemperature exceeds maximum range.' })
    .refine(isFiniteNumber, { message: 'roomTemperature must be a finite number.' })
    .nullable()
    .optional(),
  humidity: z
    .number()
    .min(0, { message: 'humidity cannot be negative.' })
    .max(100, { message: 'humidity cannot exceed 100%.' })
    .refine(isFiniteNumber, { message: 'humidity must be a finite number.' })
    .nullable()
    .optional(),
  movementDetected: z.boolean().nullable().optional(),
  cryDetected: z.boolean().nullable().optional(),
  sleepStage: z.string().nullable().optional(),
  airQuality: z
    .number()
    .int()
    .min(0)
    .max(1000)
    .refine(isFiniteNumber, { message: 'airQuality must be a finite number.' })
    .nullable()
    .optional(),
  batteryLevel: z
    .number()
    .int()
    .min(0)
    .max(100)
    .refine(isFiniteNumber, { message: 'batteryLevel must be between 0 and 100.' })
    .nullable()
    .optional(),
});

export const IngestTelemetrySchema = z.object({
  deviceId: z.string().min(3).max(100).regex(deviceIdRegex, { message: 'deviceId contains invalid characters.' }),
  timestamp: z.string().refine(isValidTimestamp, { message: 'Invalid timestamp: must be valid ISO string within past 30 days and future 24h.' }),
  heartRate: z
    .number()
    .int()
    .min(0)
    .max(300)
    .refine(isFiniteNumber)
    .nullable()
    .optional(),
  breathingRate: z
    .number()
    .int()
    .min(0)
    .max(150)
    .refine(isFiniteNumber)
    .nullable()
    .optional(),
  respirationRate: z
    .number()
    .int()
    .min(0)
    .max(150)
    .refine(isFiniteNumber)
    .nullable()
    .optional(),
  bodyTemperature: z
    .number()
    .min(20)
    .max(50)
    .refine(isFiniteNumber)
    .nullable()
    .optional(),
  roomTemperature: z
    .number()
    .min(-20)
    .max(60)
    .refine(isFiniteNumber)
    .nullable()
    .optional(),
  humidity: z
    .number()
    .min(0)
    .max(100)
    .refine(isFiniteNumber)
    .nullable()
    .optional(),
  oxygenLevel: z
    .number()
    .min(0)
    .max(100)
    .refine(isFiniteNumber)
    .nullable()
    .optional(),
  movement: z.union([z.string(), z.boolean()]).nullable().optional(),
  cryDetected: z.boolean().nullable().optional(),
  sleepStage: z.string().nullable().optional(),
  bedTemperature: z.number().nullable().optional(),
  batteryLevel: z
    .number()
    .int()
    .min(0)
    .max(100)
    .refine(isFiniteNumber)
    .nullable()
    .optional(),
  signalStrength: z.number().int().nullable().optional(),
  airQuality: z
    .number()
    .int()
    .min(0)
    .max(1000)
    .refine(isFiniteNumber)
    .nullable()
    .optional(),
});

export const HistoryQuerySchema = z.object({
  from: z
    .string()
    .refine((val) => !isNaN(Date.parse(val)), {
      message: 'Invalid from date format.',
    })
    .optional(),
  to: z
    .string()
    .refine((val) => !isNaN(Date.parse(val)), {
      message: 'Invalid to date format.',
    })
    .optional(),
  limit: z
    .string()
    .regex(/^\d+$/, { message: 'Limit must be a positive integer.' })
    .transform((val) => parseInt(val, 10))
    .optional(),
});
