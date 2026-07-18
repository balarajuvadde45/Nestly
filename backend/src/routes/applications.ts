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
    message: a.message,
    status: a.status,
    adminNotes: a.adminNotes,
    reviewedAt: a.reviewedAt?.toISOString() ?? null,
    reviewedBy: a.reviewedBy,
    createdAt: a.createdAt.toISOString(),
    updatedAt: a.updatedAt.toISOString(),
  };
}

/** Public: anyone can submit "Sell from Home" application */
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
        message: body.message?.trim() || null,
        status: ApplicationStatus.PENDING,
      },
    });

    console.log(
      `[Nestly] New seller application: ${app.businessName} (${app.phone}) id=${app.id}`,
    );

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
      const status = req.query.status as string | undefined;
      const apps = await prisma.sellerApplication.findMany({
        where: status
          ? { status: status as ApplicationStatus }
          : undefined,
        orderBy: { createdAt: 'desc' },
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

      const app = await prisma.sellerApplication.update({
        where: { id },
        data: {
          status: body.status as ApplicationStatus,
          adminNotes: body.adminNotes ?? existing.adminNotes,
          reviewedAt: new Date(),
          reviewedBy: req.user!.email,
        },
      });

      res.json({ application: serializeApp(app) });
    } catch (e) {
      next(e);
    }
  },
);
