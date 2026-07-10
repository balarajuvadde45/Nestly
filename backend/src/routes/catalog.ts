import { Router } from 'express';
import { prisma } from '../lib/prisma';
import {
  serializeBanner,
  serializeCategory,
  serializeProduct,
  serializeVendor,
} from '../lib/serializers';

export const catalogRouter = Router();

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

    const vendors = await prisma.vendor.findMany({
      where: {
        isApproved: true,
        ...(city ? { city } : {}),
        ...(vegOnly === 'true' ? { isPureVeg: true } : {}),
      },
    });

    let list = vendors.map(serializeVendor);

    if (categoryId) {
      list = list.filter((v) => v.categories.includes(categoryId));
    }
    if (q) {
      const query = q.toLowerCase();
      list = list.filter(
        (v) =>
          v.name.toLowerCase().includes(query) ||
          v.tagline.toLowerCase().includes(query) ||
          v.tags.some((t) => t.toLowerCase().includes(query)) ||
          v.area.toLowerCase().includes(query),
      );
    }

    switch (sortBy) {
      case 'rating':
        list.sort((a, b) => b.rating - a.rating);
        break;
      case 'delivery':
        list.sort((a, b) => a.deliveryTimeMins - b.deliveryTimeMins);
        break;
      case 'distance':
        list.sort((a, b) => a.distanceKm - b.distanceKm);
        break;
      default:
        list.sort((a, b) => b.orderCount - a.orderCount);
    }

    res.json({ vendors: list });
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
      where: { vendorId: req.params.id },
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
        ...(categoryId ? { categoryId } : {}),
        ...(vendorId ? { vendorId } : {}),
        ...(vegOnly === 'true' ? { isVeg: true } : {}),
        ...(q
          ? {
              OR: [
                { name: { contains: q } },
                { description: { contains: q } },
              ],
            }
          : {}),
      },
      orderBy: { reviewCount: 'desc' },
    });
    res.json({ products: products.map(serializeProduct) });
  } catch (e) {
    next(e);
  }
});

catalogRouter.get('/products/:id', async (req, res, next) => {
  try {
    const product = await prisma.product.findUnique({
      where: { id: req.params.id },
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
      prisma.vendor.findMany({ where: { isApproved: true } }),
      prisma.product.findMany({
        where: { isAvailable: true },
        orderBy: { reviewCount: 'desc' },
        take: 12,
      }),
    ]);

    const serializedVendors = vendors.map(serializeVendor);
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
