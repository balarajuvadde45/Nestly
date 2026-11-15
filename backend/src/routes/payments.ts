import { Router } from 'express';
import { prisma } from '../lib/prisma';
import { verifyWebhookSignature } from '../lib/payments';
import { getIo } from '../socket';
import { serializeOrder } from '../lib/serializers';
import { queueNotification } from '../lib/notify';
import { logger } from '../lib/logger';

export const paymentsRouter = Router();

/**
 * Razorpay webhook. The raw body is required for signature verification, so
 * this router is mounted with express.raw() before the JSON body parser in
 * app.ts. Reference id on every link we create is the Tamarin order id.
 *
 * Processing happens BEFORE the 200 response: if we crash mid-processing,
 * Razorpay sees the failure and retries. Only well-formed, signature-valid
 * events get a 200; processing errors return 500 so no payment is lost.
 */
paymentsRouter.post('/webhook', async (req, res) => {
  const raw = req.body as Buffer;
  const signature = req.header('x-razorpay-signature');
  if (!Buffer.isBuffer(raw) || !verifyWebhookSignature(raw, signature)) {
    res.status(401).json({ error: 'Invalid signature' });
    return;
  }

  let event: {
    event: string;
    payload?: {
      payment_link?: { entity?: { id?: string; reference_id?: string; status?: string; amount?: number } };
      payment?: { entity?: { id?: string; status?: string; amount?: number } };
    };
  };
  try {
    event = JSON.parse(raw.toString('utf8'));
  } catch {
    logger.warn('Razorpay webhook: malformed JSON after valid signature');
    res.json({ ok: true });
    return;
  }

  try {
    const link = event.payload?.payment_link?.entity;
    const payment = event.payload?.payment?.entity;
    const orderId = link?.reference_id;
    if (!orderId || !link?.id) {
      res.json({ ok: true });
      return;
    }
    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order) {
      logger.warn({ orderId }, 'Razorpay webhook for unknown order');
      res.json({ ok: true });
      return;
    }

    if (event.event === 'payment_link.paid' && payment?.id) {
      // Money captured on a link that is no longer the order's bound link
      // (duplicated /pay race or a superseded link): the money must go back.
      if (order.paymentLinkId !== link.id) {
        await prisma.order.updateMany({
          where: { id: order.id, paymentStatus: { in: ['PENDING', 'FAILED'] } },
          data: {
            paymentStatus: 'REFUND_DUE', paymentProvider: 'razorpay',
            paymentProviderRef: payment.id, refundAmount: order.grandTotal,
          },
        });
        logger.warn({ orderId, linkId: link.id }, 'Payment captured on superseded link — marked for refund');
        res.json({ ok: true, refunded: 'superseded_link' });
        return;
      }

      // Guard against a mis-created link paying the wrong amount.
      const expectedPaise = Math.round(order.grandTotal * 100);
      if (typeof payment.amount === 'number' && payment.amount !== expectedPaise) {
        await prisma.order.updateMany({
          where: { id: order.id, paymentStatus: { in: ['PENDING', 'FAILED'] } },
          data: {
            paymentStatus: 'REFUND_DUE', paymentProvider: 'razorpay',
            paymentProviderRef: payment.id, refundAmount: order.grandTotal,
          },
        });
        logger.error({ orderId, expected: expectedPaise, got: payment.amount }, 'Webhook amount mismatch — marked for refund');
        res.json({ ok: true, refunded: 'amount_mismatch' });
        return;
      }

      const paidOrder = await prisma.order.updateMany({
        where: { id: order.id, paymentStatus: { in: ['PENDING', 'FAILED'] } },
        data: {
          paymentStatus: 'PAID', paidAt: new Date(),
          paymentProvider: 'razorpay', paymentProviderRef: payment.id,
        },
      });
      if (paidOrder.count === 1) {
        await queueNotification(prisma, { userId: order.customerId, orderId: order.id, template: 'PAYMENT_RECEIVED' });
        const payload = serializeOrder(
          await prisma.order.findUniqueOrThrow({ where: { id: order.id }, include: { items: true, events: true, vendor: true, address: true } }),
        );
        getIo()?.to('user:' + order.customerId).emit('order:updated', payload);
        if (order.vendorId) {
          const vendor = await prisma.vendor.findUnique({ where: { id: order.vendorId }, select: { ownerId: true } });
          if (vendor?.ownerId) getIo()?.to('user:' + vendor.ownerId).emit('order:updated', payload);
        }
      }
      res.json({ ok: true });
      return;
    }

    if (event.event === 'payment_link.payment.failed') {
      await prisma.order.updateMany({
        where: { id: order.id, paymentStatus: 'PENDING' },
        data: { paymentStatus: 'FAILED' },
      });
      res.json({ ok: true });
      return;
    }

    if (event.event === 'refund.processed') {
      // Refund executed from the dashboard or by a previous sweep run.
      await prisma.order.updateMany({
        where: { id: order.id, paymentStatus: 'REFUND_DUE' },
        data: { paymentStatus: 'REFUNDED' },
      });
    }
    res.json({ ok: true });
  } catch (err) {
    // Processing failed AFTER a valid signature: respond 500 so Razorpay
    // retries this event instead of silently dropping a payment.
    logger.error({ err, event: event.event }, 'Razorpay webhook processing failed');
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});
