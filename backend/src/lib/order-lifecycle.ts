import { OrderStatus, Prisma } from '@prisma/client';
import { prisma } from './prisma';

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
export async function transitionOrder(
  where: Prisma.OrderWhereInput, status: OrderStatus, message: string, customer = false,
) {
  return prisma.$transaction(async tx => {
    const order = await tx.order.findFirst({ where, include: { items: true } });
    if (!order) throw Object.assign(new Error('Order not found'), { status: 404 });
    if (!canTransition(order.status, status) || (customer && order.status !== 'PLACED')) {
      throw Object.assign(new Error('Order status has changed or this action is unavailable'), { status: 409 });
    }
    const result = await tx.order.updateMany({
      where: { id: order.id, status: order.status },
      data: { status, ...(status === 'CANCELLED' ? { paymentStatus: 'CANCELLED' } : status === 'DELIVERED' ? { paymentStatus: 'PAID' } : {}) },
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
    await tx.orderEvent.create({ data: { orderId: order.id, status, message } });
    return tx.order.findUniqueOrThrow({ where: { id: order.id }, include: orderInclude });
  });
}
