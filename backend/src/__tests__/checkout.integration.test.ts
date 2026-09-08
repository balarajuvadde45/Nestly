import { randomUUID } from 'crypto';
import { beforeAll, beforeEach, afterAll, describe, it, expect } from 'vitest';
import request from 'supertest';
import { prisma } from '../lib/prisma';
import { createApp } from '../app';
import { signToken, hashPassword } from '../lib/auth';
import { transitionOrder } from '../lib/order-lifecycle';

describe.skipIf(!process.env.TEST_DATABASE_URL)('PostgreSQL checkout', () => {
  const app = createApp();
  const buyer = randomUUID(), owner = randomUUID(), outsider = randomUUID(), vendor = randomUUID(), product = randomUUID(), address = randomUUID();
  const token = signToken({ sub: buyer, role: 'CUSTOMER', email: buyer + '@test.invalid' });
  const sellerToken = signToken({ sub: owner, role: 'SELLER', email: owner + '@test.invalid' });
  const body = { vendorId: vendor, addressId: address, paymentMethod: 'COD', items: [{ productId: product, quantity: 1 }] };
  const quote = () => request(app).post('/api/orders/quote').auth(token, { type: 'bearer' }).send(body);
  const place = (quoteHash: string, idempotencyKey = randomUUID()) =>
    request(app).post('/api/orders').auth(token, { type: 'bearer' }).send({ ...body, quoteHash, idempotencyKey });

  beforeAll(async () => {
    const passwordHash = await hashPassword('integration-test-password');
    await prisma.user.createMany({ data: [buyer, owner, outsider].map(id => ({
      id, email: id + '@test.invalid', name: 'Integration account',
      phone: id, passwordHash, role: id === owner ? 'SELLER' : 'CUSTOMER',
    })) });
    await prisma.vendor.create({ data: {
      id: vendor, ownerId: owner, name: 'Integration seller', tagline: '', description: '',
      type: 'FMCG_DISTRIBUTOR', imageUrl: '', coverUrl: '', area: 'Test', city: 'Hyderabad',
      pincode: '500081', isApproved: true,
    } });
    await prisma.product.create({ data: {
      id: product, vendorId: vendor, name: 'Integration item', description: '', imageUrl: '',
      price: 118, gstRate: 18, stockQuantity: 5,
    } });
    await prisma.address.create({ data: {
      id: address, userId: buyer, label: 'Work', fullAddress: 'Original address',
      area: 'Test', city: 'Hyderabad', pincode: '500081',
    } });
  });
  beforeEach(async () => {
    await prisma.order.deleteMany({ where: { vendorId: vendor } });
    await prisma.product.update({ where: { id: product }, data: { price: 118, stockQuantity: 5, maxOrderQuantity: null } });
    await prisma.vendor.update({ where: { id: vendor }, data: { isApproved: true, isOpen: true } });
  });
  afterAll(async () => {
    await prisma.order.deleteMany({ where: { vendorId: vendor } });
    await prisma.vendor.deleteMany({ where: { id: vendor } });
    await prisma.user.deleteMany({ where: { id: { in: [buyer, owner, outsider] } } });
    await prisma.$disconnect();
  });
  it('places once on retry and snapshots the delivery address', async () => {
    const q = await quote();
    expect(q.status).toBe(200);
    const key = randomUUID();
    const first = await place(q.body.quote.quoteHash, key);
    expect(first.status).toBe(201);
    const retry = await place(q.body.quote.quoteHash, key);
    expect(retry.status).toBe(200);
    expect(retry.body.order.id).toBe(first.body.order.id);
    expect((await prisma.product.findUniqueOrThrow({ where: { id: product } })).stockQuantity).toBe(4);
    await prisma.address.update({ where: { id: address }, data: { fullAddress: 'Edited address' } });
    const fetched = await request(app).get('/api/orders/' + first.body.order.id).auth(token, { type: 'bearer' });
    expect(fetched.body.order.address.fullAddress).toBe('Original address');
  });
  it('rejects a stale price quote', async () => {
    const q = await quote();
    await prisma.product.update({ where: { id: product }, data: { price: 119 } });
    expect((await place(q.body.quote.quoteHash)).status).toBe(409);
    expect(await prisma.order.count({ where: { vendorId: vendor } })).toBe(0);
  });
  it('never oversells concurrent orders', async () => {
    await prisma.product.update({ where: { id: product }, data: { stockQuantity: 1 } });
    const q = await quote();
    const results = await Promise.all([place(q.body.quote.quoteHash), place(q.body.quote.quoteHash)]);
    expect(results.filter(r => r.status === 201)).toHaveLength(1);
    expect(results.every(r => [201, 400, 409].includes(r.status))).toBe(true);
    expect((await prisma.product.findUniqueOrThrow({ where: { id: product } })).stockQuantity).toBe(0);
  });
  it('restores stock exactly once on cancellation', async () => {
    const q = await quote();
    const created = await place(q.body.quote.quoteHash);
    const id = created.body.order.id;
    expect((await request(app).post('/api/orders/' + id + '/cancel').auth(token, { type: 'bearer' })).status).toBe(200);
    expect((await request(app).post('/api/orders/' + id + '/cancel').auth(token, { type: 'bearer' })).status).toBe(409);
    expect((await prisma.product.findUniqueOrThrow({ where: { id: product } })).stockQuantity).toBe(5);
  });
  it('does not allow a customer to cancel after confirmation', async () => {
    const q = await quote();
    const created = await place(q.body.quote.quoteHash);
    await transitionOrder({ id: created.body.order.id, vendorId: vendor }, 'CONFIRMED', 'Confirmed');
    expect((await request(app).post('/api/orders/' + created.body.order.id + '/cancel').auth(token, { type: 'bearer' })).status).toBe(409);
  });
  it('hides unapproved products and prevents orders from closed sellers', async () => {
    await prisma.vendor.update({ where: { id: vendor }, data: { isApproved: false } });
    expect((await request(app).get('/api/catalog/products/' + product)).status).toBe(404);
    expect((await quote()).status).toBe(400);
  });
  it('enforces aggregate maximum quantities across duplicate lines', async () => {
    await prisma.product.update({ where: { id: product }, data: { maxOrderQuantity: 1 } });
    const res = await request(app).post('/api/orders/quote').auth(token, { type: 'bearer' }).send({ ...body, items: [...body.items, ...body.items] });
    expect(res.status).toBe(400);
  });
  it('does not reveal tracking data to another authenticated customer', async () => {
    const q = await quote();
    const created = await place(q.body.quote.quoteHash);
    const otherToken = signToken({ sub: outsider, role: 'CUSTOMER', email: outsider + '@test.invalid' });
    const res = await request(app).get('/api/orders/' + created.body.order.id + '/tracking').auth(otherToken, { type: 'bearer' });
    expect(res.status).toBe(404);
  });
  it('deletes a verified account and immediately rejects its old token', async () => {
    const otherToken = signToken({ sub: outsider, role: 'CUSTOMER', email: outsider + '@test.invalid' });
    const res = await request(app).post('/api/auth/me/delete').auth(otherToken, { type: 'bearer' })
      .send({ confirmation: 'DELETE', password: 'integration-test-password' });
    expect(res.status).toBe(200);
    expect((await request(app).get('/api/auth/me').auth(otherToken, { type: 'bearer' })).status).toBe(401);
    const deleted = await prisma.user.findUniqueOrThrow({ where: { id: outsider } });
    expect(deleted.deletedAt).not.toBeNull();
    expect(deleted.email).toBe(outsider + '@deleted.invalid');
  });
  it('requires renewed credentials for account deletion', async () => {
    const res = await request(app).post('/api/auth/me/delete').auth(sellerToken, { type: 'bearer' }).send({ confirmation: 'DELETE', password: 'wrong' });
    expect(res.status).toBe(401);
  });
});
