import { randomBytes } from 'crypto';
import { Router } from 'express';
import { z } from 'zod';
import rateLimit from 'express-rate-limit';
import { prisma } from '../lib/prisma';
import { hashPassword, signToken, verifyPassword } from '../lib/auth';
import { serializeUser } from '../lib/serializers';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import { Role } from '@prisma/client';
import { normalizePhone, sendOtp, verifyOtp } from '../lib/otp';
import { rateLimitStore } from '../lib/redis';
import { getIo } from '../socket';

export const authRouter = Router();
const phoneSchema = z.string().max(20).transform(normalizePhone);
const otpSchema = z.string().regex(/^\d{6}$/);
const phoneLimiter = rateLimit({
  windowMs: 60 * 60_000, limit: 5, standardHeaders: true, legacyHeaders: false,
  store: rateLimitStore('phone'),
  keyGenerator: req => normalizePhone(String(req.body.phone ?? '')),
  message: { error: 'Too many codes requested. Please try later.' },
  skip: () => process.env.NODE_ENV === 'test',
});

function issueToken(user: { id: string; role: Role; email: string }) {
  return signToken({ sub: user.id, role: user.role, email: user.email });
}

authRouter.post('/send-otp', (req, _res, next) => {
  try { phoneSchema.parse(req.body.phone); next(); } catch (e) { next(e); }
}, phoneLimiter, async (req, res, next) => {
  try {
    const phone = phoneSchema.parse(req.body.phone);
    await sendOtp(phone);
    res.json({ ok: true, message: 'Verification code sent', phone: '+91 ' + phone });
  } catch (e) { next(e); }
});

authRouter.post('/verify-otp', async (req, res, next) => {
  try {
    const body = z.object({
      phone: phoneSchema, otp: otpSchema, name: z.string().trim().min(2).max(100).optional(),
    }).parse(req.body);
    if (!await verifyOtp(body.phone, body.otp)) {
      res.status(401).json({ error: 'Invalid or expired code' }); return;
    }
    const phone = '+91 ' + body.phone;
    const user = await prisma.user.upsert({
      where: { phone },
      create: {
        name: body.name || 'Nestly User', email: 'user' + body.phone + '@nestly.local',
        phone, passwordHash: await hashPassword(randomBytes(32).toString('hex')),
        role: Role.CUSTOMER, authProvider: 'phone',
      },
      update: {},
      include: { addresses: true },
    });
    if (user.deletedAt) { res.status(401).json({ error: 'Account unavailable' }); return; }
    res.json({ token: issueToken(user), user: serializeUser(user, user.addresses) });
  } catch (e) { next(e); }
});

authRouter.post('/register', async (req, res, next) => {
  try {
    const body = z.object({
      name: z.string().trim().min(2).max(100), email: z.string().email().max(254),
      phone: phoneSchema, otp: otpSchema, password: z.string().min(12).max(72),
    }).parse(req.body);
    if (!await verifyOtp(body.phone, body.otp)) {
      res.status(401).json({ error: 'Invalid or expired code' }); return;
    }
    const user = await prisma.user.create({
      data: {
        name: body.name, email: body.email.toLowerCase().trim(), phone: '+91 ' + body.phone,
        passwordHash: await hashPassword(body.password), role: Role.CUSTOMER, authProvider: 'email',
      }, include: { addresses: true },
    });
    res.status(201).json({ token: issueToken(user), user: serializeUser(user, user.addresses) });
  } catch (e) { next(e); }
});

authRouter.post('/login', async (req, res, next) => {
  try {
    const body = z.object({
      email: z.string().email().max(254), password: z.string().min(1).max(72),
    }).parse(req.body);
    const user = await prisma.user.findUnique({
      where: { email: body.email.toLowerCase().trim() }, include: { addresses: true },
    });
    if (!user || user.deletedAt || user.authProvider !== 'email' ||
        !await verifyPassword(body.password, user.passwordHash)) {
      res.status(401).json({ error: 'Invalid email or password' }); return;
    }
    res.json({ token: issueToken(user), user: serializeUser(user, user.addresses) });
  } catch (e) { next(e); }
});

authRouter.get('/me', requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const user = await prisma.user.findUniqueOrThrow({
      where: { id: req.user!.sub }, include: { addresses: true, vendor: true, favorites: true },
    });
    res.json({
      user: {
        ...serializeUser(user, user.addresses),
        favoriteVendorIds: user.favorites.flatMap(f => f.vendorId ? [f.vendorId] : []),
        favoriteProductIds: user.favorites.flatMap(f => f.productId ? [f.productId] : []),
      }, vendorId: user.vendor?.id ?? null,
    });
  } catch (e) { next(e); }
});

authRouter.patch('/me', requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const body = z.object({ name: z.string().trim().min(2).max(100) }).strict().parse(req.body);
    const user = await prisma.user.update({
      where: { id: req.user!.sub }, data: body, include: { addresses: true },
    });
    res.json({ user: serializeUser(user, user.addresses) });
  } catch (e) { next(e); }
});

authRouter.post('/me/delete', requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const body = z.object({
      confirmation: z.literal('DELETE'), password: z.string().max(72).optional(), otp: otpSchema.optional(),
    }).parse(req.body);
    const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.sub } });
    const verified = user.authProvider === 'email' && body.password
      ? await verifyPassword(body.password, user.passwordHash)
      : body.otp ? await verifyOtp(user.phone, body.otp) : false;
    if (!verified) { res.status(401).json({ error: 'Confirm with your password or a fresh phone code' }); return; }
    await prisma.$transaction(async tx => {
      const active = await tx.order.count({ where: {
        OR: [{ customerId: user.id }, { vendor: { ownerId: user.id } }],
        status: { notIn: ['DELIVERED', 'CANCELLED'] },
      } });
      if (active) throw Object.assign(new Error('Complete or cancel active orders before deleting your account'), { status: 409 });
      await tx.favorite.deleteMany({ where: { userId: user.id } });
      await tx.activityLog.deleteMany({ where: { userId: user.id } });
      await tx.sellerApplication.deleteMany({ where: { OR: [{ email: user.email }, { phone: user.phone }] } });
      await tx.address.deleteMany({ where: { userId: user.id, orders: { none: {} } } });
      // Financial records stay linked to an anonymized account; retained addresses are not public.
      await tx.vendor.updateMany({ where: { ownerId: user.id }, data: {
        isApproved: false, isOpen: false, supportEmail: null, supportPhone: null,
        pan: null, bankAccountLast4: null, bankVerified: false,
      } });
      await tx.user.update({ where: { id: user.id }, data: {
        name: 'Deleted account', email: user.id + '@deleted.invalid', phone: 'deleted:' + user.id,
        avatarUrl: null, googleId: null, passwordHash: await hashPassword(randomBytes(32).toString('hex')),
        role: Role.CUSTOMER, deletedAt: new Date(),
      } });
    }, { isolationLevel: 'Serializable' });
    getIo()?.in('user:' + user.id).disconnectSockets(true);
    res.json({ ok: true });
  } catch (e) { next(e); }
});
