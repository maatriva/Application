import { z } from 'zod';

const deviceIdRegex = /^[A-Za-z0-9\-_]{3,100}$/;

export const RegisterDeviceSchema = z.object({
  deviceId: z
    .string()
    .min(3, { message: 'deviceId must be at least 3 characters.' })
    .max(100, { message: 'deviceId must not exceed 100 characters.' })
    .regex(deviceIdRegex, { message: 'deviceId contains invalid characters.' }),
  deviceName: z.string().min(1, { message: 'deviceName is required.' }),
  type: z.string().min(1, { message: 'type is required.' }),
  registrationKey: z.string().optional(),
  firmwareVersion: z.string().optional(),
  protocol: z.string().optional(),
});

export const PairDeviceSchema = z.object({
  registrationKey: z.string().min(1, { message: 'registrationKey is required.' }),
  babyId: z.string().uuid({ message: 'Invalid babyId format. Must be a valid UUID.' }),
});
