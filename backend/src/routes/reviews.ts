import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { AuthedRequest, optionalAuth, requireAuth } from '../middleware/auth';

export const reviewsRouter = Router();

const listSchema = z.object({
  page: z.coerce.number().int().min(1).max(10000).default(1),
}).partial();

/**
 * Public product reviews with a verified-purchase summary. Authenticated
 * callers also learn which of their delivered order lines are reviewable.
 */
reviewsRouter.get('/product/:productId', optionalAuth, async (req: AuthedRequest, res, next) => {
  try {
    const page = listSchema.parse(req.query).page ?? 1;
    const productId = String(req.params.productId);
    const where = { productId, isHidden: false };
    const [count, rows, agg] = await Promise.all([
      prisma.review.count({ where }),
      prisma.review.findMany({
        where, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 20, skip: (page - 1) * 20,
        include: { user: { select: { name: true } } },
      }),
      prisma.review.aggregate({ where, _avg: { rating: true }, _count: { rating: true } }),
    ]);
    let canReview: string[] = [];
    if (req.user?.sub) {
      const delivered = await prisma.orderItem.findMany({
        where: {
          productId, review: null,
          order: { customerId: req.user.sub, status: 'DELIVERED' },
        },
        select: { id: true },
      });
      canReview = delivered.map(d => d.id);
    }
    res.json({
      reviews: rows.map(r => ({
        id: r.id, rating: r.rating, title: r.title, body: r.body,
        userName: r.user.name, createdAt: r.createdAt.toISOString(),
      })),
      summary: {
        average: agg._avg.rating ?? 0,
        count: agg._count.rating,
        page, hasMore: rows.length === 20,
      },
      canReview,
    });
  } catch (e) { next(e); }
});

const createSchema = z.object({
  orderItemId: z.string().min(1).max(100),
  rating: z.number().int().min(1).max(5),
  title: z.string().max(100).optional(),
  body: z.string().min(1).max(2000),
});

/** Only the buyer of a delivered line can review it, once. */
reviewsRouter.post('/product/:productId', requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const input = createSchema.parse(req.body);
    const productId = String(req.params.productId);
    const userId = req.user!.sub;
    const created = await prisma.$transaction(async tx => {
      const line = await tx.orderItem.findFirst({
        where: {
          id: input.orderItemId, productId,
          order: { customerId: userId, status: 'DELIVERED' },
        },
        include: { order: { select: { vendorId: true } }, review: true },
      });
      if (!line) throw Object.assign(new Error('Only delivered items you ordered can be reviewed'), { status: 403 });
      if (line.review) throw Object.assign(new Error('You already reviewed this item'), { status: 409 });
      const review = await tx.review.create({
        data: {
          productId, vendorId: line.order.vendorId, userId, orderItemId: line.id,
          rating: input.rating, title: input.title ?? null, body: input.body,
        },
      });
      const agg = await tx.review.aggregate({
        where: { productId, isHidden: false },
        _avg: { rating: true }, _count: { rating: true },
      });
      await tx.product.update({
        where: { id: productId },
        data: {
          rating: Math.round((agg._avg.rating ?? 0) * 10) / 10,
          reviewCount: agg._count.rating,
        },
      });
      return review;
    });
    res.status(201).json({ review: { id: created.id, rating: created.rating, createdAt: created.createdAt.toISOString() } });
  } catch (e) { next(e); }
});

/** Admin moderation: hide or restore. Product aggregates follow. */
reviewsRouter.patch('/:id', requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    if (req.user!.role !== 'ADMIN') throw Object.assign(new Error('Administrator access required'), { status: 403 });
    const input = z.object({
      isHidden: z.boolean(), moderationNote: z.string().max(500).optional(),
    }).parse(req.body);
    const review = await prisma.$transaction(async tx => {
      const existing = await tx.review.findUnique({ where: { id: String(req.params.id) } });
      if (!existing) throw Object.assign(new Error('Review not found'), { status: 404 });
      const updated = await tx.review.update({
        where: { id: existing.id },
        data: {
          isHidden: input.isHidden,
          moderatedBy: req.user!.sub,
          moderationNote: input.moderationNote ?? existing.moderationNote,
        },
      });
      const agg = await tx.review.aggregate({
        where: { productId: existing.productId, isHidden: false },
        _avg: { rating: true }, _count: { rating: true },
      });
      await tx.product.update({
        where: { id: existing.productId },
        data: {
          rating: Math.round((agg._avg.rating ?? 0) * 10) / 10,
          reviewCount: agg._count.rating,
        },
      });
      return updated;
    });
    res.json({ review: { id: review.id, isHidden: review.isHidden } });
  } catch (e) { next(e); }
});
