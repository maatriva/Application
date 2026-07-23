import { Request } from 'express';
import { UserRole } from '@prisma/client';

export interface TokenPayload {
  userId: string;
  role: UserRole;
}

export interface AuthenticatedRequest extends Request {
  user?: TokenPayload;
}
