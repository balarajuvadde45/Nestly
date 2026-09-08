import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { AuthedRequest, requireAuth } from '../middleware/auth';

export const favoritesRouter = Router();
favoritesRouter.use(requireAuth);
favoritesRouter.post('/', async (req: AuthedRequest, res, next) => {
  try {
    const body = z.object({
      kind: z.enum(['vendor', 'product']), id: z.string().min(1).max(100), saved: z.boolean(),
    }).parse(req.body);
    const userId = req.user!.sub;
    const field = body.kind === 'vendor' ? { vendorId: body.id } : { productId: body.id };
    if (body.saved) {
      const exists = body.kind === 'vendor'
        ? await prisma.vendor.findFirst({ where: { id: body.id, isApproved: true } })
        : await prisma.product.findFirst({ where: { id: body.id, isAvailable: true, vendor: { isApproved: true } } });
      if (!exists) { res.status(404).json({ error: 'Item unavailable' }); return; }
      await prisma.favorite.upsert({
        where: body.kind === 'vendor'
          ? { userId_vendorId: { userId, vendorId: body.id } }
          : { userId_productId: { userId, productId: body.id } },
        create: { userId, ...field }, update: {},
      });
    } else {
      await prisma.favorite.deleteMany({ where: { userId, ...field } });
    }
    res.json({ ok: true });
  } catch (e) { next(e); }
});
