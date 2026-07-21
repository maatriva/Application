import { Router, Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { Pool } from 'pg';
import { config } from '../config/config';

function authenticateToken(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).json({ error: 'Access token required.' });

  jwt.verify(token, config.jwtSecret, (err, decoded: any) => {
    if (err) return res.status(403).json({ error: 'Invalid token.' });
    req.body.user = decoded;
    next();
  });
}

export function createDevicesRouter(dbPool: Pool): Router {
  const router = Router();

  // POST /devices/pair (Pair a cradle/sensor device to a baby profile)
  router.post('/pair', authenticateToken, async (req: Request, res: Response) => {
    const { deviceId, deviceName, type, firmwareVersion, protocol, babyId } = req.body;

    if (!deviceId || !deviceName || !type || !babyId) {
      return res.status(400).json({ error: 'deviceId, deviceName, type, and babyId are required.' });
    }

    try {
      // 1. Insert device registry if it does not exist, otherwise update status
      await dbPool.query(
        `INSERT INTO devices (device_id, device_name, type, firmware_version, protocol, paired)
         VALUES ($1, $2, $3, $4, $5, TRUE)
         ON CONFLICT (device_id) DO UPDATE SET paired = TRUE, device_name = $2`,
        [deviceId, deviceName, type, firmwareVersion || '1.0.0', protocol || 'Wi-Fi']
      );

      // 2. Map assignment to baby
      await dbPool.query(
        `INSERT INTO device_assignments (device_id, baby_id)
         VALUES ($1, $2) ON CONFLICT (device_id, baby_id) DO NOTHING`,
        [deviceId, babyId]
      );

      res.status(201).json({ message: 'Device paired successfully.', deviceId, babyId });
    } catch (e: any) {
      res.status(500).json({ error: 'Internal pairing error', details: e.message });
    }
  });

  // GET /devices
  router.get('/', authenticateToken, async (req: Request, res: Response) => {
    const userId = req.body.user.userId;

    try {
      // Fetch devices assigned to user's babies
      const devices = await dbPool.query(
        `SELECT d.device_id as "deviceId", d.device_name as "deviceName", d.type, d.firmware_version as "firmwareVersion",
                d.protocol, d.battery, d.status, d.last_seen as "lastSeen", da.baby_id as "babyId"
         FROM devices d
         JOIN device_assignments da ON da.device_id = d.device_id
         JOIN babies b ON b.id = da.baby_id
         WHERE b.parent_id = $1 OR EXISTS (
           SELECT 1 FROM caregivers c WHERE c.baby_id = b.id AND c.user_id = $1 AND c.status = 'accepted'
         )`,
        [userId]
      );
      res.json(devices.rows);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal fetch devices error', details: e.message });
    }
  });

  // GET /devices/:id/latest (Get latest telemetry vitals map)
  router.get('/:id/latest', authenticateToken, async (req: Request, res: Response) => {
    const deviceId = req.params.id;

    try {
      const latestRes = await dbPool.query(
        `SELECT DISTINCT ON (sensor_type) sensor_type as "sensorType", value, unit, quality, timestamp
         FROM telemetry
         WHERE device_id = $1
         ORDER BY sensor_type, timestamp DESC`,
        [deviceId]
      );
      res.json(latestRes.rows);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal fetch latest telemetry error', details: e.message });
    }
  });

  // GET /devices/:id/history (TimescaleDB partitioned query for analytics charts)
  router.get('/:id/history', authenticateToken, async (req: Request, res: Response) => {
    const deviceId = req.params.id;
    const sensorType = req.query.type as string;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;

    if (!sensorType) {
      return res.status(400).json({ error: 'sensorType query parameter is required (e.g. ?type=heart_rate).' });
    }

    try {
      const historyRes = await dbPool.query(
        `SELECT timestamp, value, unit, quality
         FROM telemetry
         WHERE device_id = $1 AND sensor_type = $2
         ORDER BY timestamp DESC
         LIMIT $3`,
        [deviceId, sensorType, limit]
      );
      res.json(historyRes.rows.reverse()); // return chronological order for charting
    } catch (e: any) {
      res.status(500).json({ error: 'Internal fetch telemetry history error', details: e.message });
    }
  });

  // GET /devices/:id/alerts
  router.get('/:id/alerts', authenticateToken, async (req: Request, res: Response) => {
    const deviceId = req.params.id;
    const acknowledged = req.query.acknowledged === 'true';

    try {
      const alertsRes = await dbPool.query(
        `SELECT id, severity, type, message, value, threshold_limit as "thresholdLimit", timestamp, acknowledged
         FROM alerts
         WHERE device_id = $1 AND acknowledged = $2
         ORDER BY timestamp DESC`,
        [deviceId, acknowledged]
      );
      res.json(alertsRes.rows);
    } catch (e: any) {
      res.status(500).json({ error: 'Internal fetch alerts error', details: e.message });
    }
  });

  return router;
}
