import { randomUUID } from 'crypto';
import { Router } from 'express';
import { z } from 'zod';
import { ApplicationStatus, Role, VendorType } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { signToken } from '../lib/auth';
import { serializeUser, serializeVendor } from '../lib/serializers';
import { AuthedRequest, requireAuth } from '../middleware/auth';
import {
  defaultFulfillmentModes,
  fulfillmentModeSchema,
  normalizeString,
  vendorTypeSchema,
} from '../lib/marketplace';

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
      businessType: vendorTypeSchema.default('HOME_BUSINESS'),
      area: z.string().min(2),
      city: z.string().default('Hyderabad'),
      phone: z.string().optional(),
      categories: z.array(z.string()).optional(),
      businessAddress: z.string().optional(),
      pincode: z.string().optional(),
      premisesType: z.string().default('BUSINESS_PLACE'),
      gstin: z.string().optional(),
      pan: z.string().optional(),
      fssaiLicense: z.string().optional(),
      supportPhone: z.string().optional(),
      supportEmail: z.string().email().optional(),
      fulfillmentModes: z.array(fulfillmentModeSchema).optional(),
      gstInvoiceAvailable: z.boolean().default(false),
      acceptsWholesale: z.boolean().default(false),
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
      body.tagline?.trim() || 'Local business on Nestly';
    const description =
      body.description?.trim() ||
      `${body.businessName} is a local business on Nestly.`;

    const vendorId = randomUUID();
    const [vendor] = await prisma.$transaction([
      prisma.vendor.create({
        data: {
          id: vendorId,
          ownerId: userId,
          name: body.businessName.trim(),
          tagline,
          description,
          type: vendorType,
          area: body.area.trim(),
          city: body.city.trim(),
          businessAddress: normalizeString(body.businessAddress),
          pincode: normalizeString(body.pincode),
          premisesType: body.premisesType,
          supportPhone: normalizeString(body.supportPhone ?? body.phone),
          supportEmail: normalizeString(body.supportEmail ?? user.email),
          gstin: normalizeString(body.gstin),
          pan: normalizeString(body.pan),
          fssaiLicense: normalizeString(body.fssaiLicense),
          fulfillmentModesJson: JSON.stringify(
            body.fulfillmentModes?.length
              ? body.fulfillmentModes
              : defaultFulfillmentModes(body.businessType),
          ),
          gstInvoiceAvailable: body.gstInvoiceAvailable,
          acceptsWholesale: body.acceptsWholesale,
          imageUrl: '',
          coverUrl: '',
          categoriesJson: JSON.stringify(body.categories ?? []),
          tagsJson: JSON.stringify([]),
          isApproved: false,
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

        },
      }),
      prisma.sellerApplication.create({
        data: {
          vendorId,
          applicantName: user.name,
          businessName: body.businessName.trim(),
          phone: body.phone?.trim() || user.phone,
          email: user.email,
          city: body.city.trim(),
          area: body.area.trim(),
          businessType: body.businessType,
          premisesType: body.premisesType,
          businessAddress: normalizeString(body.businessAddress),
          pincode: normalizeString(body.pincode),
          gstin: normalizeString(body.gstin),
          pan: normalizeString(body.pan),
          fssaiLicense: normalizeString(body.fssaiLicense),
          categoriesJson: JSON.stringify(body.categories ?? []),
          acceptsWholesale: body.acceptsWholesale,
          message: 'Opened from buyer account (self-serve business setup)',
          status: ApplicationStatus.PENDING,
          adminNotes: null,
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
        'Business account created. Add your products while your seller application is reviewed.',
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
