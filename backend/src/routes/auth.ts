import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { hashPassword, signToken, verifyPassword } from '../lib/auth';
import { serializeUser } from '../lib/serializers';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import { Role } from '@prisma/client';

export const authRouter = Router();

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  phone: z.string().min(10),
  password: z.string().min(4),
  role: z.enum(['CUSTOMER', 'SELLER']).optional(),
});

const loginSchema = z.object({
  email: z.string().email().optional(),
  phone: z.string().optional(),
  password: z.string().min(1),
});

const phoneOtpSchema = z.object({
  phone: z.string().min(10),
  otp: z.string().length(6),
  name: z.string().optional(),
});

authRouter.post('/register', async (req, res, next) => {
  try {
    const body = registerSchema.parse(req.body);
    const existing = await prisma.user.findFirst({
      where: { OR: [{ email: body.email }, { phone: body.phone }] },
    });
    if (existing) {
      res.status(409).json({ error: 'Email or phone already registered' });
      return;
    }
    const role = (body.role as Role) || Role.CUSTOMER;
    const user = await prisma.user.create({
      data: {
        name: body.name,
        email: body.email.toLowerCase(),
        phone: body.phone,
        passwordHash: await hashPassword(body.password),
        role,
      },
      include: { addresses: true },
    });
    const token = signToken({
      sub: user.id,
      role: user.role,
      email: user.email,
    });
    res.status(201).json({
      token,
      user: serializeUser(user, user.addresses),
    });
  } catch (e) {
    next(e);
  }
});

authRouter.post('/login', async (req, res, next) => {
  try {
    const body = loginSchema.parse(req.body);
    if (!body.email && !body.phone) {
      res.status(400).json({ error: 'Email or phone required' });
      return;
    }
    const user = await prisma.user.findFirst({
      where: body.email
        ? { email: body.email.toLowerCase() }
        : { phone: body.phone },
      include: { addresses: true },
    });
    if (!user || !(await verifyPassword(body.password, user.passwordHash))) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }
    const token = signToken({
      sub: user.id,
      role: user.role,
      email: user.email,
    });
    res.json({ token, user: serializeUser(user, user.addresses) });
  } catch (e) {
    next(e);
  }
});

/** Demo OTP login — accepts OTP 123456, auto-creates customer if needed */
authRouter.post('/phone-otp', async (req, res, next) => {
  try {
    const body = phoneOtpSchema.parse(req.body);
    if (body.otp !== '123456') {
      res.status(401).json({ error: 'Invalid OTP. Use 123456 in demo.' });
      return;
    }
    const phone = body.phone.replace(/\D/g, '').slice(-10);
    let user = await prisma.user.findFirst({
      where: { phone: { contains: phone } },
      include: { addresses: true },
    });
    if (!user) {
      user = await prisma.user.create({
        data: {
          name: body.name || 'Nestly User',
          email: `user${phone}@nestly.local`,
          phone: `+91 ${phone}`,
          passwordHash: await hashPassword('otp-login'),
          role: Role.CUSTOMER,
          addresses: {
            create: {
              label: 'Home',
              fullAddress: 'Demo address, please update',
              area: 'Madhapur',
              city: 'Hyderabad',
              pincode: '500081',
              lat: 17.4486,
              lng: 78.3908,
              isDefault: true,
            },
          },
        },
        include: { addresses: true },
      });
    }
    const token = signToken({
      sub: user.id,
      role: user.role,
      email: user.email,
    });
    res.json({ token, user: serializeUser(user, user.addresses) });
  } catch (e) {
    next(e);
  }
});

authRouter.get('/me', requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.sub },
      include: { addresses: true, vendor: true },
    });
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    res.json({
      user: serializeUser(user, user.addresses),
      vendorId: user.vendor?.id ?? null,
    });
  } catch (e) {
    next(e);
  }
});

authRouter.patch('/me', requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const schema = z.object({
      name: z.string().min(2).optional(),
      email: z.string().email().optional(),
      phone: z.string().min(10).optional(),
    });
    const body = schema.parse(req.body);
    const user = await prisma.user.update({
      where: { id: req.user!.sub },
      data: body,
      include: { addresses: true },
    });
    res.json({ user: serializeUser(user, user.addresses) });
  } catch (e) {
    next(e);
  }
});
