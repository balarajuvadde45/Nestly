import { Router } from 'express';
import { z } from 'zod';
import { ApplicationStatus, Role, VendorType } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { signToken } from '../lib/auth';
import { serializeUser, serializeVendor } from '../lib/serializers';
import { AuthedRequest, requireAuth } from '../middleware/auth';

/**
 * Buyer-side API (Nestly shop).
 * Business accounts are opened FROM a logged-in buyer account only.
 */
export const buyerRouter = Router();

buyerRouter.use(requireAuth);

/** Current buyer profile + whether they already own a business */
buyerRouter.get('/me', async (req: AuthedRequest, res, next) => {
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
      hasBusiness: user.vendor != null,
      business: user.vendor ? serializeVendor(user.vendor) : null,
      mode: 'buyer',
    });
  } catch (e) {
    next(e);
  }
});

/**
 * Open a business account using the current buyer identity.
 * Same user, separate Vendor (business) record + role becomes SELLER.
 * Admin also gets a SellerApplication row for tracking.
 */
buyerRouter.post('/open-business', async (req: AuthedRequest, res, next) => {
  try {
    const schema = z.object({
      businessName: z.string().min(2),
      tagline: z.string().min(2).optional(),
      description: z.string().min(10).optional(),
      businessType: z
        .enum(['HOME_COOK', 'CLOUD_KITCHEN', 'HOME_BUSINESS', 'BOUTIQUE'])
        .default('HOME_BUSINESS'),
      area: z.string().min(2),
      city: z.string().default('Hyderabad'),
      phone: z.string().optional(),
      categories: z.array(z.string()).optional(),
    });
    const body = schema.parse(req.body);
    const userId = req.user!.sub;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { vendor: true },
    });
    if (!user) {
      res.status(404).json({ error: 'Buyer account not found. Login first.' });
      return;
    }

    if (user.vendor) {
      // Re-issue SELLER token so old CUSTOMER JWTs stop getting Forbidden
      const role =
        user.role === Role.ADMIN ? Role.ADMIN : Role.SELLER;
      if (user.role === Role.CUSTOMER) {
        await prisma.user.update({
          where: { id: userId },
          data: { role: Role.SELLER },
        });
      }
      const token = signToken({
        sub: user.id,
        role: role === Role.ADMIN ? Role.ADMIN : Role.SELLER,
        email: user.email,
      });
      res.status(200).json({
        message: 'Business already exists. Use Seller Dashboard.',
        token,
        user: serializeUser(
          { ...user, role: role === Role.ADMIN ? Role.ADMIN : Role.SELLER },
          [],
        ),
        business: serializeVendor(user.vendor),
        mode: 'seller',
      });
      return;
    }

    const vendorType = body.businessType as VendorType;
    const tagline =
      body.tagline?.trim() || 'Proudly selling from home on Nestly';
    const description =
      body.description?.trim() ||
      `${body.businessName} is a home business on Nestly. Update your story in Seller Dashboard.`;

    const [vendor] = await prisma.$transaction([
      prisma.vendor.create({
        data: {
          ownerId: userId,
          name: body.businessName.trim(),
          tagline,
          description,
          type: vendorType,
          area: body.area.trim(),
          city: body.city.trim(),
          imageUrl:
            'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400',
          coverUrl:
            'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
          categoriesJson: JSON.stringify(body.categories ?? []),
          tagsJson: JSON.stringify(['Home business']),
          isApproved: true,
          isOpen: true,
          rating: 0,
          reviewCount: 0,
          orderCount: 0,
        },
      }),
      prisma.user.update({
        where: { id: userId },
        data: {
          role: Role.SELLER,
          ...(body.phone ? { phone: body.phone.trim() } : {}),
        },
      }),
      prisma.sellerApplication.create({
        data: {
          applicantName: user.name,
          businessName: body.businessName.trim(),
          phone: body.phone?.trim() || user.phone,
          email: user.email,
          city: body.city.trim(),
          area: body.area.trim(),
          businessType: body.businessType,
          message: 'Opened from buyer account (self-serve business setup)',
          status: ApplicationStatus.APPROVED,
          adminNotes: 'Auto-created when buyer opened a business account',
          reviewedAt: new Date(),
          reviewedBy: 'system',
        },
      }),
      prisma.activityLog.create({
        data: {
          userId,
          mode: 'SELLER',
          action: 'BUSINESS_OPENED',
          message: `Buyer ${user.email} opened business "${body.businessName.trim()}"`,
          metaJson: JSON.stringify({ businessType: body.businessType }),
        },
      }),
    ]);

    console.log(
      `[Nestly SELLER] Business opened by buyer ${user.email}: ${vendor.name}`,
    );

    const updated = await prisma.user.findUnique({
      where: { id: userId },
      include: { addresses: true },
    });

    // Critical: new JWT with SELLER role (old buyer token would get Forbidden)
    const token = signToken({
      sub: userId,
      role: Role.SELLER,
      email: user.email,
    });

    res.status(201).json({
      message:
        'Business account created and approved. Seller Dashboard is ready now.',
      token,
      user: updated ? serializeUser(updated, updated.addresses) : null,
      business: serializeVendor(vendor),
      mode: 'seller',
    });
  } catch (e) {
    next(e);
  }
});

/**
 * Re-issue JWT with SELLER role if user already has a business.
 * Fixes Forbidden after open-business without creating a new store.
 */
buyerRouter.post('/refresh-seller-session', async (req: AuthedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.sub },
      include: { addresses: true, vendor: true },
    });
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    if (!user.vendor && user.role !== Role.SELLER && user.role !== Role.ADMIN) {
      res.status(403).json({
        error: 'No business account yet. Create one under Sell first.',
      });
      return;
    }
    if (user.role === Role.CUSTOMER && user.vendor) {
      await prisma.user.update({
        where: { id: user.id },
        data: { role: Role.SELLER },
      });
    }
    const role =
      user.role === Role.ADMIN ? Role.ADMIN : Role.SELLER;
    const token = signToken({
      sub: user.id,
      role,
      email: user.email,
    });
    res.json({
      token,
      user: serializeUser(
        { ...user, role },
        user.addresses,
      ),
      business: user.vendor ? serializeVendor(user.vendor) : null,
      mode: 'seller',
    });
  } catch (e) {
    next(e);
  }
});

/** Buyer activity log (shopping side) */
buyerRouter.post('/log', async (req: AuthedRequest, res, next) => {
  try {
    const schema = z.object({
      action: z.string().min(2),
      message: z.string().optional(),
      meta: z.record(z.unknown()).optional(),
    });
    const body = schema.parse(req.body);
    await prisma.activityLog.create({
      data: {
        userId: req.user!.sub,
        mode: 'BUYER',
        action: body.action,
        message: body.message,
        metaJson: body.meta ? JSON.stringify(body.meta) : null,
      },
    });
    res.status(201).json({ ok: true });
  } catch (e) {
    next(e);
  }
});
