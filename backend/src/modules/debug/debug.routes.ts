import { Router } from 'express';
import { debugGate } from './debug.middleware';
import { DebugController } from './debug.controller';

const router = Router();

// Enable protection middleware for all developer debug routes
router.use(debugGate);

router.post('/telemetry', DebugController.submitTelemetry);
router.post('/alert', DebugController.submitAlert);
router.post('/device/offline', DebugController.setDeviceOffline);
router.post('/device/online', DebugController.setDeviceOnline);
router.post('/cry/start', DebugController.startCry);
router.post('/cry/stop', DebugController.stopCry);
router.post('/sensor/failure', DebugController.triggerSensorFailure);
router.get('/status', DebugController.getStatus);
router.get('/camera-simulator', DebugController.cameraSimulator);


// Support both DELETE and POST for resettings
router.delete('/reset', DebugController.resetData);
router.post('/reset', DebugController.resetData);

export default router;
