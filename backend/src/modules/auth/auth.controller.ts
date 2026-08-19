import { Request, Response } from 'express';
import { AuthService } from './auth.service';
import { RegisterSchema, LoginSchema, RefreshSchema } from './auth.validation';
import { AuthenticatedRequest } from './auth.types';
import { ZodIssue } from 'zod';

const authService = new AuthService();

export class AuthController {
  /**
   * POST /auth/register
   */
  public static async register(req: Request, res: Response) {
    const parseResult = RegisterSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed.',
        errors: parseResult.error.issues.map((err: ZodIssue) => err.message),
      });
    }

    try {
      const user = await authService.register({
        fullName: parseResult.data.fullName,
        email: parseResult.data.email,
        passwordPlain: parseResult.data.password,
        role: parseResult.data.role,
      });

      res.status(201).json({
        success: true,
        message: 'User registered successfully.',
        data: user,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Internal register error',
      });
    }
  }

  /**
   * POST /auth/login
   */
  public static async login(req: Request, res: Response) {
    const parseResult = LoginSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed.',
        errors: parseResult.error.issues.map((err: ZodIssue) => err.message),
      });
    }

    try {
      const data = await authService.login(
        parseResult.data.email,
        parseResult.data.password
      );

      res.json({
        success: true,
        message: 'Login successful.',
        data,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Internal login error',
      });
    }
  }

  /**
   * POST /auth/refresh
   */
  public static async refresh(req: Request, res: Response) {
    const parseResult = RefreshSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed.',
        errors: parseResult.error.issues.map((err: ZodIssue) => err.message),
      });
    }

    try {
      const data = await authService.refresh(parseResult.data.refreshToken);

      res.json({
        success: true,
        message: 'Token refreshed successfully.',
        data,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Internal refresh error',
      });
    }
  }

  /**
   * POST /auth/logout
   * Idempotent sign-out endpoint. Accepts refreshToken from body or Authorization header.
   */
  public static async logout(req: Request, res: Response) {
    let refreshToken = req.body?.refreshToken;
    if (!refreshToken && req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
      refreshToken = req.headers.authorization.split(' ')[1];
    }

    try {
      const result = await authService.logout(refreshToken || '');

      res.json({
        success: true,
        message: result.message,
        data: {},
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Internal logout error',
      });
    }
  }

  /**
   * GET /auth/profile
   */
  public static async profile(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: No session user found.',
      });
    }

    try {
      const user = await authService.getProfile(userId);

      res.json({
        success: true,
        message: 'Profile fetched successfully.',
        data: user,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Internal fetch profile error',
      });
    }
  }

  /**
   * PATCH /auth/profile
   */
  public static async updateProfile(req: AuthenticatedRequest, res: Response) {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: No session user found.',
      });
    }

    const { fullName, email } = req.body;
    if (!fullName && !email) {
      return res.status(400).json({
        success: false,
        message: 'At least one field (fullName, email) must be provided.',
      });
    }

    try {
      const updatedUser = await authService.updateProfile(userId, { fullName, email });
      res.json({
        success: true,
        message: 'Profile updated successfully.',
        data: updatedUser,
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      res.status(status).json({
        success: false,
        message: e.message || 'Internal update profile error',
      });
    }
  }
}
