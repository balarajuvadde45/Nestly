import { OrderStatus, Prisma } from '@prisma/client';
import { env } from './env';
import { prisma } from './prisma';
import { queueNotification, type NotificationTemplate } from './notify';

export const orderInclude = {
  items: true, events: { orderBy: { createdAt: 'asc' as const } }, vendor: true, address: true,
};
const transitions: Record<OrderStatus, OrderStatus[]> = {
  PLACED: ['CONFIRMED', 'CANCELLED'],
  CONFIRMED: ['PREPARING', 'CANCELLED'],
  PREPARING: ['OUT_FOR_DELIVERY', 'CANCELLED'],
  OUT_FOR_DELIVERY: ['DELIVERED'],
  DELIVERED: [], CANCELLED: [],
};
export function canTransition(from: OrderStatus, to: OrderStatus): boolean {
  return transitions[from].includes(to);
}

const TEMPLATE_BY_STATUS: Partial<Record<OrderStatus, NotificationTemplate>> = {
  PLACED: 'ORDER_PLACED',
  CONFIRMED: 'ORDER_CONFIRMED',
  PREPARING: 'ORDER_PREPARING',
  OUT_FOR_DELIVERY: 'ORDER_OUT_FOR_DELIVERY',
  DELIVERED: 'ORDER_DELIVERED',
  CANCELLED: 'ORDER_CANCELLED',
};

/** Platform commission when the seller has no negotiated rate (percent of item total). */
export function commissionRateFor(vendorCommissionRate: number): number {
  return vendorCommissionRate > 0 ? vendorCommissionRate : env.platformCommissionRate;
}

export async function transitionOrder(
  where: Prisma.OrderWhereInput, status: OrderStatus, message: string, customer = false,
) {
  const settled = await prisma.$transaction(async tx => {
    const order = await tx.order.findFirst({ where, include: { items: true, vendor: true } });
    if (!order) throw Object.assign(new Error('Order not found'), { status: 404 });
    if (!canTransition(order.status, status) || (customer && order.status !== 'PLACED')) {
      throw Object.assign(new Error('Order status has changed or this action is unavailable'), { status: 409 });
    }

    // Delivery implies cash collected for COD orders. Paid online orders are
    // already PAID via the webhook; unpaid online orders cannot be delivered.
    let paymentStatus: string | undefined;
    if (status === 'CANCELLED') {
      paymentStatus = order.paymentStatus === 'PAID' ? 'REFUND_DUE' : 'CANCELLED';
    } else if (status === 'DELIVERED') {
      if (order.paymentMethod !== 'COD' && order.paymentStatus !== 'PAID') {
        throw Object.assign(new Error('Payment is not complete for this order'), { status: 409 });
      }
      paymentStatus = 'PAID';
    }

    const result = await tx.order.updateMany({
      where: { id: order.id, status: order.status },
      data: { status, ...(paymentStatus ? { paymentStatus } : {}) },
    });
    if (result.count !== 1) throw Object.assign(new Error('Order changed. Refresh and try again.'), { status: 409 });

    if (status === 'CANCELLED') {
      for (const item of order.items) {
        await tx.product.updateMany({
          where: { id: item.productId, stockQuantity: { not: null } },
          data: { stockQuantity: { increment: item.quantity } },
        });
      }
    }

    if (status === 'DELIVERED') {
      // Seller settlement ledger: seller keeps the item total minus commission.
      const rate = commissionRateFor(order.vendor.commissionRate);
      const commission = Math.round(order.itemTotal * rate) / 100;
      const earning = Math.round((order.itemTotal - commission) * 100) / 100;
      if (earning > 0) {
        await tx.sellerLedgerEntry.create({
          data: {
            vendorId: order.vendorId, orderId: order.id, type: 'ORDER_EARNING',
            amount: earning,
            note: `Order ${order.id.slice(0, 8)} (commission ${rate}%: Rs ${commission.toFixed(2)})`,
          },
        });
      }
      // Human-readable invoice number, assigned exactly once.
      if (!order.invoiceNumber) {
        const counter = await tx.counter.upsert({
          where: { id: 'invoice' }, create: { id: 'invoice', value: 1 }, update: { value: { increment: 1 } },
        });
        await tx.order.update({
          where: { id: order.id },
          data: { invoiceNumber: `NL-${new Date().getFullYear()}-${String(counter.value).padStart(6, '0')}` },
        });
      }
    }

    await tx.orderEvent.create({ data: { orderId: order.id, status, message } });
    await queueNotification(tx, {
      userId: order.customerId, orderId: order.id, template: TEMPLATE_BY_STATUS[status] ?? 'ORDER_PLACED',
    });
    return tx.order.findUniqueOrThrow({ where: { id: order.id }, include: orderInclude });
  });

  // A paid online order cancelled afterwards owes the customer a refund.
  // The provider call runs outside the transaction; the ledger row marks the debt.
  if (settled.status === 'CANCELLED' && settled.paymentStatus === 'REFUND_DUE' && settled.refundAmount == null) {
    await prisma.order.update({
      where: { id: settled.id },
      data: { refundAmount: settled.grandTotal },
    });
  }
  return settled;
}

/**
 * Online orders left unpaid for 30 minutes are cancelled and their reserved
 * stock restored. Called opportunistically on order listings; a dedicated
 * worker queue can take this over later.
 */
export async function expireStaleOnlineOrders(): Promise<number> {
  const stale = await prisma.order.findMany({
    where: {
      status: 'PLACED', paymentStatus: 'PENDING', paymentMethod: { not: 'COD' },
      placedAt: { lt: new Date(Date.now() - 30 * 60 * 1000) },
    },
    include: { items: true },
    take: 50,
  });
  let count = 0;
  for (const order of stale) {
    try {
      await prisma.$transaction(async tx => {
        const result = await tx.order.updateMany({
          where: { id: order.id, status: 'PLACED', paymentStatus: 'PENDING' },
          data: { status: 'CANCELLED', paymentStatus: 'CANCELLED' },
        });
        if (result.count !== 1) return;
        for (const item of order.items) {
          await tx.product.updateMany({
            where: { id: item.productId, stockQuantity: { not: null } },
            data: { stockQuantity: { increment: item.quantity } },
          });
        }
        await tx.orderEvent.create({ data: { orderId: order.id, status: 'CANCELLED', message: 'Cancelled: online payment was not completed within 30 minutes' } });
        await queueNotification(tx, { userId: order.customerId, orderId: order.id, template: 'ORDER_CANCELLED' });
        count += 1;
      });
    } catch { /* retried on the next sweep */ }
  }
  return count;
}
