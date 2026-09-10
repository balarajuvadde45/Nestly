import { Router } from 'express';
import { prisma } from '../lib/prisma';
import {
  serializeBanner,
  serializeCategory,
  serializeProduct,
  serializeVendor,
} from '../lib/serializers';

export const catalogRouter = Router();

/**
 * Unified search — products + vendors in one round-trip.
 * Target: < 1s with indexes + limited take.
 */
catalogRouter.get('/search', async (req, res, next) => {
  const started = Date.now();
  try {
    const q = String(req.query.q || '').trim();
    const limit = Math.max(1, Math.min(Math.floor(Number(req.query.limit)) || 24, 48));
    const vegOnly = req.query.vegOnly === 'true';

    if (!q || q.length < 1) {
      res.json({
        query: q,
        products: [],
        vendors: [],
        tookMs: Date.now() - started,
      });
      return;
    }

    const [products, vendors] = await Promise.all([
      prisma.product.findMany({
        where: {
          isAvailable: true,
          vendor: { isApproved: true },
          ...(vegOnly ? { isVeg: true } : {}),
          OR: [
            { name: { contains: q, mode: 'insensitive' } },
            { description: { contains: q, mode: 'insensitive' } },
            { tagsJson: { contains: q, mode: 'insensitive' } },
            { brandName: { contains: q, mode: 'insensitive' } },
            { sku: { contains: q, mode: 'insensitive' } },
            { hsnCode: { contains: q, mode: 'insensitive' } },
            { unitLabel: { contains: q, mode: 'insensitive' } },
          ],
        },
        orderBy: [{ reviewCount: 'desc' }, { rating: 'desc' }],
        take: limit,
      }),
      prisma.vendor.findMany({
        where: {
          isApproved: true,
          ...(vegOnly ? { isPureVeg: true } : {}),
          OR: [
            { name: { contains: q, mode: 'insensitive' } },
            { tagline: { contains: q, mode: 'insensitive' } },
            { area: { contains: q, mode: 'insensitive' } },
            { tagsJson: { contains: q, mode: 'insensitive' } },
            { gstin: { contains: q, mode: 'insensitive' } },
            { description: { contains: q, mode: 'insensitive' } },
          ],
        },
        orderBy: [{ orderCount: 'desc' }, { rating: 'desc' }],
        take: limit,
      }),
    ]);

    res.json({
      query: q,
      products: products.map(serializeProduct),
      vendors: vendors.map(v => serializeVendor(v)),
      tookMs: Date.now() - started,
    });
  } catch (e) {
    next(e);
  }
});

catalogRouter.get('/categories', async (_req, res, next) => {
  try {
    const categories = await prisma.shopCategory.findMany({
      orderBy: { sortOrder: 'asc' },
    });
    res.json({ categories: categories.map(serializeCategory) });
  } catch (e) {
    next(e);
  }
});

catalogRouter.get('/banners', async (_req, res, next) => {
  try {
    const banners = await prisma.banner.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
    });
    res.json({ banners: banners.map(serializeBanner) });
  } catch (e) {
    next(e);
  }
});

catalogRouter.get('/vendors', async (req, res, next) => {
  try {
    const {
      categoryId,
      q,
      vegOnly,
      sortBy = 'popular',
      city,
    } = req.query as Record<string, string | undefined>;

    const orderBy =
      sortBy === 'rating'
        ? { rating: 'desc' as const }
        : sortBy === 'delivery'
          ? { deliveryTimeMins: 'asc' as const }
          : sortBy === 'distance'
            ? { distanceKm: 'asc' as const }
            : { orderCount: 'desc' as const };

    const vendors = await prisma.vendor.findMany({
      where: {
        isApproved: true,
        ...(city ? { city } : {}),
        ...(vegOnly === 'true' ? { isPureVeg: true } : {}),
        ...(q
          ? {
              OR: [
                { name: { contains: q, mode: 'insensitive' } },
                { tagline: { contains: q, mode: 'insensitive' } },
                { area: { contains: q, mode: 'insensitive' } },
                { tagsJson: { contains: q, mode: 'insensitive' } },
                { businessAddress: { contains: q, mode: 'insensitive' } },
              ],
            }
          : {}),
        ...(categoryId
          ? { AND: [{ OR: [{ categoriesJson: { contains: categoryId } }, { products: { some: { categoryId, isAvailable: true } } }] }] }
          : {}),
      },
      orderBy,
      take: 60,
    });

    res.json({ vendors: vendors.map(v => serializeVendor(v)) });
  } catch (e) {
    next(e);
  }
});

catalogRouter.get('/vendors/:id', async (req, res, next) => {
  try {
    const vendor = await prisma.vendor.findUnique({
      where: { id: req.params.id },
    });
    if (!vendor || !vendor.isApproved) {
      res.status(404).json({ error: 'Vendor not found' });
      return;
    }
    res.json({ vendor: serializeVendor(vendor) });
  } catch (e) {
    next(e);
  }
});

catalogRouter.get('/vendors/:id/products', async (req, res, next) => {
  try {
    const products = await prisma.product.findMany({
      where: { vendorId: req.params.id, isAvailable: true, vendor: { isApproved: true } },
      take: 120,
      orderBy: { name: 'asc' },
    });
    res.json({ products: products.map(serializeProduct) });
  } catch (e) {
    next(e);
  }
});

catalogRouter.get('/products', async (req, res, next) => {
  try {
    const { categoryId, q, vegOnly, vendorId } = req.query as Record<
      string,
      string | undefined
    >;
    const products = await prisma.product.findMany({
      where: {
        isAvailable: true,
          vendor: { isApproved: true },
        ...(categoryId ? { categoryId } : {}),
        ...(vendorId ? { vendorId } : {}),
        ...(vegOnly === 'true' ? { isVeg: true } : {}),
        ...(q
          ? {
              OR: [
                { name: { contains: q, mode: 'insensitive' } },
                { description: { contains: q, mode: 'insensitive' } },
                { tagsJson: { contains: q, mode: 'insensitive' } },
                { brandName: { contains: q, mode: 'insensitive' } },
                { sku: { contains: q, mode: 'insensitive' } },
                { hsnCode: { contains: q, mode: 'insensitive' } },
                { unitLabel: { contains: q, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      orderBy: { reviewCount: 'desc' },
      take: q ? 48 : 120,
    });
    res.json({ products: products.map(serializeProduct) });
  } catch (e) {
    next(e);
  }
});

catalogRouter.get('/products/:id', async (req, res, next) => {
  try {
    const product = await prisma.product.findFirst({
      where: { id: req.params.id, isAvailable: true, vendor: { isApproved: true } },
    });
    if (!product) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }
    res.json({ product: serializeProduct(product) });
  } catch (e) {
    next(e);
  }
});

catalogRouter.get('/home', async (_req, res, next) => {
  try {
    const [categories, banners, vendors, products] = await Promise.all([
      prisma.shopCategory.findMany({ orderBy: { sortOrder: 'asc' } }),
      prisma.banner.findMany({
        where: { isActive: true },
        orderBy: { sortOrder: 'asc' },
      }),
      prisma.vendor.findMany({ where: { isApproved: true }, orderBy: { orderCount: 'desc' }, take: 60 }),
      prisma.product.findMany({
        where: { isAvailable: true, vendor: { isApproved: true } },
        orderBy: { reviewCount: 'desc' },
        take: 12,
      }),
    ]);

    const serializedVendors = vendors.map(v => serializeVendor(v));
    const popular = [...serializedVendors]
      .sort((a, b) => b.orderCount - a.orderCount)
      .slice(0, 6);
    const topRated = [...serializedVendors]
      .sort((a, b) => b.rating - a.rating)
      .slice(0, 6);

    res.json({
      categories: categories.map(serializeCategory),
      banners: banners.map(serializeBanner),
      popularVendors: popular,
      topRated,
      bestsellers: products.map(serializeProduct),
      vendors: serializedVendors,
    });
  } catch (e) {
    next(e);
  }
});
