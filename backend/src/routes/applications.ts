import { Router } from 'express';
import { z } from 'zod';
import { ApplicationStatus, Role } from '@prisma/client';
import { prisma } from '../lib/prisma';
import {
  AuthedRequest,
  optionalAuth,
  requireAuth,
  requireRole,
} from '../middleware/auth';
import { normalizeString } from '../lib/marketplace';

export const applicationsRouter = Router();

function serializeApp(a: {
  id: string;
  applicantName: string;
  businessName: string;
  phone: string;
  email: string | null;
  city: string;
  area: string | null;
  businessType: string;
  premisesType: string | null;
  businessAddress: string | null;
  pincode: string | null;
  gstin: string | null;
  pan: string | null;
  fssaiLicense: string | null;
  categoriesJson: string;
  documentsJson: string;
  acceptsWholesale: boolean;
  message: string | null;
  status: ApplicationStatus;
  adminNotes: string | null;
  reviewedAt: Date | null;
  reviewedBy: string | null;
  createdAt: Date;
  updatedAt: Date;
}) {
  return {
    id: a.id,
    applicantName: a.applicantName,
    businessName: a.businessName,
    phone: a.phone,
    email: a.email,
    city: a.city,
    area: a.area,
    businessType: a.businessType,
    premisesType: a.premisesType,
    businessAddress: a.businessAddress,
    pincode: a.pincode,
    gstin: a.gstin,
    pan: a.pan,
    fssaiLicense: a.fssaiLicense,
    categories: (() => {
      try {
        const parsed = JSON.parse(a.categoriesJson);
        return Array.isArray(parsed) ? parsed.map(String) : [];
      } catch {
        return [];
      }
    })(),
    documents: (() => {
      try {
        const parsed = JSON.parse(a.documentsJson);
        return Array.isArray(parsed) ? parsed : [];
      } catch {
        return [];
      }
    })(),
    acceptsWholesale: a.acceptsWholesale,
    message: a.message,
    status: a.status,
    adminNotes: a.adminNotes,
    reviewedAt: a.reviewedAt?.toISOString() ?? null,
    reviewedBy: a.reviewedBy,
    createdAt: a.createdAt.toISOString(),
    updatedAt: a.updatedAt.toISOString(),
  };
}

/** Public: anyone can submit "seller" application */
applicationsRouter.post('/', optionalAuth, async (req, res, next) => {
  try {
    const schema = z.object({
      applicantName: z.string().min(2),
      businessName: z.string().min(2),
      phone: z.string().min(10),
      email: z.string().email().optional().or(z.literal('')),
      city: z.string().min(2),
      area: z.string().optional(),
      businessType: z.string().min(2),
      premisesType: z.string().optional(),
      businessAddress: z.string().optional(),
      pincode: z.string().optional(),
      gstin: z.string().optional(),
      pan: z.string().optional(),
      fssaiLicense: z.string().optional(),
      categories: z.array(z.string()).optional(),
      documents: z.array(z.record(z.unknown())).optional(),
      acceptsWholesale: z.boolean().default(false),
      message: z.string().optional(),
    });
    const body = schema.parse(req.body);

    const app = await prisma.sellerApplication.create({
      data: {
        applicantName: body.applicantName.trim(),
        businessName: body.businessName.trim(),
        phone: body.phone.trim(),
        email: body.email?.trim() || null,
        city: body.city.trim(),
        area: body.area?.trim() || null,
        businessType: body.businessType.trim(),
        premisesType: normalizeString(body.premisesType),
        businessAddress: normalizeString(body.businessAddress),
        pincode: normalizeString(body.pincode),
        gstin: normalizeString(body.gstin),
        pan: normalizeString(body.pan),
        fssaiLicense: normalizeString(body.fssaiLicense),
        categoriesJson: JSON.stringify(body.categories ?? []),
        documentsJson: JSON.stringify(body.documents ?? []),
        acceptsWholesale: body.acceptsWholesale,
        message: body.message?.trim() || null,
        status: ApplicationStatus.PENDING,
      },
    });


    res.status(201).json({
      application: serializeApp(app),
      message: 'Application saved. Admin can review it in Nestly Admin.',
    });
  } catch (e) {
    next(e);
  }
});

/** Admin: list all applications (newest first) */
applicationsRouter.get(
  '/',
  requireAuth,
  requireRole(Role.ADMIN),
  async (req: AuthedRequest, res, next) => {
    try {
      const status = z.nativeEnum(ApplicationStatus).optional().parse(req.query.status);
      const apps = await prisma.sellerApplication.findMany({
        where: status
          ? { status: status as ApplicationStatus }
          : undefined,
        orderBy: { createdAt: 'desc' },
        take: 100,
      });

      const pendingCount = await prisma.sellerApplication.count({
        where: { status: ApplicationStatus.PENDING },
      });

      res.json({
        applications: apps.map(serializeApp),
        pendingCount,
        total: apps.length,
      });
    } catch (e) {
      next(e);
    }
  },
);

/** Admin: pending count only (for badges) */
applicationsRouter.get(
  '/pending-count',
  requireAuth,
  requireRole(Role.ADMIN),
  async (_req, res, next) => {
    try {
      const pendingCount = await prisma.sellerApplication.count({
        where: { status: ApplicationStatus.PENDING },
      });
      res.json({ pendingCount });
    } catch (e) {
      next(e);
    }
  },
);

/** Admin: activity logs (buyer vs seller) */
applicationsRouter.get(
  '/activity/logs',
  requireAuth,
  requireRole(Role.ADMIN),
  async (req, res, next) => {
    try {
      const mode = req.query.mode as string | undefined;
      const logs = await prisma.activityLog.findMany({
        where: mode
          ? { mode: mode as 'BUYER' | 'SELLER' | 'ADMIN' }
          : undefined,
        orderBy: { createdAt: 'desc' },
        take: 100,
      });
      res.json({
        logs: logs.map((l) => ({
          id: l.id,
          userId: l.userId,
          mode: l.mode,
          action: l.action,
          message: l.message,
          meta: l.metaJson,
          createdAt: l.createdAt.toISOString(),
        })),
      });
    } catch (e) {
      next(e);
    }
  },
);

/** Admin: get one */
applicationsRouter.get(
  '/:id',
  requireAuth,
  requireRole(Role.ADMIN),
  async (req, res, next) => {
    try {
      const id = String(req.params.id);
      const app = await prisma.sellerApplication.findUnique({ where: { id } });
      if (!app) {
        res.status(404).json({ error: 'Application not found' });
        return;
      }
      res.json({ application: serializeApp(app) });
    } catch (e) {
      next(e);
    }
  },
);

/** Admin: update status (APPROVED / REJECTED / CONTACTED / PENDING) */
applicationsRouter.patch(
  '/:id/status',
  requireAuth,
  requireRole(Role.ADMIN),
  async (req: AuthedRequest, res, next) => {
    try {
      const id = String(req.params.id);
      const schema = z.object({
        status: z.enum(['PENDING', 'APPROVED', 'REJECTED', 'CONTACTED']),
        adminNotes: z.string().optional(),
      });
      const body = schema.parse(req.body);

      const existing = await prisma.sellerApplication.findUnique({
        where: { id },
      });
      if (!existing) {
        res.status(404).json({ error: 'Application not found' });
        return;
      }

      const app = await prisma.$transaction(async tx => {
        if (existing.vendorId) {
          const vendor = await tx.vendor.findUniqueOrThrow({ where: { id: existing.vendorId } });
          if (body.status === 'APPROVED' && (!vendor.businessAddress || !vendor.pincode || !vendor.imageUrl)) {
            throw Object.assign(new Error('Seller must complete address, pincode and store image before approval'), { status: 400 });
          }
          await tx.vendor.update({ where: { id: vendor.id }, data: {
            isApproved: body.status === 'APPROVED',
            kycStatus: body.status === 'APPROVED' ? 'VERIFIED' : body.status === 'REJECTED' ? 'REJECTED' : 'PENDING',
          } });
        } else if (body.status === 'APPROVED') {
          throw Object.assign(new Error('Ask this applicant to create a business from their account before approval'), { status: 400 });
        }
        return tx.sellerApplication.update({
          where: { id }, data: {
            status: body.status, adminNotes: body.adminNotes ?? existing.adminNotes,
            reviewedAt: new Date(), reviewedBy: req.user!.email,
          },
        });
      });

      res.json({ application: serializeApp(app) });
    } catch (e) {
      next(e);
    }
  },
);
