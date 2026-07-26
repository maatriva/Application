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
        origin: '*',
        methods: ['GET', 'POST'],
      },
    });

    // 1. Authenticate all socket connections using JWT middleware
    this.io.use(async (socket, next) => {
      try {
        const token = (socket.handshake.auth?.token || socket.handshake.query?.token) as string;

        if (!token) {
          console.warn('[Socket.IO] Connection rejected: Missing token.');
          return next(new Error('Unauthorized: Missing JWT token parameter.'));
        }

        const decoded = jwt.verify(token, env.JWT_SECRET) as any;
        const userId = decoded.userId;
        const role = decoded.role;

        // Fetch authorized babies list for this user
        const babyIds = await this.fetchAuthorizedBabies(userId, role);

        // Store user metadata on the socket object
        socket.data = {
          userId,
          role,
          babyIds,
        };

        next();
      } catch (err) {
        console.warn('[Socket.IO] Connection rejected: Invalid token.');
        next(new Error('Unauthorized: Invalid token.'));
      }
    });

    // 2. Handle connection and room event subscriptions
    this.io.on('connection', (socket: Socket) => {
      const { userId, role, babyIds } = socket.data;
      console.log(`[Socket.IO] New connection: Socket ID ${socket.id}, User ID ${userId} (Role: ${role})`);

      // socket.on('join:baby', (babyId: string) => {
      //   if (babyIds.includes(babyId)) {
      //     const roomName = `baby:${babyId}`;
      //     socket.join(roomName);
      //     console.log(`[Socket.IO] Socket ${socket.id} (User ${userId}) joined room ${roomName}`);
      //     socket.emit('joined:baby', { babyId, status: 'success' });
      //   } else {
      //     console.warn(`[Socket.IO] Socket ${socket.id} (User ${userId}) unauthorized join attempt for baby ${babyId}`);
      //     socket.emit('join:error', { babyId, message: 'Unauthorized access to this baby feed.' });
      //   }
      // });



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
        this.io?.to(targetSocketId).emit('offer', {
          babyId,
          sdp,
          senderSocketId: socket.id,
        });
      });

      socket.on('answer', (data: { babyId: string; sdp: any; targetSocketId: string }) => {
        const { babyId, sdp, targetSocketId } = data;
        this.io?.to(targetSocketId).emit('answer', {
          babyId,
          sdp,
          senderSocketId: socket.id,
        });
      });

      socket.on('ice-candidate', (data: { babyId: string; candidate: any; targetSocketId: string }) => {
        const { babyId, candidate, targetSocketId } = data;
        this.io?.to(targetSocketId).emit('ice-candidate', {
          babyId,
          candidate,
          senderSocketId: socket.id,
        });
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

      socket.on('disconnect', (reason) => {
        console.log(`[Socket.IO] Socket ${socket.id} disconnected. Reason: ${reason}`);
      });
    });
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
  private async fetchAuthorizedBabies(userId: string, role: string): Promise<string[]> {
    try {
      if (role.toLowerCase() === 'admin') {
        const babies = await prisma.baby.findMany({ select: { id: true } });
        return babies.map((b) => b.id.toString());
      }

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

      return babies.map((b) => b.id.toString());
    } catch (e) {
      console.error('[Socket.IO] Error fetching authorized babies for user:', e);
      return [];
    }
  }

  public getConnectedClientsCount(): number {
    return this.io ? this.io.sockets.sockets.size : 0;
  }

  public async isUserAuthorized(userId: string, babyId: string): Promise<boolean> {
    try {
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
                  status: 'accepted',
                },
              },
            },
          ],
        },
      });
      return count > 0;
    } catch (_) {
      return false;
    }
  }
}
