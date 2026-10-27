import { Prisma } from '@prisma/client';

/**
 * Durable notification queue. Rows are written inside the same transaction as
 * the state change they belong to, so a crash cannot lose a notification.
 * Dispatch (FCM push, transactional email) runs from a worker once channel
 * credentials are configured; until then entries stay pending and are safe.
 */
export type NotificationTemplate =
  | 'ORDER_PLACED'
  | 'ORDER_CONFIRMED'
  | 'ORDER_PREPARING'
  | 'ORDER_OUT_FOR_DELIVERY'
  | 'ORDER_DELIVERED'
  | 'ORDER_CANCELLED'
  | 'PAYMENT_RECEIVED'
  | 'PAYMENT_FAILED';

const CUSTOMER_MESSAGE: Record<NotificationTemplate, string> = {
  ORDER_PLACED: 'Your order is placed',
  ORDER_CONFIRMED: 'The seller confirmed your order',
  ORDER_PREPARING: 'Your order is being prepared',
  ORDER_OUT_FOR_DELIVERY: 'Your order is out for delivery',
  ORDER_DELIVERED: 'Your order was delivered',
  ORDER_CANCELLED: 'Your order was cancelled',
  PAYMENT_RECEIVED: 'Payment received for your order',
  PAYMENT_FAILED: 'Payment failed for your order',
};

export function customerMessage(template: NotificationTemplate): string {
  return CUSTOMER_MESSAGE[template];
}

type Client = Prisma.TransactionClient | typeof import('./prisma').prisma;

export async function queueNotification(
  client: Client,
  input: { userId?: string | null; orderId?: string | null; template: NotificationTemplate; payload?: Record<string, unknown> },
): Promise<void> {
  if (!input.userId) return;
  await client.notificationOutbox.create({
    data: {
      userId: input.userId,
      orderId: input.orderId ?? null,
      channel: 'PUSH',
      template: input.template,
      payloadJson: JSON.stringify({ message: CUSTOMER_MESSAGE[input.template], ...(input.payload ?? {}) }),
    },
  });
}
