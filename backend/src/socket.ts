import { Server as HttpServer } from 'http';
import { Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { verifyToken } from './lib/auth';
import { env } from './lib/env';
import { prisma } from './lib/prisma';
import { redis } from './lib/redis';

let io: Server | null = null;
let subscriber: ReturnType<NonNullable<typeof redis>['duplicate']> | null = null;
export function getIo(): Server | null { return io; }

export async function initSocket(httpServer: HttpServer): Promise<Server> {
  io = new Server(httpServer, {
    transports: ['websocket'],
    cors: { origin: env.corsOrigin === '*' ? true : env.corsOrigin.split(',').map(v => v.trim()) },
  });
  if (redis) {
    subscriber = redis.duplicate();
    subscriber.on('error', () => {});
    await subscriber.connect();
    io.adapter(createAdapter(redis, subscriber));
  }
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (typeof token !== 'string') return next(new Error('Unauthorized'));
      const payload = verifyToken(token);
      const user = await prisma.user.findUnique({ where: { id: payload.sub } });
      if (!user || user.deletedAt) return next(new Error('Unauthorized'));
      socket.data.userId = user.id;
      socket.data.token = token;
      next();
    } catch { next(new Error('Unauthorized')); }
  });
  io.on('connection', socket => {
    void socket.join('user:' + socket.data.userId);
    const checkSession = setInterval(async () => {
      try {
        verifyToken(socket.data.token);
        const user = await prisma.user.findUnique({ where: { id: socket.data.userId } });
        if (!user || user.deletedAt) socket.disconnect(true);
      } catch { socket.disconnect(true); }
    }, 60_000);
    checkSession.unref();
    let lastSubscribe = 0;
    socket.on('tracking:subscribe', async (orderId: unknown) => {
      if (typeof orderId !== 'string' || orderId.length > 100 ||
          Date.now() - lastSubscribe < 250 || socket.rooms.size >= 30) return;
      lastSubscribe = Date.now();
      try {
        verifyToken(socket.data.token);
        const user = await prisma.user.findUnique({ where: { id: socket.data.userId } });
        if (!user || user.deletedAt) { socket.disconnect(true); return; }
        const order = await prisma.order.findFirst({ where: {
          id: orderId,
          ...(user.role === 'ADMIN' ? {} : { OR: [
            { customerId: user.id }, { vendor: { ownerId: user.id } },
          ] }),
        } });
        if (order) await socket.join('order:' + orderId);
      } catch { socket.emit('tracking:error', { error: 'Unable to subscribe' }); }
    });
    socket.on('tracking:unsubscribe', (id: unknown) => {
      if (typeof id === 'string') void socket.leave('order:' + id);
    });
    socket.on('disconnect', () => clearInterval(checkSession));
  });
  return io;
}
export async function closeSocket(): Promise<void> {
  await new Promise<void>(resolve => { if (io) io.close(() => resolve()); else resolve(); });
  if (subscriber?.isOpen) await subscriber.quit();
}
