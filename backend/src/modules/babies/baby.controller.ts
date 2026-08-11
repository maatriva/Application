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
  const { birthDate, deletedAt, caregivers, temporaryCaregiverPermissions, ...rest } = baby;
  let accessLevel = 'parent';
  if (caregivers && caregivers.length > 0) {
    accessLevel = caregivers[0]?.accessLevel || 'parent';
  } else if (temporaryCaregiverPermissions && temporaryCaregiverPermissions.length > 0) {
    accessLevel = temporaryCaregiverPermissions[0]?.permission || 'LIVE_MONITOR_ONLY';
  }

  let dateOfBirth: string | null = null;
  if (birthDate) {
    if (birthDate instanceof Date && !isNaN(birthDate.getTime())) {
      dateOfBirth = birthDate.toISOString().split('T')[0];
    } else if (typeof birthDate === 'string') {
      dateOfBirth = birthDate.split('T')[0];
    } else {
      try {
        const parsed = new Date(birthDate);
        if (!isNaN(parsed.getTime())) {
          dateOfBirth = parsed.toISOString().split('T')[0];
        }
      } catch {
        dateOfBirth = null;
      }
    }
  }

  return {
    ...rest,
    accessLevel,
    dateOfBirth,
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
      console.error('[Parent] POST /babies error:', e);
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
      console.log(`[Parent] Logged-in userId: ${parentId}`);
      console.log(`[Parent] GET /babies`);
      const babies = await babyService.listBabies(parentId);
      const formattedBabies = babies.map(formatBabyResponse).filter((b): b is NonNullable<typeof b> => b !== null);
      const babyIds = formattedBabies.map((b: any) => b.id).join(', ');
      const currentBabyName = formattedBabies.length > 0 ? formattedBabies[0].name : 'None';

      console.log(`[Parent] Response status: 200`);
      console.log(`[Parent] Babies returned: ${formattedBabies.length}`);
      console.log(`[Parent] Baby IDs: ${babyIds}`);
      console.log(`[Parent] Current baby: ${currentBabyName}`);

      return res.status(200).json({
        success: true,
        message: 'Babies fetched successfully.',
        data: formattedBabies,
      });
    } catch (e: any) {
      console.error(`[Parent] GET /babies error:`, e);
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
