import http from 'http';
import express from 'express';
import cors from 'cors';
import { env, dbPublicInfo } from './lib/env';
import { prisma } from './lib/prisma';
import { errorHandler, notFound } from './middleware/error';
import { authRouter } from './routes/auth';
import { catalogRouter } from './routes/catalog';
import { ordersRouter } from './routes/orders';
import { sellerRouter } from './routes/seller';
import { addressesRouter } from './routes/addresses';
import { wisdomRouter } from './routes/wisdom';
import { applicationsRouter } from './routes/applications';
import { initSocket } from './socket';

async function main() {
  // Fail fast if DB is unreachable
  try {
    await prisma.$connect();
    console.log(`PostgreSQL connected: ${dbPublicInfo()}`);
  } catch (err) {
    console.error(
      'Failed to connect to PostgreSQL. Check DATABASE_URL / DB_* in backend/.env',
    );
    console.error(err);
    process.exit(1);
  }

  const app = express();
  app.use(
    cors({
      origin: env.corsOrigin === '*' ? true : env.corsOrigin.split(','),
    }),
  );
  app.use(express.json({ limit: '2mb' }));

  app.get('/health', async (_req, res) => {
    let db = 'unknown';
    try {
      await prisma.$queryRaw`SELECT 1`;
      db = 'up';
    } catch {
      db = 'down';
    }
    res.json({
      ok: db === 'up',
      service: 'nestly-api',
      database: db,
      time: new Date().toISOString(),
    });
  });

  app.use('/api/auth', authRouter);
  app.use('/api/catalog', catalogRouter);
  app.use('/api/orders', ordersRouter);
  app.use('/api/seller', sellerRouter);
  app.use('/api/addresses', addressesRouter);
  app.use('/api/wisdom', wisdomRouter);
  app.use('/api/seller-applications', applicationsRouter);

  app.use(notFound);
  app.use(errorHandler);

  const server = http.createServer(app);
  initSocket(server);

  server.listen(env.port, () => {
    console.log(`Nestly API listening on http://localhost:${env.port}`);
    console.log(`Health: http://localhost:${env.port}/health`);
    console.log(`Socket.IO ready for live tracking`);
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
