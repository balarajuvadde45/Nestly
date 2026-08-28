import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { hashPassword, signToken, verifyPassword } from '../lib/auth';
import { serializeUser } from '../lib/serializers';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import { Role } from '@prisma/client';
import { env } from '../lib/env';
import {
  generateOtp,
  normalizePhone,
  saveOtp,
  verifyOtp,
  peekDevOtp,
} from '../lib/otp';

export const authRouter = Router();

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  phone: z.string().min(10),
  password: z.string().min(6),
  role: z.enum(['CUSTOMER', 'SELLER']).optional(),
});

const loginSchema = z.object({
  email: z.string().email().optional(),
  phone: z.string().optional(),
  password: z.string().min(1),
});

const sendOtpSchema = z.object({
  phone: z.string().min(10),
});

const verifyOtpSchema = z.object({
  phone: z.string().min(10),
  otp: z.string().length(6),
  name: z.string().min(2).optional(),
});

const googleSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  googleId: z.string().min(3),
  avatarUrl: z.string().url().optional().or(z.literal('')).optional(),
  idToken: z.string().optional(),
});

function issueToken(user: { id: string; role: Role; email: string }) {
  return signToken({
    sub: user.id,
    role: user.role,
    email: user.email,
  });
}

function hashCode(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  }
  return h;
}

authRouter.post('/register', async (req, res, next) => {
  try {
    const body = registerSchema.parse(req.body);
    const phone = normalizePhone(body.phone);
    const email = body.email.toLowerCase().trim();

    const existing = await prisma.user.findFirst({
      where: {
        OR: [
          { email },
          { phone: { contains: phone } },
        ],
      },
    });
    if (existing) {
      res.status(409).json({ error: 'Email or phone already registered' });
      return;
    }

    const role = (body.role as Role) || Role.CUSTOMER;
    const user = await prisma.user.create({
      data: {
        name: body.name.trim(),
        email,
        phone: `+91 ${phone}`,
        passwordHash: await hashPassword(body.password),
        role,
        authProvider: 'email',
      },
      include: { addresses: true },
    });
    const token = issueToken(user);
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
        ? { email: body.email.toLowerCase().trim() }
        : { phone: { contains: normalizePhone(body.phone!) } },
      include: { addresses: true },
    });
    if (!user || !(await verifyPassword(body.password, user.passwordHash))) {
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }
    const token = issueToken(user);
    res.json({ token, user: serializeUser(user, user.addresses) });
  } catch (e) {
    next(e);
  }
});

/** Request phone OTP (SMS in production; logged in dev). */
authRouter.post('/send-otp', async (req, res, next) => {
  try {
    const body = sendOtpSchema.parse(req.body);
    const phone = normalizePhone(body.phone);
    if (phone.length !== 10) {
      res.status(400).json({ error: 'Enter a valid 10-digit mobile number' });
      return;
    }
    const code = generateOtp();
    saveOtp(phone, code);

    // Production: send via SMS provider. Dev: log + return for testing.
    console.log(`[Nestly OTP] +91 ${phone} → ${code}`);

    const payload: Record<string, unknown> = {
      ok: true,
      message: 'OTP sent to your mobile number',
      expiresInSec: 300,
      phone: `+91 ${phone}`,
    };
    if (env.isDev) {
      payload.devOtp = code;
      payload.hint = 'Use this OTP or master OTP 123456 in development';
    }
    res.json(payload);
  } catch (e) {
    next(e);
  }
});

/** Verify phone OTP and login / auto-register. */
authRouter.post('/verify-otp', async (req, res, next) => {
  try {
    const body = verifyOtpSchema.parse(req.body);
    const phone = normalizePhone(body.phone);
    const check = verifyOtp(phone, body.otp, { allowMaster: env.isDev });
    if (!check.ok) {
      res.status(401).json({ error: check.error });
      return;
    }

    let user = await prisma.user.findFirst({
      where: { phone: { contains: phone } },
      include: { addresses: true },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          name: body.name?.trim() || 'Nestly User',
          email: `user${phone}@nestly.local`,
          phone: `+91 ${phone}`,
          passwordHash: await hashPassword(`otp-${phone}-${Date.now()}`),
          role: Role.CUSTOMER,
          authProvider: 'phone',
        },
        include: { addresses: true },
      });
    } else if (body.name && user.name === 'Nestly User') {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { name: body.name.trim() },
        include: { addresses: true },
      });
    }

    const token = issueToken(user);
    res.json({ token, user: serializeUser(user, user.addresses) });
  } catch (e) {
    next(e);
  }
});

/** Legacy phone-otp endpoint (compat). */
authRouter.post('/phone-otp', async (req, res, next) => {
  try {
    const body = verifyOtpSchema.parse(req.body);
    // ensure OTP can verify via master or stored
    const check = verifyOtp(body.phone, body.otp, { allowMaster: env.isDev });
    if (!check.ok) {
      res.status(401).json({ error: check.error });
      return;
    }
    req.body = body;
    // re-use verify path by calling same logic inline
    const phone = normalizePhone(body.phone);
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
          authProvider: 'phone',
        },
        include: { addresses: true },
      });
    }
    const token = issueToken(user);
    res.json({ token, user: serializeUser(user, user.addresses) });
  } catch (e) {
    next(e);
  }
});

/**
 * Continue with Google — disabled for soft launch until OAuth client IDs exist.
 */
authRouter.post('/google', async (req, res, next) => {
  try {
    if (!process.env.GOOGLE_CLIENT_ID) {
      res.status(403).json({
        error: 'Google sign-in is not enabled yet. Use email or phone OTP.',
      });
      return;
    }
    const body = googleSchema.parse(req.body);
    const email = body.email.toLowerCase().trim();
    const googleId = body.googleId.trim();

    // Optional: verify Google idToken when client ID is configured
    if (process.env.GOOGLE_CLIENT_ID && body.idToken) {
      // Structure ready for google-auth-library verifyIdToken
      // without requiring the package until keys are added.
    }

    let user = await prisma.user.findFirst({
      where: {
        OR: [{ googleId }, { email }],
      },
      include: { addresses: true },
    });

    if (user) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          googleId: user.googleId || googleId,
          authProvider: user.authProvider === 'email' ? 'google' : user.authProvider,
          avatarUrl: body.avatarUrl || user.avatarUrl,
          name: user.name || body.name,
        },
        include: { addresses: true },
      });
    } else {
      // Unique placeholder phone (user can update later in profile)
      const phoneSeed = String(
        9000000000 + (Math.abs(hashCode(googleId)) % 999999999),
      );
      user = await prisma.user.create({
        data: {
          name: body.name.trim(),
          email,
          phone: `+91 ${phoneSeed}`,
          passwordHash: await hashPassword(`google-${googleId}`),
          role: Role.CUSTOMER,
          googleId,
          authProvider: 'google',
          avatarUrl: body.avatarUrl || null,
        },
        include: { addresses: true },
      });
    }

    const token = issueToken(user);
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

/** Dev helper — never enable in production responses without auth. */
authRouter.get('/dev-otp/:phone', async (req, res) => {
  if (!env.isDev) {
    res.status(404).json({ error: 'Not found' });
    return;
  }
  const code = peekDevOtp(req.params.phone);
  res.json({ otp: code });
});
