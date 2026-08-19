import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { prisma } from '../../config/database';
import { env } from '../../config/env';
import { UserRole } from '@prisma/client';
import { TokenPayload } from './auth.types';

function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

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
      { userId: user.id, role: user.role, jti: crypto.randomUUID() } as any,
      env.JWT_SECRET,
      { expiresIn: env.JWT_REFRESH_EXPIRATION as any }
    );

    // Create active server-side session (hashing refresh token)
    const tokenHash = hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await prisma.session.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt,
      },
    });

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
      { userId: user.id, role: user.role, jti: crypto.randomUUID() } as any,
      env.JWT_SECRET,
      { expiresIn: env.JWT_REFRESH_EXPIRATION as any }
    );

    // 5. Create active server-side session (storing SHA-256 hash of refresh token)
    const tokenHash = hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await prisma.session.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt,
      },
    });

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
   * Generate new access token from refresh token with token rotation and session verification.
   */
  public async refresh(refreshToken: string) {
    if (!refreshToken) {
      throw { statusCode: 401, message: 'Refresh token required.' };
    }

    let decoded: TokenPayload;
    try {
      decoded = jwt.verify(refreshToken, env.JWT_SECRET) as TokenPayload;
    } catch {
      throw { statusCode: 401, message: 'Invalid or expired refresh token.' };
    }

    // 1. Hash incoming refresh token and check active server-side session
    const tokenHash = hashToken(refreshToken);
    const session = await prisma.session.findUnique({
      where: { tokenHash },
    });

    if (
      !session ||
      session.revokedAt !== null ||
      session.expiresAt <= new Date() ||
      session.userId !== decoded.userId
    ) {
      throw { statusCode: 401, message: 'Invalid, expired, or revoked refresh token.' };
    }

    // 2. Look up user to ensure they still exist
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
    });
    if (!user) {
      throw { statusCode: 401, message: 'User not found.' };
    }

    // 3. Refresh token rotation: Revoke old session and issue a new session
    await prisma.session.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });

    const newAccessToken = jwt.sign(
      { userId: user.id, role: user.role } as TokenPayload,
      env.JWT_SECRET,
      { expiresIn: env.JWT_EXPIRATION as any }
    );

    const newRefreshToken = jwt.sign(
      { userId: user.id, role: user.role, jti: crypto.randomUUID() } as any,
      env.JWT_SECRET,
      { expiresIn: env.JWT_REFRESH_EXPIRATION as any }
    );

    const newTokenHash = hashToken(newRefreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await prisma.session.create({
      data: {
        userId: user.id,
        tokenHash: newTokenHash,
        expiresAt,
      },
    });

    return {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    };
  }

  /**
   * Invalidate a specific device session (Logout).
   */
  public async logout(refreshToken: string) {
    if (refreshToken && refreshToken.trim() !== '') {
      const tokenHash = hashToken(refreshToken);
      await prisma.session.updateMany({
        where: { tokenHash, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
    return { message: 'Logged out successfully.' };
  }

  /**
   * Revoke all active sessions for a user (e.g. security breach, password change).
   */
  public async revokeAllUserSessions(userId: string) {
    await prisma.session.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { message: 'All user sessions revoked successfully.' };
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
