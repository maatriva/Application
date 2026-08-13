import { Router } from 'express';
import authRoutes from '../modules/auth/auth.routes';
import babyRoutes from '../modules/babies/baby.routes';
import caregiversRoutes from '../modules/caregivers/caregivers.routes';
import devicesRoutes from '../modules/devices/devices.routes';
import aiRoutes from '../modules/ai/ai.routes';
import usersRoutes from '../modules/users/users.routes';
import cradleRoutes from '../modules/cradle/cradle.routes';
import sensorsRoutes from '../modules/sensors/sensors.routes';
import alertsRoutes from '../modules/alerts/alerts.routes';
import reportsRoutes from '../modules/reports/reports.routes';
import doctorsRoutes from '../modules/doctors/doctors.routes';
import notificationsRoutes from '../modules/notifications/notifications.routes';
import musicRoutes from '../modules/music/music.routes';
import telemetryRoutes from '../modules/telemetry/telemetry.routes';
import debugRoutes from '../modules/debug/debug.routes';

import { env } from '../config/env';

const router = Router();

// Register module routes
router.use('/auth', authRoutes);
router.use('/babies', babyRoutes);
router.use('/caregivers', caregiversRoutes);
router.use('/caregiver', caregiversRoutes);
router.use('/devices', devicesRoutes);
router.use('/ai', aiRoutes);
router.use('/users', usersRoutes);
router.use('/cradle', cradleRoutes);
router.use('/sensors', sensorsRoutes);
router.use('/alerts', alertsRoutes);
router.use('/reports', reportsRoutes);
router.use('/doctors', doctorsRoutes);
router.use('/notifications', notificationsRoutes);
router.use('/music', musicRoutes);
router.use('/telemetry', telemetryRoutes);

// Debug routes are ONLY mounted when NOT in production AND DEBUG_MODE is explicitly enabled
if (env.isDebugEnabled) {
  router.use('/debug', debugRoutes);
}

export default router;
