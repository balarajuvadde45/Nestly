import { Request, Response, NextFunction } from 'express';
import { Role } from '@prisma/client';
import { verifyToken, JwtPayload } from '../lib/auth';
import { prisma } from '../lib/prisma';

export type AuthedRequest = Request & {
  user?: JwtPayload;
};

export function requireAuth(
  req: AuthedRequest,
  res: Response,
  next: NextFunction,
): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  try {
    req.user = verifyToken(header.slice(7));
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

export function optionalAuth(
  req: AuthedRequest,
  _res: Response,
  next: NextFunction,
): void {
  const header = req.headers.authorization;
  if (header?.startsWith('Bearer ')) {
    try {
      req.user = verifyToken(header.slice(7));
    } catch {
      // ignore
    }
  }
  next();
}

export function requireRole(...roles: Role[]) {
  return (req: AuthedRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    if (!roles.includes(req.user.role)) {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }
    next();
  };
}

/**
 * Seller routes: trust JWT SELLER/ADMIN, or refresh from DB if user
 * owns a business (fixes stale JWT after open-business).
 */
export function requireSellerAccess() {
  return async (
    req: AuthedRequest,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized — login required' });
      return;
    }
    if (
      req.user.role === Role.SELLER ||
      req.user.role === Role.ADMIN
    ) {
      next();
      return;
    }

    try {
      const user = await prisma.user.findUnique({
        where: { id: req.user.sub },
        include: { vendor: true },
      });
      if (!user) {
        res.status(401).json({ error: 'User not found' });
        return;
      }
      if (user.role === Role.SELLER || user.role === Role.ADMIN || user.vendor) {
        // Elevate JWT payload for this request so handlers see SELLER
        req.user = {
          ...req.user,
          role:
            user.role === Role.ADMIN
              ? Role.ADMIN
              : Role.SELLER,
        };
        next();
        return;
      }
      res.status(403).json({
        error:
          'Forbidden — open a business account from your buyer login first (Sell → Create business).',
      });
    } catch (e) {
      next(e);
    }
  };
}
