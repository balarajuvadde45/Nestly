import { Router } from 'express';
import { z } from 'zod';
import {
  OrderStatus,
  ProductType,
  Role,
  VendorType,
} from '@prisma/client';
import { prisma } from '../lib/prisma';
import {
  serializeOrder,
  serializeProduct,
  serializeVendor,
} from '../lib/serializers';
import {
  AuthedRequest,
  requireAuth,
  requireRole,
} from '../middleware/auth';
import { getIo } from '../socket';

export const sellerRouter = Router();

sellerRouter.use(requireAuth, requireRole(Role.SELLER, Role.ADMIN));

async function getOwnedVendor(userId: string, role: Role) {
  if (role === Role.ADMIN) {
    return prisma.vendor.findFirst({ orderBy: { createdAt: 'asc' } });
  }
  return prisma.vendor.findUnique({ where: { ownerId: userId } });
}

/** Register / claim a seller storefront for the logged-in seller */
sellerRouter.post('/onboard', async (req: AuthedRequest, res, next) => {
  try {
    const schema = z.object({
      name: z.string().min(2),
      tagline: z.string().min(2),
      description: z.string().min(10),
      type: z.enum([
        'HOME_COOK',
        'CLOUD_KITCHEN',
        'HOME_BUSINESS',
        'BOUTIQUE',
      ]),
      area: z.string().min(2),
      city: z.string().default('Hyderabad'),
      imageUrl: z.string().url().optional(),
      coverUrl: z.string().url().optional(),
      categories: z.array(z.string()).default([]),
      tags: z.array(z.string()).default([]),
      isPureVeg: z.boolean().optional(),
      freeDelivery: z.boolean().optional(),
      lat: z.number().optional(),
      lng: z.number().optional(),
    });
    const body = schema.parse(req.body);

    const existing = await prisma.vendor.findUnique({
      where: { ownerId: req.user!.sub },
    });
    if (existing) {
      res.status(409).json({ error: 'You already have a storefront', vendor: serializeVendor(existing) });
      return;
    }

    // Ensure user is SELLER
    await prisma.user.update({
      where: { id: req.user!.sub },
      data: { role: Role.SELLER },
    });

    const vendor = await prisma.vendor.create({
      data: {
        ownerId: req.user!.sub,
        name: body.name,
        tagline: body.tagline,
        description: body.description,
        type: body.type as VendorType,
        area: body.area,
        city: body.city,
        imageUrl:
          body.imageUrl ||
          'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400',
        coverUrl:
          body.coverUrl ||
          'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
        categoriesJson: JSON.stringify(body.categories),
        tagsJson: JSON.stringify(body.tags),
        isPureVeg: body.isPureVeg ?? false,
        freeDelivery: body.freeDelivery ?? false,
        lat: body.lat ?? 17.4486,
        lng: body.lng ?? 78.3908,
        isApproved: true,
      },
    });

    res.status(201).json({ vendor: serializeVendor(vendor) });
  } catch (e) {
    next(e);
  }
});

sellerRouter.get('/dashboard', async (req: AuthedRequest, res, next) => {
  try {
    const vendor = await getOwnedVendor(req.user!.sub, req.user!.role);
    if (!vendor) {
      res.status(404).json({ error: 'No storefront. Complete seller onboarding.' });
      return;
    }

    const [products, orders, activeCount, revenueAgg] = await Promise.all([
      prisma.product.count({ where: { vendorId: vendor.id } }),
      prisma.order.findMany({
        where: { vendorId: vendor.id },
        orderBy: { placedAt: 'desc' },
        take: 10,
        include: {
          items: true,
          events: true,
          vendor: true,
          address: true,
        },
      }),
      prisma.order.count({
        where: {
          vendorId: vendor.id,
          status: {
            in: [
              OrderStatus.PLACED,
              OrderStatus.CONFIRMED,
              OrderStatus.PREPARING,
              OrderStatus.OUT_FOR_DELIVERY,
            ],
          },
        },
      }),
      prisma.order.aggregate({
        where: {
          vendorId: vendor.id,
          status: { not: OrderStatus.CANCELLED },
        },
        _sum: { grandTotal: true },
        _count: true,
      }),
    ]);

    res.json({
      vendor: serializeVendor(vendor),
      stats: {
        productCount: products,
        totalOrders: revenueAgg._count,
        activeOrders: activeCount,
        revenue: revenueAgg._sum.grandTotal ?? 0,
        rating: vendor.rating,
      },
      recentOrders: orders.map(serializeOrder),
    });
  } catch (e) {
    next(e);
  }
});

sellerRouter.get('/products', async (req: AuthedRequest, res, next) => {
  try {
    const vendor = await getOwnedVendor(req.user!.sub, req.user!.role);
    if (!vendor) {
      res.status(404).json({ error: 'No storefront' });
      return;
    }
    const products = await prisma.product.findMany({
      where: { vendorId: vendor.id },
      orderBy: { updatedAt: 'desc' },
    });
    res.json({ products: products.map(serializeProduct) });
  } catch (e) {
    next(e);
  }
});

sellerRouter.post('/products', async (req: AuthedRequest, res, next) => {
  try {
    const vendor = await getOwnedVendor(req.user!.sub, req.user!.role);
    if (!vendor) {
      res.status(404).json({ error: 'No storefront' });
      return;
    }
    const schema = z.object({
      name: z.string().min(2),
      description: z.string().min(5),
      price: z.number().positive(),
      mrp: z.number().positive().optional(),
      imageUrl: z.string().url(),
      type: z
        .enum(['FOOD', 'PICKLE', 'CLOTHES', 'SNACK', 'SWEET', 'GROCERY', 'OTHER'])
        .default('FOOD'),
      isVeg: z.boolean().default(true),
      isAvailable: z.boolean().default(true),
      categoryId: z.string().optional(),
      tags: z.array(z.string()).default([]),
      sizes: z.array(z.string()).default([]),
      prepTimeMins: z.number().int().optional(),
    });
    const body = schema.parse(req.body);
    const product = await prisma.product.create({
      data: {
        vendorId: vendor.id,
        name: body.name,
        description: body.description,
        price: body.price,
        mrp: body.mrp,
        imageUrl: body.imageUrl,
        type: body.type as ProductType,
        isVeg: body.isVeg,
        isAvailable: body.isAvailable,
        categoryId: body.categoryId,
        tagsJson: JSON.stringify(body.tags),
        sizesJson: JSON.stringify(body.sizes),
        prepTimeMins: body.prepTimeMins,
      },
    });
    res.status(201).json({ product: serializeProduct(product) });
  } catch (e) {
    next(e);
  }
});

sellerRouter.patch('/products/:id', async (req: AuthedRequest, res, next) => {
  try {
    const vendor = await getOwnedVendor(req.user!.sub, req.user!.role);
    if (!vendor) {
      res.status(404).json({ error: 'No storefront' });
      return;
    }
    const existing = await prisma.product.findFirst({
      where: { id: req.params.id, vendorId: vendor.id },
    });
    if (!existing) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }
    const schema = z.object({
      name: z.string().min(2).optional(),
      description: z.string().min(5).optional(),
      price: z.number().positive().optional(),
      mrp: z.number().positive().nullable().optional(),
      imageUrl: z.string().url().optional(),
      isVeg: z.boolean().optional(),
      isAvailable: z.boolean().optional(),
      categoryId: z.string().nullable().optional(),
      tags: z.array(z.string()).optional(),
      sizes: z.array(z.string()).optional(),
      prepTimeMins: z.number().int().nullable().optional(),
    });
    const body = schema.parse(req.body);
    const product = await prisma.product.update({
      where: { id: existing.id },
      data: {
        name: body.name,
        description: body.description,
        price: body.price,
        mrp: body.mrp === null ? null : body.mrp,
        imageUrl: body.imageUrl,
        isVeg: body.isVeg,
        isAvailable: body.isAvailable,
        categoryId: body.categoryId === null ? null : body.categoryId,
        tagsJson: body.tags ? JSON.stringify(body.tags) : undefined,
        sizesJson: body.sizes ? JSON.stringify(body.sizes) : undefined,
        prepTimeMins:
          body.prepTimeMins === null ? null : body.prepTimeMins,
      },
    });
    res.json({ product: serializeProduct(product) });
  } catch (e) {
    next(e);
  }
});

sellerRouter.delete('/products/:id', async (req: AuthedRequest, res, next) => {
  try {
    const vendor = await getOwnedVendor(req.user!.sub, req.user!.role);
    if (!vendor) {
      res.status(404).json({ error: 'No storefront' });
      return;
    }
    const existing = await prisma.product.findFirst({
      where: { id: req.params.id, vendorId: vendor.id },
    });
    if (!existing) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }
    await prisma.product.delete({ where: { id: existing.id } });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

sellerRouter.get('/orders', async (req: AuthedRequest, res, next) => {
  try {
    const vendor = await getOwnedVendor(req.user!.sub, req.user!.role);
    if (!vendor) {
      res.status(404).json({ error: 'No storefront' });
      return;
    }
    const status = req.query.status as string | undefined;
    const orders = await prisma.order.findMany({
      where: {
        vendorId: vendor.id,
        ...(status ? { status: status as OrderStatus } : {}),
      },
      include: {
        items: true,
        events: { orderBy: { createdAt: 'asc' } },
        vendor: true,
        address: true,
      },
      orderBy: { placedAt: 'desc' },
    });
    res.json({ orders: orders.map(serializeOrder) });
  } catch (e) {
    next(e);
  }
});

sellerRouter.patch(
  '/orders/:id/status',
  async (req: AuthedRequest, res, next) => {
    try {
      const vendor = await getOwnedVendor(req.user!.sub, req.user!.role);
      if (!vendor) {
        res.status(404).json({ error: 'No storefront' });
        return;
      }
      const schema = z.object({
        status: z.enum([
          'CONFIRMED',
          'PREPARING',
          'OUT_FOR_DELIVERY',
          'DELIVERED',
          'CANCELLED',
        ]),
        message: z.string().optional(),
      });
      const body = schema.parse(req.body);
      const order = await prisma.order.findFirst({
        where: { id: req.params.id, vendorId: vendor.id },
        include: { address: true },
      });
      if (!order) {
        res.status(404).json({ error: 'Order not found' });
        return;
      }

      const status = body.status as OrderStatus;
      const updateData: {
        status: OrderStatus;
        deliveryPartner?: string;
        riderLat?: number;
        riderLng?: number;
      } = { status };

      if (status === OrderStatus.OUT_FOR_DELIVERY) {
        updateData.deliveryPartner = order.deliveryPartner || 'Ravi K.';
        updateData.riderLat = vendor.lat;
        updateData.riderLng = vendor.lng;
      }

      const updated = await prisma.order.update({
        where: { id: order.id },
        data: {
          ...updateData,
          events: {
            create: {
              status,
              message:
                body.message ||
                `Status updated to ${status.replaceAll('_', ' ').toLowerCase()}`,
              lat: updateData.riderLat,
              lng: updateData.riderLng,
            },
          },
        },
        include: {
          items: true,
          events: { orderBy: { createdAt: 'asc' } },
          vendor: true,
          address: true,
        },
      });

      const payload = serializeOrder(updated);
      getIo()?.to(`order:${order.id}`).emit('order:updated', payload);
      getIo()?.to(`user:${order.customerId}`).emit('order:updated', payload);

      // Simulate rider movement when out for delivery
      if (status === OrderStatus.OUT_FOR_DELIVERY) {
        simulateRider(
          order.id,
          vendor.lat,
          vendor.lng,
          order.address.lat ?? 17.44,
          order.address.lng ?? 78.39,
        );
      }

      res.json({ order: payload });
    } catch (e) {
      next(e);
    }
  },
);

sellerRouter.patch('/store', async (req: AuthedRequest, res, next) => {
  try {
    const vendor = await getOwnedVendor(req.user!.sub, req.user!.role);
    if (!vendor) {
      res.status(404).json({ error: 'No storefront' });
      return;
    }
    const schema = z.object({
      name: z.string().min(2).optional(),
      tagline: z.string().optional(),
      description: z.string().optional(),
      isOpen: z.boolean().optional(),
      freeDelivery: z.boolean().optional(),
      offerText: z.string().nullable().optional(),
      imageUrl: z.string().url().optional(),
      coverUrl: z.string().url().optional(),
      deliveryTimeMins: z.number().int().optional(),
    });
    const body = schema.parse(req.body);
    const updated = await prisma.vendor.update({
      where: { id: vendor.id },
      data: {
        name: body.name,
        tagline: body.tagline,
        description: body.description,
        isOpen: body.isOpen,
        freeDelivery: body.freeDelivery,
        offerText: body.offerText === null ? null : body.offerText,
        imageUrl: body.imageUrl,
        coverUrl: body.coverUrl,
        deliveryTimeMins: body.deliveryTimeMins,
      },
    });
    res.json({ vendor: serializeVendor(updated) });
  } catch (e) {
    next(e);
  }
});

/** Linear interpolate rider position over ~2 minutes (demo) */
function simulateRider(
  orderId: string,
  fromLat: number,
  fromLng: number,
  toLat: number,
  toLng: number,
) {
  const steps = 12;
  let i = 0;
  const timer = setInterval(async () => {
    i += 1;
    const t = Math.min(1, i / steps);
    const lat = fromLat + (toLat - fromLat) * t;
    const lng = fromLng + (toLng - fromLng) * t;
    try {
      const order = await prisma.order.findUnique({ where: { id: orderId } });
      if (
        !order ||
        order.status !== OrderStatus.OUT_FOR_DELIVERY
      ) {
        clearInterval(timer);
        return;
      }
      const updated = await prisma.order.update({
        where: { id: orderId },
        data: { riderLat: lat, riderLng: lng },
        include: {
          items: true,
          events: { orderBy: { createdAt: 'asc' } },
          vendor: true,
          address: true,
        },
      });
      getIo()?.to(`order:${orderId}`).emit('tracking:location', {
        orderId,
        lat,
        lng,
        status: updated.status,
        deliveryPartner: updated.deliveryPartner,
      });
      getIo()?.to(`order:${orderId}`).emit('order:updated', serializeOrder(updated));

      if (t >= 1) {
        clearInterval(timer);
        // Auto-deliver at end of demo route
        const delivered = await prisma.order.update({
          where: { id: orderId },
          data: {
            status: OrderStatus.DELIVERED,
            riderLat: toLat,
            riderLng: toLng,
            events: {
              create: {
                status: OrderStatus.DELIVERED,
                message: 'Order delivered',
                lat: toLat,
                lng: toLng,
              },
            },
          },
          include: {
            items: true,
            events: { orderBy: { createdAt: 'asc' } },
            vendor: true,
            address: true,
          },
        });
        getIo()
          ?.to(`order:${orderId}`)
          .emit('order:updated', serializeOrder(delivered));
      }
    } catch (e) {
      console.error('simulateRider', e);
      clearInterval(timer);
    }
  }, 10_000);
}
