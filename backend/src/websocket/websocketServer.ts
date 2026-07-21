import { Server, WebSocket } from 'ws';
import http from 'http';
import url from 'url';
import jwt from 'jsonwebtoken';
import { Pool } from 'pg';
import { config } from '../config/config';

interface ClientSession {
  ws: WebSocket;
  userId: string;
  role: string;
  babyIds: string[]; // List of babyIds this user is authorized to monitor
}

export class WebsocketServerManager {
  private wss?: Server;
  private dbPool: Pool;
  private sessions: Map<WebSocket, ClientSession> = new Map();

  constructor(dbPool: Pool) {
    this.dbPool = dbPool;
  }

  /**
   * Initializes the WebSocket server attached to the HTTP server.
   */
  public initialize(server: http.Server): void {
    this.wss = new Server({ noServer: true });

    server.on('upgrade', (request, socket, head) => {
      const pathname = url.parse(request.url || '').pathname;

      if (pathname === '/ws') {
        this.wss?.handleUpgrade(request, socket, head, (ws) => {
          this.wss?.emit('connection', ws, request);
        });
      } else {
        socket.destroy();
      }
    });

    this.wss.on('connection', async (ws: WebSocket, req: http.IncomingMessage) => {
      console.log('New incoming WebSocket connection handshake...');
      
      const parsedUrl = url.parse(req.url || '', true);
      const token = parsedUrl.query.token as string;

      if (!token) {
        ws.close(4001, 'Unauthorized: Missing JWT token parameter.');
        return;
      }

      try {
        // 1. Authenticate token
        const decoded = jwt.verify(token, config.jwtSecret) as any;
        const userId = decoded.userId;
        const role = decoded.role;

        // 2. Fetch authorized babies list for this user
        const babyIds = await this.fetchAuthorizedBabies(userId, role);

        const session: ClientSession = {
          ws,
          userId,
          role,
          babyIds,
        };

        this.sessions.set(ws, session);
        console.log(`WebSocket user authenticated: User ID ${userId} (Role: ${role}) subscribed to ${babyIds.length} baby feeds.`);

        // Setup ping-pong to detect dead connections
        ws.on('pong', () => {
          // Socket is alive
        });

        ws.on('close', () => {
          this.sessions.delete(ws);
          console.log(`WebSocket session closed for User ${userId}`);
        });

        // Send initialization success
        ws.send(JSON.stringify({ event: 'connected', message: 'Authorized real-time telemetry stream active.' }));

      } catch (err) {
        ws.close(4003, 'Unauthorized: Invalid token.');
      }
    });

    // Start connection keep-alive heartbeat interval (every 30s)
    setInterval(() => {
      this.sessions.forEach((session, ws) => {
        if (ws.readyState === WebSocket.CLOSED) {
          this.sessions.delete(ws);
          return;
        }
        ws.ping();
      });
    }, 30000);
  }

  /**
   * Streams a telemetry packet in real-time to all authenticated sockets monitoring the baby.
   */
  public broadcastTelemetry(babyId: string, telemetry: any): void {
    this.sessions.forEach((session) => {
      if (session.babyIds.includes(babyId) && session.ws.readyState === WebSocket.OPEN) {
        session.ws.send(JSON.stringify({
          event: 'telemetry',
          babyId,
          data: telemetry,
        }));
      }
    });
  }

  /**
   * Streams alert pings immediately to all parent/caregiver app clients monitoring the baby.
   */
  public broadcastAlert(babyId: string, alert: any): void {
    this.sessions.forEach((session) => {
      if (session.babyIds.includes(babyId) && session.ws.readyState === WebSocket.OPEN) {
        session.ws.send(JSON.stringify({
          event: 'alert',
          babyId,
          data: alert,
        }));
      }
    });
  }

  /**
   * Helper: Resolves relational permissions for babies connected to a parent or caregiver.
   */
  private async fetchAuthorizedBabies(userId: string, role: string): Promise<string[]> {
    try {
      if (role === 'admin') {
        const res = await this.dbPool.query('SELECT id FROM babies');
        return res.rows.map((row) => row.id.toString());
      }

      // Parents see their babies directly + caregivers see accepted invitation assignments
      const res = await this.dbPool.query(
        `SELECT id FROM babies WHERE parent_id = $1
         UNION
         SELECT baby_id FROM caregivers WHERE user_id = $1 AND status = 'accepted'`,
        [userId]
      );

      return res.rows.map((row) => row.id.toString());
    } catch (e) {
      console.error('Error fetching authorized babies for user:', e);
      return [];
    }
  }
}
