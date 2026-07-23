import { z } from 'zod';
import { UserRole } from '@prisma/client';

export const RegisterSchema = z.object({
  fullName: z.string().min(1, { message: 'Full name is required.' }),
  email: z.string().email({ message: 'Invalid email format.' }),
  password: z.string().min(8, { message: 'Password must be at least 8 characters long.' }),
  role: z.nativeEnum(UserRole).optional(),
});

export const LoginSchema = z.object({
  email: z.string().email({ message: 'Invalid email format.' }),
  password: z.string().min(1, { message: 'Password is required.' }),
});

export const RefreshSchema = z.object({
  refreshToken: z.string().min(1, { message: 'Refresh token is required.' }),
});
