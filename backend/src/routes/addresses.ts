import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { serializeAddress } from '../lib/serializers';
import { AuthedRequest, requireAuth } from '../middleware/auth';

export const addressesRouter = Router();

addressesRouter.use(requireAuth);

addressesRouter.get('/', async (req: AuthedRequest, res, next) => {
  try {
    const addresses = await prisma.address.findMany({
      where: { userId: req.user!.sub },
      orderBy: { isDefault: 'desc' },
    });
    res.json({ addresses: addresses.map(serializeAddress) });
  } catch (e) {
    next(e);
  }
});

addressesRouter.post('/', async (req: AuthedRequest, res, next) => {
  try {
    const schema = z.object({
      label: z.string().min(1),
      fullAddress: z.string().min(3),
      area: z.string().min(2),
      city: z.string().min(2),
      pincode: z.string().regex(/^[1-9][0-9]{5}$/),
      landmark: z.string().optional(),
      lat: z.number().min(-90).max(90).optional(),
      lng: z.number().min(-180).max(180).optional(),
      isDefault: z.boolean().optional(),
    });
    const body = schema.parse(req.body);
    if (body.isDefault) {
      await prisma.address.updateMany({
        where: { userId: req.user!.sub },
        data: { isDefault: false },
      });
    }
    const address = await prisma.address.create({
      data: {
        userId: req.user!.sub,
        ...body,
        lat: body.lat,
        lng: body.lng,
      },
    });
    res.status(201).json({ address: serializeAddress(address) });
  } catch (e) {
    next(e);
  }
});

const addressUpdateSchema = z.object({
  label: z.string().min(1).optional(),
  fullAddress: z.string().min(3).optional(),
  area: z.string().min(2).optional(),
  city: z.string().min(2).optional(),
  pincode: z.string().regex(/^[1-9][0-9]{5}$/).optional(),
  landmark: z.string().optional(),
  lat: z.number().min(-90).max(90).optional(),
  lng: z.number().min(-180).max(180).optional(),
  isDefault: z.boolean().optional(),
});

addressesRouter.patch('/:id', async (req: AuthedRequest, res, next) => {
  try {
    const id = String(req.params.id);
    const body = addressUpdateSchema.parse(req.body);
    const existing = await prisma.address.findFirst({
      where: { id, userId: req.user!.sub },
    });
    if (!existing) {
      res.status(404).json({ error: 'Address not found' });
      return;
    }
    if (body.isDefault) {
      await prisma.address.updateMany({
        where: { userId: req.user!.sub },
        data: { isDefault: false },
      });
    }
    const address = await prisma.address.update({
      where: { id },
      data: body,
    });
    res.json({ address: serializeAddress(address) });
  } catch (e) {
    next(e);
  }
});

addressesRouter.delete('/:id', async (req: AuthedRequest, res, next) => {
  try {
    const id = String(req.params.id);
    const existing = await prisma.address.findFirst({
      where: { id, userId: req.user!.sub },
    });
    if (!existing) {
      res.status(404).json({ error: 'Address not found' });
      return;
    }
    const used = await prisma.order.count({ where: { addressId: id } });
    if (used) { res.status(409).json({ error: 'This address is linked to an order and must be retained.' }); return; }
    await prisma.address.delete({ where: { id } });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});
