import { Router } from 'express';
import { prisma } from '../lib/prisma';
import { verifyWebhookSignature } from '../lib/payments';
import { getIo } from '../socket';
import { serializeOrder } from '../lib/serializers';
import { queueNotification } from '../lib/notify';

export const paymentsRouter = Router();

/**
 * Razorpay webhook. The raw body is required for signature verification, so
 * this router is mounted before the JSON body parser in app.ts.
 * Reference id on every link we create is the Nestly order id.
 */
paymentsRouter.post('/webhook', async (req, res) => {
  const raw = req.body as Buffer;
  const signature = req.header('x-razorpay-signature');
  if (!verifyWebhookSignature(raw, signature)) {
    res.status(401).json({ error: 'Invalid signature' });
    return;
  }
  res.json({ ok: true });
  try {
    const event = JSON.parse(raw.toString('utf8')) as {
      event: string;
      payload?: {
        payment_link?: { entity?: { id?: string; reference_id?: string; status?: string } };
        payment?: { entity?: { id?: string; status?: string } };
      };
    };
    const link = event.payload?.payment_link?.entity;
    const payment = event.payload?.payment?.entity;
    const orderId = link?.reference_id;
    if (!orderId) return;
    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order || order.paymentLinkId !== link?.id) return;

    if (event.event === 'payment_link.paid' && payment?.id) {
      const updated = await prisma.order.updateMany({
        where: { id: order.id, paymentStatus: { in: ['PENDING', 'FAILED'] } },
        data: {
          paymentStatus: 'PAID', paidAt: new Date(),
          paymentProvider: 'razorpay', paymentProviderRef: payment.id,
        },
      });
      if (updated.count === 1) {
        await queueNotification(prisma, { userId: order.customerId, orderId: order.id, template: 'PAYMENT_RECEIVED' });
        const payload = serializeOrder(await prisma.order.findUniqueOrThrow({ where: { id: order.id }, include: { items: true, events: true, vendor: true, address: true } }));
        getIo()?.to('user:' + order.customerId).emit('order:updated', payload);
        if (order.vendorId) {
          const vendor = await prisma.vendor.findUnique({ where: { id: order.vendorId }, select: { ownerId: true } });
          if (vendor?.ownerId) getIo()?.to('user:' + vendor.ownerId).emit('order:updated', payload);
        }
      }
    } else if (event.event === 'payment_link.payment.failed') {
      await prisma.order.updateMany({
        where: { id: order.id, paymentStatus: 'PENDING' },
        data: { paymentStatus: 'FAILED' },
      });
    }
  } catch { // malformed or unrelated payloads are logged upstream and dropped
  }
});
