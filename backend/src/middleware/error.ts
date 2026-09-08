import { Request, Response, NextFunction } from 'express';
import { Prisma } from '@prisma/client';
import { ZodError } from 'zod';
import { logger } from '../lib/logger';

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    const status = ['P2002', 'P2003', 'P2034'].includes(err.code) ? 409 : err.code === 'P2025' ? 404 : 500;
    res.status(status).json({ error: status === 409 ? 'Record conflict. Refresh and try again.' : status === 404 ? 'Record not found' : 'Internal server error' });
    if (status === 500) logger.error({ code: err.code }, 'Database operation failed');
    return;
  }
  if (err instanceof ZodError) {
    res.status(400).json({
      error: 'Validation failed',
      details: err.flatten(),
    });
    return;
  }
  if (err instanceof Error) {
    const status = (err as Error & { status?: number }).status ?? 500;
    // 5xx are real faults (log full stack); 4xx are client errors (log lightly).
    if (status >= 500) {
      logger.error({ err }, err.message);
    } else {
      logger.warn({ msg: err.message }, 'client error');
    }
    res.status(status).json({ error: status >= 500 ? 'Service temporarily unavailable' : err.message });
    return;
  }
  logger.error({ err }, 'Unknown non-Error thrown');
  res.status(500).json({ error: 'Internal server error' });
}

export function notFound(_req: Request, res: Response): void {
  res.status(404).json({ error: 'Not found' });
}
