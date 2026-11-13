import { randomUUID } from 'crypto';
import { beforeAll, beforeEach, afterAll, describe, it, expect } from 'vitest';
import request from 'supertest';
import { prisma } from '../lib/prisma';
import { createApp } from '../app';
import { signToken, hashPassword } from '../lib/auth';
import { transitionOrder } from '../lib/order-lifecycle';
import { expireStaleOnlineOrders } from '../lib/order-lifecycle';

describe.skipIf(!process.env.TEST_DATABASE_URL)('Marketplace commerce', () => {
  const app = createApp();
  const buyer = randomUUID(), owner = randomUUID(), vendor = randomUUID(),
        product = randomUUID(), address = randomUUID();
  const token = signToken({ sub: buyer, role: 'CUSTOMER', email: buyer + '@test.invalid' });
  const sellerToken = signToken({ sub: owner, role: 'SELLER', email: owner + '@test.invalid' });
  const H = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  let order = '';
  let quoteHash = '';
  const body = { vendorId: vendor, addressId: address, paymentMethod: 'COD', items: [{ productId: product, quantity: 2 }] };

  const quote = () => request(app).post('/api/orders/quote').auth(token, { type: 'bearer' }).send(body);
  const place = () => request(app).post('/api/orders').auth(token, { type: 'bearer' })
    .send({ ...body, quoteHash, idempotencyKey: randomUUID() });

  beforeAll(async () => {
    const passwordHash = await hashPassword('integration-test-password');
    await prisma.user.createMany({
      data: [buyer, owner].map(id => ({
        id, email: id + '@test.invalid', name: 'Mkt test',
        phone: id, passwordHash, role: id === owner ? 'SELLER' : 'CUSTOMER',
      })),
    });
    await prisma.vendor.create({
      data: {
        id: vendor, ownerId: owner, name: 'Mkt seller', tagline: '', description: '',
        type: 'FMCG_DISTRIBUTOR', imageUrl: '', coverUrl: '', area: 'Test', city: 'Hyderabad',
        pincode: '500081', serviceablePincodesJson: '["500081","500032"]', commissionRate: 0, isApproved: true,
      },
    });
    await prisma.product.create({
      data: { id: product, vendorId: vendor, name: 'Mkt item', description: '', imageUrl: '', price: 200, gstRate: 5, stockQuantity: 10 },
    });
    await prisma.address.create({
      data: { id: address, userId: buyer, label: 'Home', fullAddress: 'Flat 1', area: 'Test', city: 'Hyderabad', pincode: '500032' },
    });
  });

  beforeEach(async () => {
    await prisma.order.deleteMany({ where: { vendorId: vendor } });
    await prisma.product.update({ where: { id: product }, data: { price: 200, stockQuantity: 10, maxOrderQuantity: null } });
    await prisma.review.deleteMany({ where: { productId: product } });
    await prisma.address.update({ where: { id: address }, data: { pincode: '500032' } });
  });

  afterAll(async () => {
    await prisma.order.deleteMany({ where: { vendorId: vendor } });
    await prisma.vendor.deleteMany({ where: { id: vendor } });
    await prisma.user.deleteMany({ where: { id: { in: [buyer, owner] } } });
    await prisma.$disconnect();
  });

  it('serves the wider serviceable pincodes, not just the seller pincode', async () => {
    const q = await quote();
    expect(q.status).toBe(200);
    quoteHash = q.body.quote.quoteHash;
  });

  it('refuses a pincode outside the serviceable list', async () => {
    await prisma.address.update({ where: { id: address }, data: { pincode: '999999' } });
    const q = await quote();
    expect(q.status).toBe(400);
  });

  it('places, delivers, keeps the ledger and assigns an invoice number', async () => {
    quoteHash = (await quote()).body.quote.quoteHash;
    const placed = await place();
    expect(placed.status).toBe(201);
    order = placed.body.order.id;
    expect(placed.body.order.paymentMethod).toBe('COD');

    await transitionOrder({ id: order }, 'CONFIRMED', 'ok');
    await transitionOrder({ id: order }, 'PREPARING', 'ok');
    await transitionOrder({ id: order }, 'OUT_FOR_DELIVERY', 'ok');
    await transitionOrder({ id: order }, 'DELIVERED', 'ok');

    const after = await prisma.order.findUniqueOrThrow({ where: { id: order } });
    expect(after.status).toBe('DELIVERED');
    expect(after.paymentStatus).toBe('PAID');
    expect(after.invoiceNumber).toMatch(/^NL-\d{4}-\d{6}$/);

    const ledger = await prisma.sellerLedgerEntry.findFirst({ where: { vendorId: vendor, orderId: order } });
    expect(ledger).not.toBeNull();
    // 10 percent commission on the 400 item total: seller keeps 360
    expect(ledger!.amount).toBe(360);

    const earnings = await request(app).get('/api/seller/earnings').auth(sellerToken, { type: 'bearer' });
    expect(earnings.status).toBe(200);
    expect(earnings.body.totalEarnings).toBe(360);
    expect(earnings.body.entries[0].orderId).toBe(order);

    const invoice = await request(app).get(`/api/orders/${order}/invoice`).auth(token, { type: 'bearer' });
    expect(invoice.status).toBe(200);
    expect(invoice.text).toContain(after.invoiceNumber!);
    expect(invoice.text).toContain('Mkt item');
  });

  it('lets the buyer review a delivered item exactly once and updates aggregates', async () => {
    quoteHash = (await quote()).body.quote.quoteHash;
    const placed = await place();
    expect(placed.status).toBe(201);
    for (const st of ['CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELIVERED']) {
      await transitionOrder({ id: placed.body.order.id }, st as never, 'ok');
    }
    const lines = await prisma.orderItem.findMany({ where: { orderId: placed.body.order.id } });
    const orderItemId = lines[0].id;
    const forbidden = await request(app).post(`/api/reviews/product/${product}`).auth(sellerToken, { type: 'bearer' })
      .send({ orderItemId, rating: 5, body: 'nice' });
    expect(forbidden.status).toBe(403);

    const first = await request(app).post(`/api/reviews/product/${product}`).auth(token, { type: 'bearer' })
      .send({ orderItemId, rating: 4, body: 'very good pickle', title: 'tasty' });
    expect(first.status).toBe(201);

    const again = await request(app).post(`/api/reviews/product/${product}`).auth(token, { type: 'bearer' })
      .send({ orderItemId, rating: 1, body: 'second try' });
    expect(again.status).toBe(409);

    const list = await request(app).get(`/api/reviews/product/${product}`);
    expect(list.status).toBe(200);
    expect(list.body.summary.count).toBe(1);
    expect(list.body.summary.average).toBe(4);
    expect(list.body.reviews[0].body).toBe('very good pickle');

    const prod = await prisma.product.findUniqueOrThrow({ where: { id: product } });
    expect(prod.reviewCount).toBe(1);
    expect(prod.rating).toBe(4);
  });

  it('accepts a valid image upload and refuses non-image bytes', async () => {
    const good = await request(app).post('/api/media/upload').auth(sellerToken, { type: 'bearer' })
      .send({ filename: 'pickle jar.png', dataBase64: H });
    expect(good.status).toBe(201);
    expect(good.body.url).toMatch(/\/media\/.+\.png$/);

    const fake = Buffer.from('this is not an image at all, just plain text bytes repeated many times over to pass the minimum size rule......').toString('base64');
    const bad = await request(app).post('/api/media/upload').auth(sellerToken, { type: 'bearer' })
      .send({ filename: 'notes.txt', dataBase64: fake });
    expect(bad.status).toBe(415);

    const anon = await request(app).post('/api/media/upload').send({ filename: 'x.png', dataBase64: H });
    expect(anon.status).toBe(401);
  });

  it('cancels and restores stock', async () => {
    quoteHash = (await quote()).body.quote.quoteHash;
    const placed = await place();
    expect(placed.status).toBe(201);
    const before = (await prisma.product.findUniqueOrThrow({ where: { id: product } })).stockQuantity;
    expect(before).toBe(8);
    const cancel = await request(app).post(`/api/orders/${placed.body.order.id}/cancel`).auth(token, { type: 'bearer' });
    expect(cancel.status).toBe(200);
    expect(cancel.body.order.status).toBe('CANCELLED');
    expect(cancel.body.order.paymentStatus).toBe('CANCELLED');
    const after = (await prisma.product.findUniqueOrThrow({ where: { id: product } })).stockQuantity;
    expect(after).toBe(10);
  });
});
