import http from 'http';
import { env, dbPublicInfo } from './lib/env';
import { prisma } from './lib/prisma';
import { logger } from './lib/logger';
import { createApp } from './app';
import { redis } from './lib/redis';
import { initSocket, closeSocket } from './socket';

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

  server.listen(env.port, () => {
    logger.info({ port: env.port }, 'Nestly API ready');
  });

  // Graceful shutdown: stop accepting connections, drain, disconnect DB.
  const shutdown = (signal: string): void => {
    logger.info(`${signal} received — shutting down gracefully`);
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
