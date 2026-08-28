import http from 'http';
import { env, dbPublicInfo } from './lib/env';
import { prisma } from './lib/prisma';
import { logger } from './lib/logger';
import { createApp } from './app';
import { initSocket } from './socket';

async function main(): Promise<void> {
  // Fail fast if the DB is unreachable.
  try {
    await prisma.$connect();
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
  initSocket(server);

  server.listen(env.port, () => {
    logger.info(`Nestly API listening on http://localhost:${env.port}`);
    logger.info(`Health: http://localhost:${env.port}/health`);
    logger.info('Socket.IO ready for live tracking');
  });

  // Graceful shutdown: stop accepting connections, drain, disconnect DB.
  const shutdown = (signal: string): void => {
    logger.info(`${signal} received — shutting down gracefully`);
    server.close(() => {
      void prisma.$disconnect().finally(() => {
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
