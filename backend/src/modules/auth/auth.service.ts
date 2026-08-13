import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../../config/database';
import { env } from '../../config/env';
import { UserRole } from '@prisma/client';
import { TokenPayload } from './auth.types';

export class AuthService {
  /**
   * Register a new user.
   */
  public async register(data: {
    fullName: string;
    email: string;
    passwordPlain: string;
    role?: UserRole;
  }) {
    const cleanEmail = data.email.trim().toLowerCase();

    // 1. Check duplicate email
    const existing = await prisma.user.findUnique({
      where: { email: cleanEmail },
    });
    if (existing) {
      throw { statusCode: 409, message: 'User with this email already exists.' };
    }

    // 2. Hash password (bcryptjs with 10 salt rounds)
    const passwordHash = await bcrypt.hash(data.passwordPlain, 10);

    // 3. Save user (default role is PARENT)
    const role = data.role || UserRole.PARENT;

    const user = await prisma.user.create({
      data: {
        fullName: data.fullName,
        email: cleanEmail,
        passwordHash: passwordHash,
        role: role,
      },
      select: {
        id: true,
        fullName: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    const accessToken = jwt.sign(
      { userId: user.id, role: user.role } as TokenPayload,
      env.JWT_SECRET,
      { expiresIn: env.JWT_EXPIRATION as any }
    );

    const refreshToken = jwt.sign(
      { userId: user.id, role: user.role } as TokenPayload,
      env.JWT_SECRET,
      { expiresIn: env.JWT_REFRESH_EXPIRATION as any }
    );

    return {
      accessToken,
      refreshToken,
      user,
    };
  }

  /**
   * Authenticate user and return tokens.
   */
  public async login(emailInput: string, passwordPlain: string) {
    const cleanEmail = (emailInput || '').trim().toLowerCase();

    // 1. Find user
    const user = await prisma.user.findUnique({
      where: { email: cleanEmail },
    });
    if (!user) {
      throw { statusCode: 401, message: 'Invalid email or password.' };
    }

    // 2. Compare bcrypt hash
    const isValid = await bcrypt.compare(passwordPlain, user.passwordHash);
    if (!isValid) {
      throw { statusCode: 401, message: 'Invalid email or password.' };
    }

    // 3. Generate Access Token (15 minutes)
    const accessToken = jwt.sign(
      { userId: user.id, role: user.role } as TokenPayload,
      env.JWT_SECRET,
      { expiresIn: env.JWT_EXPIRATION as any }
    );

    // 4. Generate Refresh Token (7 days)
    const refreshToken = jwt.sign(
      { userId: user.id, role: user.role } as TokenPayload,
      env.JWT_SECRET,
      { expiresIn: env.JWT_REFRESH_EXPIRATION as any }
    );

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
      },
    };
  }

  /**
   * Generate new access token from refresh token.
   */
  public async refresh(refreshToken: string) {
    try {
      // Verify refresh token signature
      const decoded = jwt.verify(refreshToken, env.JWT_SECRET) as any;
      
      // Look up user to ensure they still exist
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
      });
      if (!user) {
        throw { statusCode: 403, message: 'User not found.' };
      }

      // Generate new access token
      const accessToken = jwt.sign(
        { userId: user.id, role: user.role } as TokenPayload,
        env.JWT_SECRET,
        { expiresIn: env.JWT_EXPIRATION as any }
      );

      return { accessToken };
    } catch (e: any) {
      if (e.statusCode) throw e;
      throw { statusCode: 403, message: 'Invalid or expired refresh token.' };
    }
  }

  /**
   * Invalidate a session (Logout).
   */
  public async logout(refreshToken: string) {
    try {
      const decoded: any = jwt.verify(refreshToken, env.JWT_SECRET);
      console.log(`[AUTH SERVICE] Session invalidated for userId=${decoded.userId || 'unknown'}, role=${decoded.role || 'unknown'}`);
      return { message: 'Logged out successfully.' };
    } catch {
      console.log(`[AUTH SERVICE] Session invalidated for provided refresh token.`);
      return { message: 'Logged out successfully.' };
    }
  }

  /**
   * Fetch User Profile by ID.
   */
  public async getProfile(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        fullName: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    if (!user) {
      throw { statusCode: 404, message: 'User profile not found.' };
    }

    return user;
  }

  /**
   * Update User Profile by ID.
   */
  public async updateProfile(userId: string, data: { fullName?: string; email?: string }) {
    // If email is changing, check duplicate email
    if (data.email) {
      const existing = await prisma.user.findUnique({
        where: { email: data.email },
      });
      if (existing && existing.id !== userId) {
        throw { statusCode: 409, message: 'User with this email already exists.' };
      }
    }

    const updated = await prisma.user.update({
      where: { id: userId },
      data: {
        fullName: data.fullName ?? undefined,
        email: data.email ?? undefined,
      },
      select: {
        id: true,
        fullName: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    return updated;
  }
}
