import { createHash } from 'crypto';
import { Router } from 'express';
import { Prisma } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { serializeOrder, serializeAddress } from '../lib/serializers';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import { getIo } from '../socket';
import { parseWholesaleTiers, priceForQuantity, safeJsonArray } from '../lib/marketplace';
import { orderInclude, transitionOrder } from '../lib/order-lifecycle';
import { fromPaise, toPaise, totals } from '../lib/pricing';
import { createPaymentLink, onlinePaymentsConfigured } from '../lib/payments';
import { expireStaleOnlineOrders } from '../lib/order-lifecycle';
import { env } from '../lib/env';


export const ordersRouter = Router();
const isTest = process.env.NODE_ENV === 'test';
ordersRouter.use(requireAuth);
const placeSchema = z.object({
  vendorId: z.string().min(1).max(100), addressId: z.string().min(1).max(100),
  paymentMethod: z.enum(['COD', 'UPI', 'CARD', 'WALLET']).default('COD'),
  notes: z.string().max(500).optional(),
  fulfillmentMode: z.literal('LOCAL_DELIVERY').default('LOCAL_DELIVERY'),
  items: z.array(z.object({
    productId: z.string().min(1).max(100), quantity: z.number().int().min(1).max(10000),
    selectedSize: z.string().max(50).optional(), specialInstructions: z.string().max(500).optional(),
  })).min(1).max(100),
}).strict();
type Input = z.infer<typeof placeSchema>;
const hash = (value: unknown) => createHash('sha256').update(JSON.stringify(value)).digest('hex');
const escapeHtml = (value: string): string =>
  value.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c] ?? c));
const fail = (message: string, status = 400): never => { throw Object.assign(new Error(message), { status }); };

async function quote(tx: Prisma.TransactionClient, customerId: string, body: Input) {
  const customer = await tx.user.findUnique({ where: { id: customerId } });
  if (!customer || customer.deletedAt) fail('Account unavailable', 401);
  const vendor = await tx.vendor.findUnique({ where: { id: body.vendorId } });
  if (!vendor || !vendor.isApproved || !vendor.isOpen) return fail('Seller is unavailable');
  if (!safeJsonArray(vendor.fulfillmentModesJson).includes('LOCAL_DELIVERY')) fail('Seller does not offer local delivery');
  const address = await tx.address.findFirst({ where: { id: body.addressId, userId: customerId } });
  if (!address) return fail('Choose a valid delivery address');
  if (address.city.trim().toLowerCase() !== vendor.city.trim().toLowerCase()) fail('This seller does not deliver to the selected city');
  const serviceable = safeJsonArray(vendor.serviceablePincodesJson).map(String);
  const pinOk = serviceable.length > 0 ? serviceable.includes(address.pincode) : Boolean(vendor.pincode && address.pincode === vendor.pincode);
  if (!pinOk) fail('This seller does not deliver to the selected pincode');
  const ids = [...new Set(body.items.map(i => i.productId))];
  const products = await tx.product.findMany({ where: { id: { in: ids }, vendorId: vendor.id } });
  if (products.length !== ids.length) fail('One or more items are unavailable');
  const quantities = new Map<string, number>();
  for (const item of body.items) quantities.set(item.productId, (quantities.get(item.productId) ?? 0) + item.quantity);
  const lines = body.items.map(item => {
    const product = products.find(p => p.id === item.productId)!;
    const quantity = quantities.get(product.id)!;
    if (!product.isAvailable || (product.expiryDate && product.expiryDate <= new Date())) fail(product.name + ' is unavailable');
    if (item.quantity < product.minOrderQuantity ||
        (product.casePackQuantity && item.quantity % product.casePackQuantity !== 0)) fail(product.name + ': check minimum quantity and case pack');
    if (product.maxOrderQuantity && quantity > product.maxOrderQuantity) fail(product.name + ': maximum quantity exceeded');
    if (product.stockQuantity != null && quantity > product.stockQuantity) fail(product.name + ': insufficient stock');
    const sizes = safeJsonArray(product.sizesJson);
    if ((sizes.length && !sizes.includes(item.selectedSize ?? '')) || (!sizes.length && item.selectedSize)) fail(product.name + ': select a valid size');
    const unitPrice = fromPaise(toPaise(priceForQuantity(product.price, item.quantity, parseWholesaleTiers(product.wholesaleTiersJson))));
    const gstRate = product.gstRate ?? 0;
    if (product.mrp != null && unitPrice > product.mrp) fail(product.name + ': price exceeds MRP');
    return {
      productId: product.id, productName: product.name, productImage: product.imageUrl,
      unitPrice, quantity: item.quantity, unitLabel: product.unitLabel,
      hsnCode: product.hsnCode, gstRate,
      lineTax: fromPaise(Math.round(toPaise(unitPrice) * item.quantity * gstRate / (100 + gstRate))),
      selectedSize: item.selectedSize, specialInstructions: item.specialInstructions, isVeg: product.isVeg,
    };
  });
  const amounts = totals(lines, vendor.freeDelivery);
  if (vendor.minOrder != null && amounts.itemTotal < vendor.minOrder) fail('Minimum order is Rs ' + vendor.minOrder);
  const addressSnapshot = serializeAddress(address);
  const quoteHash = hash({ body, lines, amounts, address: addressSnapshot, sellerGstin: vendor.gstin });
  return { vendor, address, addressSnapshot, products, quantities, lines, amounts, quoteHash };
}

ordersRouter.post('/quote', async (req: AuthedRequest, res, next) => {
  try {
    const body = placeSchema.parse(req.body);
    const result = await quote(prisma, req.user!.sub, body);
    res.json({ quote: { ...result.amounts, items: result.lines, quoteHash: result.quoteHash } });
  } catch (e) { next(e); }
});

ordersRouter.post('/', async (req: AuthedRequest, res, next) => {
  try {
    const { idempotencyKey, quoteHash, ...raw } = z.object({
      idempotencyKey: z.string().uuid(), quoteHash: z.string().regex(/^[a-f0-9]{64}$/),
    }).passthrough().parse(req.body);
    const body = placeSchema.parse(raw);
    const customerId = req.user!.sub;
    const requestHash = hash({ body, quoteHash });
    const key = { customerId_idempotencyKey: { customerId, idempotencyKey } };
    const replay = async () => {
      const previous = await prisma.order.findUnique({ where: key, include: orderInclude });
      if (previous && previous.requestHash !== requestHash) fail('Checkout key was already used for a different request', 409);
      return previous;
    };
    const previous = await replay();
    if (previous) { res.json({ order: serializeOrder(previous) }); return; }
    let order;
    try {
      order = await prisma.$transaction(async tx => {
        const result = await quote(tx, customerId, body);
        if (result.quoteHash !== quoteHash) fail('Prices or availability changed. Review your order again.', 409);
        for (const product of result.products) {
          if (product.stockQuantity == null) continue;
          const quantity = result.quantities.get(product.id)!;
          const updated = await tx.product.updateMany({
            where: { id: product.id, stockQuantity: { gte: quantity }, isAvailable: true },
            data: { stockQuantity: { decrement: quantity } },
          });
          if (updated.count !== 1) fail('Stock changed. Review your order again.', 409);
        }
        const created = await tx.order.create({
          data: {
            customerId, vendorId: result.vendor.id, addressId: result.address.id,
            addressSnapshotJson: JSON.stringify(result.addressSnapshot),
            idempotencyKey, requestHash, paymentMethod: body.paymentMethod, paymentStatus: 'PENDING',
            ...result.amounts, fulfillmentMode: body.fulfillmentMode, sellerGstin: result.vendor.gstin,
            notes: body.notes,
            estimatedDelivery: new Date(Date.now() + result.vendor.deliveryTimeMins * 60000 + Math.max(0, ...result.products.map(p => p.dispatchTimeDays ?? 0)) * 86400000),
            items: { create: result.lines },
            events: { create: { status: 'PLACED', message: 'Order placed' } },
          }, include: orderInclude,
        });
        await tx.vendor.update({ where: { id: result.vendor.id }, data: { orderCount: { increment: 1 } } });
        return created;
      }, { isolationLevel: 'Serializable' });
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && ['P2002', 'P2034'].includes(e.code)) {
        const existing = await replay();
        if (existing) { res.json({ order: serializeOrder(existing) }); return; }
      }
      throw e;
    }
    if (body.paymentMethod !== 'COD') {
      if (!onlinePaymentsConfigured()) {
        await transitionOrder({ id: order.id }, 'CANCELLED', 'Cancelled: online payments are not configured');
        fail('Online payments are not configured yet. Please choose cash on delivery.', 503);
      }
      try {
        const customer = await prisma.user.findUnique({ where: { id: customerId }, select: { name: true, phone: true, email: true } });
        const link = await createPaymentLink({
          orderId: order.id,
          amountPaise: Math.round((order.grandTotal) * 100),
          customerName: customer?.name ?? 'Nestly customer',
          customerPhone: customer?.phone ?? '',
          customerEmail: customer?.email ?? '',
          description: `Nestly order ${order.id.slice(0, 8)}`,
        });
        order = await prisma.order.update({
          where: { id: order.id },
          data: { paymentLinkId: link.linkId, paymentUrl: link.shortUrl, paymentProvider: 'razorpay' },
          include: orderInclude,
        });
      } catch (e) {
        await transitionOrder({ id: order.id }, 'CANCELLED', 'Cancelled: payment link could not be created');
        throw e;
      }
    }
    const payload = serializeOrder(order);
    getIo()?.to('user:' + customerId).emit('order:updated', payload);
    if (order.vendor.ownerId) getIo()?.to('user:' + order.vendor.ownerId).emit('order:new', payload);
    res.status(201).json({ order: payload });
  } catch (e) { next(e); }
});

ordersRouter.get('/', async (req: AuthedRequest, res, next) => {
  try {
    if (!isTest) await expireStaleOnlineOrders();
    const page = z.coerce.number().int().min(1).max(10000).default(1).parse(req.query.page);
    const orders = await prisma.order.findMany({
      where: { customerId: req.user!.sub }, include: orderInclude,
      orderBy: [{ placedAt: 'desc' }, { id: 'desc' }], take: 50, skip: (page - 1) * 50,
    });
    res.json({ orders: orders.map(serializeOrder), page, hasMore: orders.length === 50 });
  } catch (e) { next(e); }
});

ordersRouter.get('/:id', async (req: AuthedRequest, res, next) => {
  try {
    const order = await prisma.order.findFirst({
      where: { id: String(req.params.id), ...(req.user!.role === 'ADMIN' ? {} : {
        OR: [{ customerId: req.user!.sub }, { vendor: { ownerId: req.user!.sub } }],
      }) }, include: orderInclude,
    });
    if (!order) { res.status(404).json({ error: 'Order not found' }); return; }
    res.json({ order: serializeOrder(order) });
  } catch (e) { next(e); }
});
/**
 * Create (or reuse) the Razorpay payment link for an unpaid online order.
 *COD orders and already-paid orders are refused with a clear message.
 */
ordersRouter.post('/:id/pay', async (req: AuthedRequest, res, next) => {
  try {
    const order = await prisma.order.findFirst({
      where: { id: String(req.params.id), customerId: req.user!.sub }, include: orderInclude,
    });
    if (!order) { res.status(404).json({ error: 'Order not found' }); return; }
    if (order.paymentMethod === 'COD') { res.status(400).json({ error: 'Cash on delivery orders do not use online payment' }); return; }
    if (order.paymentStatus === 'PAID') { res.json({ paid: true, order: serializeOrder(order) }); return; }
    if (order.status !== 'PLACED' || order.paymentStatus === 'CANCELLED') {
      res.status(409).json({ error: 'Order changed. Refresh and try again.' }); return;
    }
    if (order.paymentLinkId && order.paymentUrl) {
      res.json({ paid: false, paymentUrl: order.paymentUrl, order: serializeOrder(order) }); return;
    }
    if (!onlinePaymentsConfigured()) {
      res.status(503).json({ error: 'Online payments are not configured yet. Please choose cash on delivery.' }); return;
    }
    const customer = await prisma.user.findUnique({ where: { id: req.user!.sub }, select: { name: true, phone: true, email: true } });
    const link = await createPaymentLink({
      orderId: order.id,
      amountPaise: Math.round(order.grandTotal * 100),
      customerName: customer?.name ?? 'Nestly customer',
      customerPhone: customer?.phone ?? '',
      customerEmail: customer?.email ?? '',
      description: `Nestly order ${order.id.slice(0, 8)}`,
    });
    const updated = await prisma.order.update({
      where: { id: order.id },
      data: { paymentLinkId: link.linkId, paymentUrl: link.shortUrl, paymentProvider: 'razorpay', paymentStatus: 'PENDING' },
      include: orderInclude,
    });
    res.json({ paid: false, paymentUrl: link.shortUrl, order: serializeOrder(updated) });
  } catch (e) { next(e); }
});

/** Printable GST-style invoice for a delivered order. */
ordersRouter.get('/:id/invoice', async (req: AuthedRequest, res, next) => {
  try {
    const order = await prisma.order.findFirst({
      where: { id: String(req.params.id), ...(req.user!.role === 'ADMIN' ? {} : {
        OR: [{ customerId: req.user!.sub }, { vendor: { ownerId: req.user!.sub } }],
      }) }, include: orderInclude,
    });
    if (!order) { res.status(404).json({ error: 'Order not found' }); return; }
    if (order.status !== 'DELIVERED') { res.status(409).json({ error: 'Invoices are issued after delivery' }); return; }
    let invoiceNumber = order.invoiceNumber;
    if (!invoiceNumber) {
      invoiceNumber = await prisma.$transaction(async tx => {
        const counter = await tx.counter.upsert({
          where: { id: 'invoice' }, create: { id: 'invoice', value: 1 }, update: { value: { increment: 1 } },
        });
        const value = `NL-${new Date().getFullYear()}-${String(counter.value).padStart(6, '0')}`;
        await tx.order.update({ where: { id: order.id }, data: { invoiceNumber: value } });
        return value;
      });
    }
    const buyer = order.addressSnapshotJson ? JSON.parse(order.addressSnapshotJson) as Record<string, string> : {};
    const rows = order.items.map(i => `
        <tr>
          <td>${escapeHtml(i.productName)}${i.selectedSize ? ` (${escapeHtml(i.selectedSize)})` : ''}</td>
          <td style="text-align:center">${i.quantity}</td>
          <td style="text-align:right">&#8377;${i.unitPrice.toFixed(2)}</td>
          <td style="text-align:right">${i.gstRate ?? 0}%</td>
          <td style="text-align:right">&#8377;${(i.lineTax ?? 0).toFixed(2)}</td>
          <td style="text-align:right">&#8377;${(i.unitPrice * i.quantity).toFixed(2)}</td>
        </tr>`).join('');
    const html = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Invoice ${escapeHtml(invoiceNumber)}</title></head>
<body style="font-family:Arial,Helvetica,sans-serif;max-width:720px;margin:24px auto;color:#1a1a1a">
  <h1 style="font-size:20px;margin:0">Nestly tax invoice</h1>
  <p style="color:#555;margin:4px 0 16px">${escapeHtml(invoiceNumber)} &middot; ${order.placedAt.toISOString().slice(0, 10)}</p>
  <p style="margin:4px 0"><strong>Sold by:</strong> ${escapeHtml(order.vendor.name)}${order.vendor.gstin ? ` &middot; GSTIN ${escapeHtml(order.vendor.gstin)}` : ' &middot; GSTIN not provided'}</p>
  <p style="margin:4px 0"><strong>Billed to:</strong> ${escapeHtml(buyer.label ?? 'Customer')}, ${escapeHtml(buyer.fullAddress ?? '')}, ${escapeHtml(buyer.city ?? '')} ${escapeHtml(buyer.pincode ?? '')}</p>
  <table style="width:100%;border-collapse:collapse;margin-top:16px;font-size:14px">
    <thead><tr style="border-bottom:2px solid #333">
      <th style="text-align:left;padding:6px">Item</th><th style="text-align:center;padding:6px">Qty</th>
      <th style="text-align:right;padding:6px">Unit (incl. GST)</th><th style="text-align:right;padding:6px">GST</th>
      <th style="text-align:right;padding:6px">Tax</th><th style="text-align:right;padding:6px">Total</th>
    </tr></thead>
    <tbody>${rows}</tbody>
  </table>
  <table style="width:100%;margin-top:16px;font-size:14px">
    <tr><td style="padding:2px 0">Item total</td><td style="text-align:right">&#8377;${order.itemTotal.toFixed(2)}</td></tr>
    <tr><td style="padding:2px 0">Delivery</td><td style="text-align:right">&#8377;${order.deliveryFee.toFixed(2)}</td></tr>
    <tr><td style="padding:2px 0">Platform fee</td><td style="text-align:right">&#8377;${order.platformFee.toFixed(2)}</td></tr>
    <tr><td style="padding:6px 0;border-top:2px solid #333"><strong>Paid (${order.paymentMethod === 'COD' ? 'cash on delivery' : escapeHtml(order.paymentMethod)})</strong></td>
        <td style="text-align:right;border-top:2px solid #333"><strong>&#8377;${order.grandTotal.toFixed(2)}</strong></td></tr>
  </table>
  <p style="color:#666;font-size:12px;margin-top:24px">Prices are GST-inclusive. This invoice was generated from the delivered order record.</p>
</body></html>`;
    res.type('html').send(html);
  } catch (e) { next(e); }
});

ordersRouter.post('/:id/cancel' , async (req: AuthedRequest, res, next) => {
  try {
    const order = await transitionOrder(
      { id: String(req.params.id), customerId: req.user!.sub }, 'CANCELLED', 'Cancelled by customer', true,
    );
    const payload = serializeOrder(order);
    getIo()?.to('order:' + order.id).emit('order:updated', payload);
    if (order.vendor.ownerId) getIo()?.to('user:' + order.vendor.ownerId).emit('order:updated', payload);
    res.json({ order: payload });
  } catch (e) { next(e); }
});
ordersRouter.get('/:id/tracking', async (req: AuthedRequest, res, next) => {
  try {
    const order = await prisma.order.findFirst({
      where: { id: String(req.params.id), ...(req.user!.role === 'ADMIN' ? {} : {
        OR: [{ customerId: req.user!.sub }, { vendor: { ownerId: req.user!.sub } }],
      }) }, include: orderInclude,
    });
    if (!order) { res.status(404).json({ error: 'Order not found' }); return; }
    res.json({ order: serializeOrder(order), orderId: order.id, status: order.status,
      rider: { lat: order.riderLat, lng: order.riderLng } });
  } catch (e) { next(e); }
});
