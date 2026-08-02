import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../middleware/auth.middleware';
import { BabyService } from './baby.service';
import { CreateBabySchema, UpdateBabySchema } from './baby.validation';
import { ZodIssue } from 'zod';

const babyService = new BabyService();

/**
 * Maps the database Baby model properties to the expected API response format.
 */
function formatBabyResponse(baby: any) {
  if (!baby) return null;
  const { birthDate, deletedAt, caregivers, ...rest } = baby;
  const accessLevel = caregivers && caregivers.length > 0 ? caregivers[0].accessLevel : 'parent';
  return {
    ...rest,
    accessLevel,
    dateOfBirth: birthDate ? birthDate.toISOString().split('T')[0] : null,
  };
}

export class BabyController {
  /**
   * POST /babies
   * Create a baby profile. Authenticated parent only.
   */
  public static async create(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    const parentId = req.user?.userId;
    if (!parentId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Authentication required.',
      });
    }

    const parseResult = CreateBabySchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed.',
        errors: parseResult.error.issues.map((err: ZodIssue) => err.message),
      });
    }

    try {
      const baby = await babyService.createBaby(parentId, parseResult.data);
      return res.status(201).json({
        success: true,
        message: 'Baby profile created successfully.',
        data: formatBabyResponse(baby),
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      return res.status(status).json({
        success: false,
        message: e.message || 'Internal baby creation error.',
      });
    }
  }

  /**
   * GET /babies
   * Return all babies belonging to logged-in parent.
   */
  public static async list(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    const parentId = req.user?.userId;
    if (!parentId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Authentication required.',
      });
    }

    try {
      const babies = await babyService.listBabies(parentId);
      return res.status(200).json({
        success: true,
        message: 'Babies fetched successfully.',
        data: babies.map(formatBabyResponse),
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      return res.status(status).json({
        success: false,
        message: e.message || 'Internal fetch babies error.',
      });
    }
  }

  /**
   * GET /babies/:id
   * Return baby details. Only owner can access.
   */
  public static async getById(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    const parentId = req.user?.userId;
    const babyId = req.params.id;

    if (!parentId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Authentication required.',
      });
    }

    try {
      const baby = await babyService.getBabyById(babyId, parentId);
      return res.status(200).json({
        success: true,
        message: 'Baby details fetched successfully.',
        data: formatBabyResponse(baby),
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      return res.status(status).json({
        success: false,
        message: e.message || 'Internal fetch baby error.',
      });
    }
  }

  /**
   * PUT /babies/:id
   * Update baby profile. Only owner can access.
   */
  public static async update(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    const parentId = req.user?.userId;
    const babyId = req.params.id;

    if (!parentId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Authentication required.',
      });
    }

    const parseResult = UpdateBabySchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed.',
        errors: parseResult.error.issues.map((err: ZodIssue) => err.message),
      });
    }

    try {
      const updatedBaby = await babyService.updateBaby(babyId, parentId, parseResult.data);
      return res.status(200).json({
        success: true,
        message: 'Baby profile updated successfully.',
        data: formatBabyResponse(updatedBaby),
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      return res.status(status).json({
        success: false,
        message: e.message || 'Internal update baby error.',
      });
    }
  }

  /**
   * DELETE /babies/:id
   * Soft delete baby profile. Only owner can access.
   */
  public static async delete(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    const parentId = req.user?.userId;
    const babyId = req.params.id;

    if (!parentId) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Authentication required.',
      });
    }

    try {
      await babyService.deleteBaby(babyId, parentId);
      return res.status(200).json({
        success: true,
        message: 'Baby profile soft-deleted successfully.',
        data: {},
      });
    } catch (e: any) {
      const status = e.statusCode || 500;
      return res.status(status).json({
        success: false,
        message: e.message || 'Internal delete baby error.',
      });
    }
  }
}
