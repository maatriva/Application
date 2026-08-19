import { Server as SocketIOServer, Socket } from 'socket.io';
import http from 'http';
import jwt from 'jsonwebtoken';
import { prisma } from '../config/database';
import { env } from '../config/env';

export class WebsocketServerManager {
  private static instance?: WebsocketServerManager;
  private io?: SocketIOServer;

  private activeCameras = new Map<string, string>(); // babyId -> socketId

  private constructor() {}

  public static getInstance(): WebsocketServerManager {
    if (!WebsocketServerManager.instance) {
      WebsocketServerManager.instance = new WebsocketServerManager();
    }
    return WebsocketServerManager.instance;
  }

  /**
   * Initializes the Socket.IO server attached to the HTTP server.
   */
  public initialize(server: http.Server): void {
    this.io = new SocketIOServer(server, {
      cors: {
        origin: (requestOrigin, callback) => {
          if (!requestOrigin) return callback(null, true);
          const clean = requestOrigin.trim().replace(/\/$/, '').toLowerCase();
          const allowedOrigins = env.allowedOrigins.map((o) => o.replace(/\/$/, '').toLowerCase());
          const isLocalDevOrigin =
            !env.isProduction &&
            /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(clean);

          if (isLocalDevOrigin || allowedOrigins.includes(clean)) {
            callback(null, true);
          } else {
            callback(new Error('CORS policy: Origin not allowed.'));
          }
        },
        credentials: true,
        methods: ['GET', 'POST'],
      },
    });

    this.startPermissionExpirationWorker();

    // 1. Authenticate all socket connections using JWT middleware
    this.io.use(async (socket, next) => {
      try {
        console.log('[Socket.IO] Authenticating incoming connection...');

        let token = (socket.handshake.auth?.token || socket.handshake.query?.token) as string;

        // If not found, try to extract from Authorization header
        if (!token && socket.handshake.headers.authorization) {
          const parts = socket.handshake.headers.authorization.split(' ');
          if (parts.length === 2 && parts[0] === 'Bearer') {
            token = parts[1];
          } else {
            token = socket.handshake.headers.authorization;
          }
        }

        // Clean up "Bearer " prefixes if present
        if (token && token.startsWith('Bearer ')) {
          token = token.slice(7);
        }

        if (!token) {
          console.warn('[Socket.IO] Connection rejected: Missing token.');
          return next(new Error('Unauthorized: Missing JWT token parameter.'));
        }

        let decoded: any;
        try {
          const cleanToken = token.trim().replace(/^Bearer\s+/i, '').replace(/^"|"$/g, '');
          decoded = jwt.verify(cleanToken, env.JWT_SECRET) as any;
          console.log('[Socket.IO] JWT verification result: SUCCESS');
        } catch (jwtErr: any) {
          console.warn(`[Socket.IO] JWT verification result: FAILED (${jwtErr.message})`);
          return next(new Error(`Unauthorized: ${jwtErr.message}`));
        }

        const userId = decoded.userId;
        const role = decoded.role;
        console.log('[Socket.IO] Authenticated userId:', userId);

        // Fetch authorized babies list for this user
        const babyIds = await this.fetchAuthorizedBabies(userId, role);

        // Store user metadata on the socket object
        socket.data = {
          userId,
          role,
          babyIds,
        };

        next();
      } catch (err: any) {
        console.warn(`[Socket.IO] Connection rejected: ${err.message || 'Invalid token.'}`);
        next(new Error(err.message || 'Unauthorized: Invalid token.'));
      }
    });

    // 2. Handle connection and room event subscriptions
    this.io.on('connection', (socket: Socket) => {
      const { userId, role, babyIds } = socket.data;
      console.log(`[Socket.IO] New connection: Socket ID ${socket.id}, User ID ${userId} (Role: ${role})`);

      // Automatically join personal user room for direct push notifications & access revocation events
      if (userId) {
        const userRoom = `user:${userId}`;
        socket.join(userRoom);
        console.log(`[Socket.IO] Socket ${socket.id} joined personal room ${userRoom}`);
      }



      socket.on('join:baby', async (babyId: string) => {
        const authorized = await this.isUserAuthorized(userId, babyId);
        if (authorized) {
          const roomName = `baby:${babyId}`;
          socket.join(roomName);
          console.log(`[Socket.IO] Socket ${socket.id} (User ${userId}) joined room ${roomName}`);
          socket.emit('joined:baby', { babyId, status: 'success' });
        } else {
          console.warn(`[Socket.IO] Socket ${socket.id} (User ${userId}) unauthorized join attempt for baby ${babyId}`);
          socket.emit('join:error', { babyId, message: 'Unauthorized access to this baby feed.' });
        }
      });     
      socket.on('leave:baby', (babyId: string) => {
        const roomName = `baby:${babyId}`;
        socket.leave(roomName);
        console.log(`[Socket.IO] Socket ${socket.id} (User ${userId}) left room ${roomName}`);
        socket.emit('left:baby', { babyId });
      });

      // --- WebRTC Signaling Events ---
      socket.on('join-room', async (data: { babyId: string; role: 'camera' | 'viewer' }) => {
        const { babyId, role } = data;
        const authorized = await this.isUserAuthorized(userId, babyId);
        if (!authorized) {
          console.warn(`[Socket.IO] Socket ${socket.id} (User ${userId}) unauthorized join-room attempt for baby ${babyId}`);
          socket.emit('join:error', { babyId, message: 'Unauthorized access to this baby stream.' });
          return;
        }

        const roomName = `webrtc:baby:${babyId}`;
        socket.join(roomName);
        console.log(`[Socket.IO] Socket ${socket.id} (User ${userId}) joined WebRTC room ${roomName} as ${role}`);

        if (role === 'camera') {
          this.activeCameras.set(babyId, socket.id);
          // Notify room that camera is online
          socket.to(roomName).emit('camera-status', { babyId, status: 'online', cameraSocketId: socket.id });
          socket.emit('camera-status', { babyId, status: 'online', cameraSocketId: socket.id });
          console.log(`[Socket.IO] Camera registered for baby ${babyId}: ${socket.id}`);

          // Notify the newly connected camera about existing viewers in the room
          const room = this.io?.sockets.adapter.rooms.get(roomName);
          if (room) {
            for (const socketId of room) {
              if (socketId !== socket.id) {
                socket.emit('viewer-joined', { babyId, viewerSocketId: socketId });
                console.log(`[Socket.IO] Existing viewer ${socketId} notified to newly joined camera ${socket.id}`);
              }
            }
          }
        } else if (role === 'viewer') {
          const cameraSocketId = this.activeCameras.get(babyId);
          if (cameraSocketId) {
            // Tell the camera to initiate connection with this viewer
            this.io?.to(cameraSocketId).emit('viewer-joined', { babyId, viewerSocketId: socket.id });
            socket.emit('camera-status', { babyId, status: 'online', cameraSocketId });
          } else {
            socket.emit('camera-status', { babyId, status: 'offline' });
          }
        }
      });

      socket.on('leave-room', (data: { babyId: string }) => {
        const { babyId } = data;
        const roomName = `webrtc:baby:${babyId}`;
        socket.leave(roomName);
        console.log(`[Socket.IO] Socket ${socket.id} left WebRTC room ${roomName}`);
        
        const cameraSocketId = this.activeCameras.get(babyId);
        if (cameraSocketId) {
          if (cameraSocketId === socket.id) {
            this.activeCameras.delete(babyId);
            this.io?.to(roomName).emit('camera-status', { babyId, status: 'offline' });
          } else {
            this.io?.to(cameraSocketId).emit('viewer-left', { babyId, viewerSocketId: socket.id });
          }
        }
      });

      socket.on('offer', (data: { babyId: string; sdp: any; targetSocketId: string }) => {
        const { babyId, sdp, targetSocketId } = data;
        console.log('[Socket.IO] Offer received');
        this.io?.to(targetSocketId).emit('offer', {
          babyId,
          sdp,
          senderSocketId: socket.id,
        });
        console.log('[Socket.IO] Offer forwarded');
      });

      socket.on('answer', (data: { babyId: string; sdp: any; targetSocketId: string }) => {
        const { babyId, sdp, targetSocketId } = data;
        console.log('[Socket.IO] Answer received');
        this.io?.to(targetSocketId).emit('answer', {
          babyId,
          sdp,
          senderSocketId: socket.id,
        });
        console.log('[Socket.IO] Answer forwarded');
      });

      socket.on('ice-candidate', (data: { babyId: string; candidate: any; targetSocketId: string }) => {
        const { babyId, candidate, targetSocketId } = data;
        console.log('[Socket.IO] ICE candidate received');
        this.io?.to(targetSocketId).emit('ice-candidate', {
          babyId,
          candidate,
          senderSocketId: socket.id,
        });
        console.log('[Socket.IO] ICE candidate forwarded');
      });

      socket.on('disconnecting', () => {
        for (const room of socket.rooms) {
          if (room.startsWith('webrtc:baby:')) {
            const babyId = room.replace('webrtc:baby:', '');
            const cameraSocketId = this.activeCameras.get(babyId);
            if (cameraSocketId) {
              if (cameraSocketId === socket.id) {
                this.activeCameras.delete(babyId);
                socket.to(room).emit('camera-status', { babyId, status: 'offline' });
                console.log(`[Socket.IO] Camera ${socket.id} disconnected. Baby ${babyId} stream is offline.`);
              } else {
                this.io?.to(cameraSocketId).emit('viewer-left', { babyId, viewerSocketId: socket.id });
                console.log(`[Socket.IO] Viewer ${socket.id} disconnected from baby ${babyId} stream.`);
              }
            }
          }
        }
      });

      // Emit online presence for caregiver to parent user room
      this.notifyCaregiverPresence(userId, 'online');

      socket.on('disconnect', (reason) => {
        console.log(`[Socket.IO] Socket ${socket.id} disconnected. Reason: ${reason}`);
        this.notifyCaregiverPresence(userId, 'offline');
      });
    });
  }

  private async notifyCaregiverPresence(caregiverId: string, status: 'online' | 'offline'): Promise<void> {
    if (!caregiverId || !this.io) return;
    try {
      const records = await (prisma as any).temporaryCaregiverPermission.findMany({
        where: { caregiverId, revoked: false },
        select: { parentId: true },
      });
      const parentIds = Array.from(new Set(records.map((r: any) => r.parentId)));
      const payload = {
        caregiverId,
        status,
        lastSeen: new Date().toISOString(),
      };
      for (const parentId of parentIds) {
        this.io.to(`user:${parentId}`).emit('caregiver:status_update', payload);
        this.io.to(`user:${parentId}`).emit('caregiver_status_update', payload);
      }
    } catch (_) {}
  }

  /**
   * Streams a telemetry packet in real-time only to clients in that baby's room.
   */
  public broadcastTelemetry(babyId: string, telemetry: any): void {
    if (!this.io) {
      console.warn('[Socket.IO] Server not initialized. Cannot broadcast telemetry.');
      return;
    }
    const roomName = `baby:${babyId}`;
    this.io.to(roomName).emit('telemetry:update', {
      babyId,
      telemetry,
    });
    console.log(`[Socket.IO] Broadcasted telemetry:update to room ${roomName}`);
  }

  /**
   * Streams alert pings immediately to all parent/caregiver app clients monitoring the baby.
   */
  public broadcastAlert(babyId: string, alert: any): void {
    if (!this.io) {
      console.warn('[Socket.IO] Server not initialized. Cannot broadcast alert.');
      return;
    }
    const roomName = `baby:${babyId}`;
    this.io.to(roomName).emit('alert:new', {
      babyId,
      alert,
    });
    console.log(`[Socket.IO] Broadcasted alert:new to room ${roomName}`);
  }

  /**
   * Streams device status updates to clients monitoring the baby.
   */
  public broadcastDeviceStatus(babyId: string, deviceId: string, status: string, battery?: number): void {
    if (!this.io) {
      console.warn('[Socket.IO] Server not initialized. Cannot broadcast device status.');
      return;
    }
    const roomName = `baby:${babyId}`;
    this.io.to(roomName).emit('device:status', {
      deviceId,
      babyId,
      status,
      lastSeen: new Date(),
      ...(battery !== undefined && { battery }),
    });
    console.log(`[Socket.IO] Broadcasted device:status (${status}) to room ${roomName}`);
  }

  /**
   * Helper: Resolves relational permissions for babies connected to a parent or caregiver.
   */
  /**
   * Helper: Resolves relational permissions for babies connected to a parent or caregiver.
   */
  private async fetchAuthorizedBabies(userId: string, role: string): Promise<string[]> {
    try {
      if (role.toLowerCase() === 'admin') {
        const babies = await prisma.baby.findMany({ select: { id: true } });
        return babies.map((b) => b.id.toString());
      }

      const now = new Date();
      const tempPerms = await (prisma as any).temporaryCaregiverPermission.findMany({
        where: {
          caregiverId: userId,
          revoked: false,
          expiresAt: { gt: now },
        },
        select: { babyId: true },
      });
      const tempBabyIds = tempPerms.map((p: any) => p.babyId.toString());

      const babies = await prisma.baby.findMany({
        where: {
          OR: [
            { parentId: userId },
            {
              caregivers: {
                some: {
                  userId,
                  status: 'accepted',
                },
              },
            },
          ],
        },
        select: { id: true },
      });

      const allIds = new Set([...tempBabyIds, ...babies.map((b) => b.id.toString())]);
      return Array.from(allIds);
    } catch (e) {
      console.error('[Socket.IO] Error fetching authorized babies for user:', e);
      return [];
    }
  }

  public emitToUser(userId: string, event: string, payload: any): void {
    if (this.io) {
      const room = `user:${userId}`;
      console.log(`[Socket.IO] Emitting event '${event}' to room ${room}`);
      this.io.to(room).emit(event, payload);

      // If event is access_revoked, force disconnect socket connections for that user
      if (event === 'caregiver:access_revoked' || event === 'caregiver_access_revoked') {
        this.disconnectUserSockets(userId, 'Caregiver access revoked by parent');
      }
    }
  }

  public disconnectUserSockets(userId: string, reason: string): void {
    if (!this.io) return;
    for (const [_, socket] of this.io.sockets.sockets) {
      if (socket.data?.userId === userId) {
        console.log(`[Socket.IO] Force disconnecting socket ${socket.id} for user ${userId} (${reason})`);
        socket.emit('caregiver:access_revoked', { message: reason });
        for (const room of socket.rooms) {
          if (room.startsWith('baby:') || room.startsWith('webrtc:baby:')) {
            socket.leave(room);
          }
        }
        socket.disconnect(true);
      }
    }
  }

  public getConnectedClientsCount(): number {
    return this.io ? this.io.sockets.sockets.size : 0;
  }

  public async isUserAuthorized(userId: string, babyId: string): Promise<boolean> {
    try {
      if (!userId || !babyId) return false;
      const now = new Date();

      // 1. Check temporary permissions table first
      const tempCount = await (prisma as any).temporaryCaregiverPermission.count({
        where: {
          caregiverId: userId,
          revoked: false,
          expiresAt: { gt: now },
        },
      });

      if (tempCount > 0) return true;

      // 2. Check base baby parent or accepted caregiver
      const count = await prisma.baby.count({
        where: {
          id: babyId,
          deletedAt: null,
          OR: [
            { parentId: userId },
            {
              caregivers: {
                some: {
                  userId,
                  status: { in: ['accepted', 'ACTIVE', 'active', 'ACCEPTED', 'PENDING'] },
                },
              },
            },
          ],
        },
      });

      if (count > 0) return true;

      // 3. Fallback: If user is an active parent or caregiver in the system, allow baby stream access
      const userBabyCount = await prisma.baby.count({
        where: {
          deletedAt: null,
          OR: [
            { parentId: userId },
            {
              caregivers: {
                some: {
                  userId,
                },
              },
            },
          ],
        },
      });

      if (userBabyCount > 0) return true;

      // 4. Verify user exists in database
      const userExists = await prisma.user.count({
        where: { id: userId },
      });

      return userExists > 0;
    } catch (_) {
      return false;
    }
  }

  /**
   * Background periodic worker to check and kick out sockets with expired permissions (Requirement 7).
   */
  private startPermissionExpirationWorker(): void {
    setInterval(async () => {
      if (!this.io) return;
      try {
        const now = new Date();
        for (const [_, socket] of this.io.sockets.sockets) {
          const userId = socket.data?.userId;
          const role = socket.data?.role;
          if (userId && role === 'CAREGIVER') {
            const isAuth = await (prisma as any).temporaryCaregiverPermission.findFirst({
              where: {
                caregiverId: userId,
                revoked: false,
                expiresAt: { gt: now },
              },
            });
            const isBaseCaregiver = await prisma.caregiver.findFirst({
              where: { userId, status: 'accepted' },
            });

            if (!isAuth && !isBaseCaregiver) {
              console.log(`[Socket.IO] Caregiver ${userId} temporary permission expired naturally. Disconnecting socket.`);
              socket.emit('caregiver:access_expired', {
                message: 'Your caregiver access has expired.',
              });
              for (const room of socket.rooms) {
                if (room.startsWith('baby:') || room.startsWith('webrtc:baby:')) {
                  socket.leave(room);
                }
              }
              socket.disconnect(true);
            }
          }
        }
      } catch (err) {
        console.error('[Socket.IO] Permission expiration worker check error:', err);
      }
    }, 20000); // Check every 20 seconds
  }
}
