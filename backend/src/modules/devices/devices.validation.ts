import { z } from 'zod';

export const RegisterDeviceSchema = z.object({
  deviceId: z.string().min(1, { message: 'deviceId is required.' }),
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
