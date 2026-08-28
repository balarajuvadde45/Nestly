import express, { type Express, type Request, type Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import { pinoHttp } from 'pino-http';

import { env } from './lib/env';
import { logger } from './lib/logger';
import { prisma } from './lib/prisma';
import { errorHandler, notFound } from './middleware/error';

import { authRouter } from './routes/auth';
import { catalogRouter } from './routes/catalog';
import { ordersRouter } from './routes/orders';
import { sellerRouter } from './routes/seller';
import { addressesRouter } from './routes/addresses';
import { wisdomRouter } from './routes/wisdom';
import { applicationsRouter } from './routes/applications';
import { buyerRouter } from './routes/buyer';

const isTest = process.env.NODE_ENV === 'test';

/**
 * Build the Express app. Deliberately does NOT connect to the DB or start
 * listening — that is the job of index.ts. Keeping this pure lets tests import
 * the app directly (see src/__tests__).
 */
export function createApp(): Express {
  const app = express();

  // We sit behind Cloudflare / a load balancer in production, so trust the
  // first proxy hop for correct client IPs (rate limiting, logging).
  app.set('trust proxy', 1);

  app.use(
    helmet({
      // Public API consumed cross-origin by the web client.
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );
  app.use(
    cors({
      origin: env.corsOrigin === '*' ? true : env.corsOrigin.split(','),
    }),
  );
  app.use(compression());
  app.use(express.json({ limit: '2mb' }));
  app.use(pinoHttp({ logger }));

  // ---- Health probes ----
  // Liveness: the process is up (no external dependencies checked).
  app.get('/healthz', (_req: Request, res: Response) => {
    res.json({ ok: true, service: 'nestly-api', time: new Date().toISOString() });
  });
  // Readiness: dependencies reachable — used by a load balancer before routing.
  app.get('/readyz', async (_req: Request, res: Response) => {
    try {
      await prisma.$queryRaw`SELECT 1`;
      res.json({ ok: true, database: 'up', time: new Date().toISOString() });
    } catch {
      res
        .status(503)
        .json({ ok: false, database: 'down', time: new Date().toISOString() });
    }
  });
  // Backward-compatible health endpoint (the Flutter app probes /health).
  app.get('/health', async (_req: Request, res: Response) => {
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

  // ---- Rate limiting ----
  // NOTE: in-memory store — resets per instance and is NOT shared across
  // instances. Phase 1 swaps this for a Redis-backed store so limits hold
  // across the whole fleet.
  const skip = (): boolean => isTest;
  const apiLimiter = rateLimit({
    windowMs: 60_000,
    max: 300,
    standardHeaders: true,
    legacyHeaders: false,
    skip,
  });
  const authLimiter = rateLimit({
    windowMs: 15 * 60_000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
    skip,
  });

  app.use('/api', apiLimiter);

  // Buyer shop API
  app.use('/api/auth', authLimiter, authRouter);
  app.use('/api/catalog', catalogRouter);
  app.use('/api/orders', ordersRouter);
  app.use('/api/buyer', buyerRouter);
  app.use('/api/addresses', addressesRouter);
  app.use('/api/wisdom', wisdomRouter);

  // Seller dashboard API (separate surface)
  app.use('/api/seller', sellerRouter);

  // Admin
  app.use('/api/seller-applications', applicationsRouter);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}
