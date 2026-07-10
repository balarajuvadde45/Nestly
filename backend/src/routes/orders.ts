import { Router } from 'express';
import { z } from 'zod';
import {
  OrderStatus,
  PaymentMethod,
  Role,
} from '@prisma/client';
import { prisma } from '../lib/prisma';
import { serializeOrder } from '../lib/serializers';
import {
  AuthedRequest,
  requireAuth,
  requireRole,
} from '../middleware/auth';
import { getIo } from '../socket';

export const ordersRouter = Router();

const placeSchema = z.object({
  vendorId: z.string(),
  addressId: z.string(),
  paymentMethod: z.enum(['UPI', 'CARD', 'COD', 'WALLET']).default('COD'),
  couponCode: z.string().optional(),
  notes: z.string().optional(),
  items: z
    .array(
      z.object({
        productId: z.string(),
        quantity: z.number().int().min(1),
        selectedSize: z.string().optional(),
        specialInstructions: z.string().optional(),
      }),
    )
    .min(1),
});

function computeCoupon(
  code: string | undefined,
  itemTotal: number,
): { discount: number; error?: string } {
  if (!code) return { discount: 0 };
  const c = code.trim().toUpperCase();
  if (c === 'NESTLY20') return { discount: Math.min(itemTotal * 0.2, 100) };
  if (c === 'FLAT50') {
    if (itemTotal < 199) return { discount: 0, error: 'Minimum order ₹199' };
    return { discount: 50 };
  }
  if (c === 'FIRST100') return { discount: Math.min(100, itemTotal) };
  return { discount: 0, error: 'Invalid coupon' };
}

ordersRouter.post(
  '/',
  requireAuth,
  requireRole(Role.CUSTOMER, Role.ADMIN, Role.SELLER),
  async (req: AuthedRequest, res, next) => {
    try {
      const body = placeSchema.parse(req.body);
      const vendor = await prisma.vendor.findUnique({
        where: { id: body.vendorId },
      });
      if (!vendor || !vendor.isApproved) {
        res.status(404).json({ error: 'Vendor not found' });
        return;
      }
      const address = await prisma.address.findFirst({
        where: { id: body.addressId, userId: req.user!.sub },
      });
      if (!address) {
        res.status(400).json({ error: 'Invalid address' });
        return;
      }

      const productIds = body.items.map((i) => i.productId);
      const products = await prisma.product.findMany({
        where: { id: { in: productIds }, vendorId: vendor.id },
      });
      if (products.length !== productIds.length) {
        res.status(400).json({ error: 'Some products are invalid for this vendor' });
        return;
      }

      const productMap = new Map(products.map((p) => [p.id, p]));
      let itemTotal = 0;
      const lineItems = body.items.map((i) => {
        const p = productMap.get(i.productId)!;
        itemTotal += p.price * i.quantity;
        return {
          productId: p.id,
          productName: p.name,
          productImage: p.imageUrl,
          unitPrice: p.price,
          quantity: i.quantity,
          selectedSize: i.selectedSize,
          specialInstructions: i.specialInstructions,
          isVeg: p.isVeg,
        };
      });

      const coupon = computeCoupon(body.couponCode, itemTotal);
      if (coupon.error && body.couponCode) {
        res.status(400).json({ error: coupon.error });
        return;
      }

      const deliveryFee =
        vendor.freeDelivery || itemTotal >= 199 ? 0 : 29;
      const platformFee = 5;
      const tax =
        (itemTotal + deliveryFee + platformFee - coupon.discount) * 0.05;
      const grandTotal = Math.max(
        0,
        itemTotal + deliveryFee + platformFee + tax - coupon.discount,
      );

      const order = await prisma.order.create({
        data: {
          customerId: req.user!.sub,
          vendorId: vendor.id,
          addressId: address.id,
          paymentMethod: body.paymentMethod as PaymentMethod,
          paymentStatus: body.paymentMethod === 'COD' ? 'PENDING' : 'PENDING',
          itemTotal,
          deliveryFee,
          platformFee,
          tax,
          discount: coupon.discount,
          grandTotal,
          couponCode: body.couponCode?.toUpperCase(),
          notes: body.notes,
          estimatedDelivery: new Date(
            Date.now() + (vendor.deliveryTimeMins + 10) * 60_000,
          ),
          items: { create: lineItems },
          events: {
            create: {
              status: OrderStatus.PLACED,
              message: 'Order placed successfully',
            },
          },
        },
        include: {
          items: true,
          events: true,
          vendor: true,
          address: true,
        },
      });

      await prisma.vendor.update({
        where: { id: vendor.id },
        data: { orderCount: { increment: 1 } },
      });

      const payload = serializeOrder(order);
      getIo()?.to(`user:${req.user!.sub}`).emit('order:updated', payload);
      if (vendor.ownerId) {
        getIo()?.to(`user:${vendor.ownerId}`).emit('order:new', payload);
      }
      getIo()?.to(`order:${order.id}`).emit('order:updated', payload);

      // Demo: auto-progress PLACED -> CONFIRMED after 8s
      setTimeout(() => void autoProgress(order.id, OrderStatus.CONFIRMED), 8000);
      setTimeout(() => void autoProgress(order.id, OrderStatus.PREPARING), 20000);

      res.status(201).json({ order: payload });
    } catch (e) {
      next(e);
    }
  },
);

async function autoProgress(orderId: string, status: OrderStatus) {
  try {
    const existing = await prisma.order.findUnique({ where: { id: orderId } });
    if (
      !existing ||
      existing.status === OrderStatus.CANCELLED ||
      existing.status === OrderStatus.DELIVERED
    ) {
      return;
    }
    // Only advance forward
    const order = [
      OrderStatus.PLACED,
      OrderStatus.CONFIRMED,
      OrderStatus.PREPARING,
      OrderStatus.OUT_FOR_DELIVERY,
      OrderStatus.DELIVERED,
    ];
    if (order.indexOf(existing.status) >= order.indexOf(status)) return;

    const messages: Record<string, string> = {
      CONFIRMED: 'Seller confirmed your order',
      PREPARING: 'Your order is being prepared',
      OUT_FOR_DELIVERY: 'Rider is on the way',
      DELIVERED: 'Order delivered',
    };

    const data: {
      status: OrderStatus;
      deliveryPartner?: string;
      riderLat?: number;
      riderLng?: number;
    } = { status };

    if (status === OrderStatus.OUT_FOR_DELIVERY) {
      data.deliveryPartner = 'Ravi K.';
      // Start near vendor
      const vendor = await prisma.vendor.findUnique({
        where: { id: existing.vendorId },
      });
      data.riderLat = vendor?.lat ?? 17.4486;
      data.riderLng = vendor?.lng ?? 78.3908;
    }

    const updated = await prisma.order.update({
      where: { id: orderId },
      data: {
        ...data,
        events: {
          create: {
            status,
            message: messages[status] || status,
            lat: data.riderLat,
            lng: data.riderLng,
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
    getIo()?.to(`order:${orderId}`).emit('order:updated', payload);
    getIo()?.to(`user:${updated.customerId}`).emit('order:updated', payload);
  } catch (e) {
    console.error('autoProgress failed', e);
  }
}

ordersRouter.get('/', requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const orders = await prisma.order.findMany({
      where: { customerId: req.user!.sub },
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

ordersRouter.get('/:id', requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const order = await prisma.order.findUnique({
      where: { id: req.params.id },
      include: {
        items: true,
        events: { orderBy: { createdAt: 'asc' } },
        vendor: true,
        address: true,
      },
    });
    if (!order) {
      res.status(404).json({ error: 'Order not found' });
      return;
    }
    // Allow customer, seller owner, or admin
    if (order.customerId !== req.user!.sub && req.user!.role !== Role.ADMIN) {
      const vendor = await prisma.vendor.findUnique({
        where: { id: order.vendorId },
      });
      if (vendor?.ownerId !== req.user!.sub) {
        res.status(403).json({ error: 'Forbidden' });
        return;
      }
    }
    res.json({ order: serializeOrder(order) });
  } catch (e) {
    next(e);
  }
});

ordersRouter.post(
  '/:id/cancel',
  requireAuth,
  async (req: AuthedRequest, res, next) => {
    try {
      const order = await prisma.order.findUnique({
        where: { id: req.params.id },
      });
      if (!order || order.customerId !== req.user!.sub) {
        res.status(404).json({ error: 'Order not found' });
        return;
      }
      if (
        [
          OrderStatus.OUT_FOR_DELIVERY,
          OrderStatus.DELIVERED,
          OrderStatus.CANCELLED,
        ].includes(order.status)
      ) {
        res.status(400).json({ error: 'Order cannot be cancelled now' });
        return;
      }
      const updated = await prisma.order.update({
        where: { id: order.id },
        data: {
          status: OrderStatus.CANCELLED,
          events: {
            create: {
              status: OrderStatus.CANCELLED,
              message: 'Order cancelled by customer',
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
      res.json({ order: payload });
    } catch (e) {
      next(e);
    }
  },
);

/** Customer/seller: get live tracking snapshot */
ordersRouter.get(
  '/:id/tracking',
  requireAuth,
  async (req: AuthedRequest, res, next) => {
    try {
      const order = await prisma.order.findUnique({
        where: { id: req.params.id },
        include: {
          vendor: true,
          address: true,
          events: { orderBy: { createdAt: 'asc' } },
        },
      });
      if (!order) {
        res.status(404).json({ error: 'Order not found' });
        return;
      }
      res.json({
        orderId: order.id,
        status: order.status,
        deliveryPartner: order.deliveryPartner,
        rider: {
          lat: order.riderLat,
          lng: order.riderLng,
        },
        vendor: {
          lat: order.vendor.lat,
          lng: order.vendor.lng,
          name: order.vendor.name,
        },
        dropoff: {
          lat: order.address.lat ?? 17.44,
          lng: order.address.lng ?? 78.39,
          label: order.address.label,
          address: `${order.address.fullAddress}, ${order.address.area}`,
        },
        estimatedDelivery: order.estimatedDelivery?.toISOString() ?? null,
        events: order.events,
      });
    } catch (e) {
      next(e);
    }
  },
);
