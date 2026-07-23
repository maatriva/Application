import { z } from 'zod';

export const CreateBabySchema = z.object({
  name: z.string().min(1, { message: 'Name is required.' }),
  gender: z.string().min(1, { message: 'Gender is required.' }),
  dateOfBirth: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: 'Invalid date format for dateOfBirth. Please use YYYY-MM-DD or standard ISO format.',
  }),
  bloodGroup: z.string().optional(),
  birthWeight: z.number().positive({ message: 'Birth weight must be a positive number.' }).optional(),
  birthHeight: z.number().positive({ message: 'Birth height must be a positive number.' }).optional(),
  photoUrl: z.string().url({ message: 'Invalid photo URL format.' }).or(z.string().length(0)).optional(),
});

export const UpdateBabySchema = z.object({
  name: z.string().min(1, { message: 'Name cannot be empty.' }).optional(),
  gender: z.string().min(1, { message: 'Gender cannot be empty.' }).optional(),
  dateOfBirth: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: 'Invalid date format for dateOfBirth. Please use YYYY-MM-DD or standard ISO format.',
  }).optional(),
  bloodGroup: z.string().optional(),
  birthWeight: z.number().positive({ message: 'Birth weight must be a positive number.' }).optional(),
  birthHeight: z.number().positive({ message: 'Birth height must be a positive number.' }).optional(),
  photoUrl: z.string().url({ message: 'Invalid photo URL format.' }).or(z.string().length(0)).optional(),
});
