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
  requireSellerAccess,
} from '../middleware/auth';
import { transitionOrder } from '../lib/order-lifecycle';
import { getIo } from '../socket';
import {
  defaultFulfillmentModes,
  categoryForProductType,
  fulfillmentModeSchema,
  normalizeString,
  normalizeWholesaleTiers,
  productTypeSchema,
  vendorTypeSchema,
  wholesaleTierSchema,
} from '../lib/marketplace';

export const sellerRouter = Router();

/** Seller dashboard API — JWT SELLER or DB-owned business (stale buyer token safe) */
sellerRouter.use(requireAuth, requireSellerAccess());

async function getOwnedVendor(userId: string, role: Role) {

  return prisma.vendor.findUnique({ where: { ownerId: userId } });
}

async function logSeller(
  userId: string,
  action: string,
  message?: string,
  meta?: Record<string, unknown>,
) {
  try {
    await prisma.activityLog.create({
      data: {
        userId,
        mode: 'SELLER',
        action,
        message,
        metaJson: meta ? JSON.stringify(meta) : null,
      },
    });
  } catch {
    // non-blocking
  }
}

const nullableTrimmedString = z
  .string()
  .trim()
  .optional()
  .nullable();

const imageUrlSchema = z.string().url().refine(value => {
  const url = new URL(value);
  return url.protocol === 'https:' && !url.username && !url.password;
}, 'Use a public HTTPS image URL without credentials');

const productCreateSchema = z.object({
  name: z.string().min(2),
  description: z.string().min(5),
  price: z.number().positive(),
  mrp: z.number().positive().optional(),
  imageUrl: imageUrlSchema,
  type: productTypeSchema.default('FOOD'),
  isVeg: z.boolean().default(true),
  isAvailable: z.boolean().default(true),
  categoryId: z.string().optional().nullable(),
  tags: z.array(z.string()).default([]),
  sizes: z.array(z.string()).default([]),
  colors: z.array(z.string()).default([]),
  prepTimeMins: z.number().int().positive().optional().nullable(),
  brandName: nullableTrimmedString,
  sku: nullableTrimmedString,
  unitLabel: nullableTrimmedString,
  minOrderQuantity: z.number().int().min(1).default(1),
  casePackQuantity: z.number().int().min(1).optional().nullable(),
  maxOrderQuantity: z.number().int().min(1).optional().nullable(),
  stockQuantity: z.number().int().min(0).optional().nullable(),
  hsnCode: nullableTrimmedString,
  gstRate: z.number().min(0).max(28).optional().nullable(),
  batchNumber: nullableTrimmedString,
  manufactureDate: z.coerce.date().optional().nullable(),
  expiryDate: z.coerce.date().optional().nullable(),
  shelfLifeDays: z.number().int().min(1).optional().nullable(),
  manufacturerName: nullableTrimmedString,
  packerName: nullableTrimmedString,
  originCountry: nullableTrimmedString,
  fssaiLicense: nullableTrimmedString,
  isReturnable: z.boolean().default(false),
  returnWindowDays: z.number().int().min(1).optional().nullable(),
  madeToOrder: z.boolean().default(false),
  dispatchTimeDays: z.number().int().min(0).optional().nullable(),
  wholesaleTiers: z.array(wholesaleTierSchema).default([]),
  material: nullableTrimmedString,
});

const productPatchSchema = productCreateSchema.partial().extend({
  mrp: z.number().positive().optional().nullable(),
});

/** Register / claim a seller storefront (legacy path — prefer /api/buyer/open-business) */
sellerRouter.post('/onboard', (_req, res) => {
  res.status(410).json({ error: 'Create your business through /api/buyer/open-business' });
});

/** Seller-side activity log */
sellerRouter.post('/log', async (req: AuthedRequest, res, next) => {
  try {
    const schema = z.object({
      action: z.string().min(2),
      message: z.string().optional(),
      meta: z.record(z.unknown()).optional(),
    });
    const body = schema.parse(req.body);
    await logSeller(req.user!.sub, body.action, body.message, body.meta);
    res.status(201).json({ ok: true, mode: 'seller' });
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
      vendor: serializeVendor(vendor, true),
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
    const body = productCreateSchema.parse(req.body);
    const wholesaleTiers = normalizeWholesaleTiers(body.wholesaleTiers);
    const product = await prisma.product.create({
      data: {
        vendorId: vendor.id,
        name: body.name,
        description: body.description,
        price: body.price,
        mrp: body.mrp,
        brandName: normalizeString(body.brandName),
        sku: normalizeString(body.sku),
        unitLabel: normalizeString(body.unitLabel),
        minOrderQuantity: body.minOrderQuantity,
        casePackQuantity: body.casePackQuantity,
        maxOrderQuantity: body.maxOrderQuantity,
        stockQuantity: body.stockQuantity,
        hsnCode: normalizeString(body.hsnCode),
        gstRate: body.gstRate,
        batchNumber: normalizeString(body.batchNumber),
        manufactureDate: body.manufactureDate,
        expiryDate: body.expiryDate,
        shelfLifeDays: body.shelfLifeDays,
        manufacturerName: normalizeString(body.manufacturerName),
        packerName: normalizeString(body.packerName),
        originCountry: normalizeString(body.originCountry) ?? 'India',
        fssaiLicense:
          normalizeString(body.fssaiLicense) ?? vendor.fssaiLicense,
        isReturnable: body.isReturnable,
        returnWindowDays: body.returnWindowDays,
        madeToOrder: body.madeToOrder,
        dispatchTimeDays: body.dispatchTimeDays,
        wholesaleTiersJson: JSON.stringify(wholesaleTiers),
        colorsJson: JSON.stringify(body.colors),
        material: normalizeString(body.material),
        imageUrl: body.imageUrl,
        type: body.type as ProductType,
        isVeg: body.isVeg,
        isAvailable: body.isAvailable,
        categoryId: body.categoryId ?? categoryForProductType(body.type),
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
      where: { id: String(req.params.id), vendorId: vendor.id },
    });
    if (!existing) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }
    const body = productPatchSchema.parse(req.body);
    const product = await prisma.product.update({
      where: { id: existing.id },
      data: {
        name: body.name,
        description: body.description,
        price: body.price,
        mrp: body.mrp === null ? null : body.mrp,
        brandName:
          body.brandName === undefined ? undefined : normalizeString(body.brandName),
        sku: body.sku === undefined ? undefined : normalizeString(body.sku),
        unitLabel:
          body.unitLabel === undefined ? undefined : normalizeString(body.unitLabel),
        minOrderQuantity: body.minOrderQuantity,
        casePackQuantity:
          body.casePackQuantity === null ? null : body.casePackQuantity,
        maxOrderQuantity:
          body.maxOrderQuantity === null ? null : body.maxOrderQuantity,
        stockQuantity:
          body.stockQuantity === null ? null : body.stockQuantity,
        hsnCode:
          body.hsnCode === undefined ? undefined : normalizeString(body.hsnCode),
        gstRate: body.gstRate === null ? null : body.gstRate,
        batchNumber:
          body.batchNumber === undefined
            ? undefined
            : normalizeString(body.batchNumber),
        manufactureDate:
          body.manufactureDate === null ? null : body.manufactureDate,
        expiryDate: body.expiryDate === null ? null : body.expiryDate,
        shelfLifeDays:
          body.shelfLifeDays === null ? null : body.shelfLifeDays,
        manufacturerName:
          body.manufacturerName === undefined
            ? undefined
            : normalizeString(body.manufacturerName),
        packerName:
          body.packerName === undefined
            ? undefined
            : normalizeString(body.packerName),
        originCountry:
          body.originCountry === undefined
            ? undefined
            : normalizeString(body.originCountry),
        fssaiLicense:
          body.fssaiLicense === undefined
            ? undefined
            : normalizeString(body.fssaiLicense),
        isReturnable: body.isReturnable,
        returnWindowDays:
          body.returnWindowDays === null ? null : body.returnWindowDays,
        madeToOrder: body.madeToOrder,
        dispatchTimeDays:
          body.dispatchTimeDays === null ? null : body.dispatchTimeDays,
        wholesaleTiersJson:
          body.wholesaleTiers === undefined
            ? undefined
            : JSON.stringify(normalizeWholesaleTiers(body.wholesaleTiers)),
        colorsJson:
          body.colors === undefined ? undefined : JSON.stringify(body.colors),
        material:
          body.material === undefined ? undefined : normalizeString(body.material),
        imageUrl: body.imageUrl,
        type: body.type as ProductType | undefined,
        isVeg: body.isVeg,
        isAvailable: body.isAvailable,
        categoryId: body.categoryId === null ? null : body.categoryId ?? (body.type ? categoryForProductType(body.type) : undefined),
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
      where: { id: String(req.params.id), vendorId: vendor.id },
    });
    if (!existing) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }
    await prisma.product.update({ where: { id: existing.id }, data: { isAvailable: false } });
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

sellerRouter.patch('/orders/:id/status', async (req: AuthedRequest, res, next) => {
  try {
    const vendor = await getOwnedVendor(req.user!.sub, req.user!.role);
    if (!vendor) { res.status(404).json({ error: 'No storefront' }); return; }
    const body = z.object({
      status: z.enum(['CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED']),
      message: z.string().max(500).optional(),
      cashCollected: z.boolean().optional(),
    }).parse(req.body);
    if (body.status === 'DELIVERED' && body.cashCollected !== true) {
      res.status(400).json({ error: 'Confirm cash collection before marking delivery complete' }); return;
    }
    const order = await transitionOrder(
      { id: String(req.params.id), vendorId: vendor.id }, body.status,
      body.message || 'Status updated to ' + body.status.toLowerCase().replaceAll('_', ' '),
    );
    const payload = serializeOrder(order);
    getIo()?.to('order:' + order.id).emit('order:updated', payload);
    getIo()?.to('user:' + order.customerId).emit('order:updated', payload);
    res.json({ order: payload });
  } catch (e) { next(e); }
});

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
      area: z.string().min(2).optional(),
      city: z.string().min(2).optional(),
      businessAddress: z.string().nullable().optional(),
      pincode: z.string().regex(/^\d{6}$/).nullable().optional(),
      premisesType: z.string().optional(),
      supportPhone: z.string().nullable().optional(),
      supportEmail: z.string().email().nullable().optional(),
      gstin: z.string().nullable().optional(),
      pan: z.string().nullable().optional(),
      fssaiLicense: z.string().nullable().optional(),
      fssaiExpiry: z.coerce.date().nullable().optional(),
      bankAccountLast4: z.string().regex(/^\d{4}$/).nullable().optional(),
      fulfillmentModes: z.array(fulfillmentModeSchema).optional(),
      serviceRadiusKm: z.number().positive().optional(),
      gstInvoiceAvailable: z.boolean().optional(),
      acceptsWholesale: z.boolean().optional(),
      isOpen: z.boolean().optional(),
      freeDelivery: z.boolean().optional(),
      minOrder: z.number().min(0).nullable().optional(),
      offerText: z.string().nullable().optional(),
      imageUrl: imageUrlSchema.optional(),
      coverUrl: imageUrlSchema.optional(),
      deliveryTimeMins: z.number().int().min(1).max(10080).optional(),
    });
    const body = schema.parse(req.body);
    const needsReview = ['businessAddress', 'city', 'pincode', 'gstin', 'pan', 'fssaiLicense', 'fssaiExpiry'].some(
      key => key in body && body[key as keyof typeof body] !== vendor[key as keyof typeof vendor],
    );
    const updated = await prisma.$transaction(async tx => {
      if (needsReview) await tx.sellerApplication.updateMany({
        where: { vendorId: vendor.id }, data: { status: 'PENDING', reviewedAt: null, reviewedBy: null },
      });
      return tx.vendor.update({
      where: { id: vendor.id },
      data: {
        ...(needsReview ? { isApproved: false, kycStatus: 'PENDING' } : {}),
        name: body.name,
        tagline: body.tagline,
        description: body.description,
        area: body.area,
        city: body.city,
        businessAddress:
          body.businessAddress === undefined
            ? undefined
            : normalizeString(body.businessAddress),
        pincode:
          body.pincode === undefined ? undefined : normalizeString(body.pincode),
        premisesType: body.premisesType,
        supportPhone:
          body.supportPhone === undefined
            ? undefined
            : normalizeString(body.supportPhone),
        supportEmail:
          body.supportEmail === undefined
            ? undefined
            : normalizeString(body.supportEmail),
        gstin: body.gstin === undefined ? undefined : normalizeString(body.gstin),
        pan: body.pan === undefined ? undefined : normalizeString(body.pan),
        fssaiLicense:
          body.fssaiLicense === undefined
            ? undefined
            : normalizeString(body.fssaiLicense),
        fssaiExpiry: body.fssaiExpiry === null ? null : body.fssaiExpiry,
        bankAccountLast4:
          body.bankAccountLast4 === null ? null : body.bankAccountLast4,
        fulfillmentModesJson:
          body.fulfillmentModes === undefined
            ? undefined
            : JSON.stringify(body.fulfillmentModes),
        serviceRadiusKm: body.serviceRadiusKm,
        gstInvoiceAvailable: body.gstInvoiceAvailable,
        acceptsWholesale: body.acceptsWholesale,
        isOpen: body.isOpen,
        freeDelivery: body.freeDelivery,
        minOrder: body.minOrder === null ? null : body.minOrder,
        offerText: body.offerText === null ? null : body.offerText,
        imageUrl: body.imageUrl,
        coverUrl: body.coverUrl,
        deliveryTimeMins: body.deliveryTimeMins,
      },
    });
    });
    res.json({ vendor: serializeVendor(updated, true) });
  } catch (e) {
    next(e);
  }
});
