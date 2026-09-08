import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../app';
import { normalizePhone, sendOtp } from '../lib/otp';
import { totals } from '../lib/pricing';
import { canTransition } from '../lib/order-lifecycle';

describe('release safeguards', () => {
  const app = createApp();
  it('requires authentication for checkout and tracking', async () => {
    expect((await request(app).post('/api/orders/quote').send({})).status).toBe(401);
    expect((await request(app).get('/api/orders/other-order/tracking')).status).toBe(401);
  });
  it('does not expose removed authentication or community endpoints', async () => {
    for (const path of ['/api/auth/google', '/api/auth/phone-otp', '/api/wisdom/posts']) {
      expect((await request(app).post(path).send({})).status).toBe(404);
    }
    expect((await request(app).get('/api/auth/dev-otp/9876543210')).status).toBe(404);
  });
  it('requires a phone proof before registering an email account', async () => {
    const res = await request(app).post('/api/auth/register').send({
      name: 'Test Customer', email: 'customer@test.invalid', phone: '9876543210',
      password: 'test-password-long', role: 'ADMIN',
    });
    expect(res.status).toBe(400);
  });
  it('fails closed when SMS delivery is not configured', async () => {
    await expect(sendOtp('9876543210')).rejects.toMatchObject({ status: 503 });
  });
  it('normalizes only valid Indian mobile numbers', () => {
    expect(normalizePhone('+91 98765-43210')).toBe('9876543210');
    for (const value of ['123', '+1 9876543210', 'hello9876543210', '0000000000']) {
      expect(() => normalizePhone(value)).toThrow();
    }
  });
  it('calculates mixed GST-inclusive prices in paise without charging GST twice', () => {
    const result = totals([
      { unitPrice: 118, quantity: 2, gstRate: 18 },
      { unitPrice: 105, quantity: 1, gstRate: 5 },
    ], false);
    expect(result).toEqual({ itemTotal: 341, tax: 41, deliveryFee: 0, platformFee: 5, discount: 0, grandTotal: 346 });
    expect(totals([{ unitPrice: 0.1, quantity: 3, gstRate: 0 }], true).itemTotal).toBe(0.3);
  });
  it('prevents status reversal and terminal order changes', () => {
    expect(canTransition('PLACED', 'CONFIRMED')).toBe(true);
    expect(canTransition('PLACED', 'DELIVERED')).toBe(false);
    expect(canTransition('DELIVERED', 'CANCELLED')).toBe(false);
    expect(canTransition('CANCELLED', 'CONFIRMED')).toBe(false);
  });
});
