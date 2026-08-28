import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { logger } from '../lib/logger';

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
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
    res.status(status).json({ error: err.message || 'Internal server error' });
    return;
  }
  logger.error({ err }, 'Unknown non-Error thrown');
  res.status(500).json({ error: 'Internal server error' });
}

export function notFound(_req: Request, res: Response): void {
  res.status(404).json({ error: 'Not found' });
}
