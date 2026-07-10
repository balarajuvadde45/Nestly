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
      pincode: z.string().min(4),
      landmark: z.string().optional(),
      lat: z.number().optional(),
      lng: z.number().optional(),
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
        lat: body.lat ?? 17.4486,
        lng: body.lng ?? 78.3908,
      },
    });
    res.status(201).json({ address: serializeAddress(address) });
  } catch (e) {
    next(e);
  }
});
