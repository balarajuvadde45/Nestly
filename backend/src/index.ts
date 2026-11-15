import http from 'http';
import { env, dbPublicInfo } from './lib/env';
import { prisma } from './lib/prisma';
import { logger } from './lib/logger';
import { createApp } from './app';
import { redis } from './lib/redis';
import { initSocket, closeSocket } from './socket';
import { NotificationWorker } from './lib/notification-worker';
import { expireStaleOnlineOrders, processRefundDueOrders } from './lib/order-lifecycle';

async function main(): Promise<void> {
  // Fail fast if the DB is unreachable.
  try {
    await prisma.$connect();
    if (redis) await redis.connect();
    logger.info(`PostgreSQL connected: ${dbPublicInfo()}`);
  } catch (err) {
    logger.error(
      { err },
      'Failed to connect to PostgreSQL. Check DATABASE_URL / DB_* in backend/.env',
    );
    process.exit(1);
  }

  const app = createApp();
  const server = http.createServer(app);
  await initSocket(server);

  // Drain the durable notification queue in-process.
  const notifications = new NotificationWorker();
  notifications.start();

  // Money-critical sweeps: reconcile stale online orders (they must never be
  // cancelled while the provider actually captured money) and execute pending
  // refunds. Both are idempotent and safe to run on every instance.
  const sweeps = setInterval(() => {
    void expireStaleOnlineOrders().catch((err) => logger.error({ err }, 'Stale-order sweep failed'));
    void processRefundDueOrders().catch((err) => logger.error({ err }, 'Refund sweep failed'));
  }, 60_000);
  sweeps.unref();

  server.listen(env.port, () => {
    logger.info({ port: env.port }, 'Tamarin API ready');
  });

  // Graceful shutdown: stop accepting connections, drain, disconnect DB.
  const shutdown = (signal: string): void => {
    logger.info(`${signal} received — shutting down gracefully`);
    notifications.stop();
    clearInterval(sweeps);
    void closeSocket();
    server.close(() => {
      void Promise.all([prisma.$disconnect(), redis?.isOpen ? redis.quit() : Promise.resolve()]).finally(() => {
        logger.info('HTTP server closed and DB disconnected');
        process.exit(0);
      });
    });
    // Force-exit if a connection refuses to drain.
    setTimeout(() => {
      logger.error('Forced shutdown after 10s timeout');
      process.exit(1);
    }, 10_000).unref();
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch((e) => {
  logger.error({ err: e }, 'Fatal startup error');
  process.exit(1);
});
