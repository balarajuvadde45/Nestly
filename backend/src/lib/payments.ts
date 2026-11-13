import { createHmac, timingSafeEqual } from 'crypto';
import { env } from './env';

/**
 * Razorpay Payment Links integration.
 *
 * A payment link is created after an order is placed (stock already reserved).
 * The customer opens the hosted link and pays; Razorpay notifies us on the
 * signed webhook in routes/payments.ts. This needs no in-app SDK and works on
 * Android, iOS and web. Until credentials are configured the API refuses
 * online checkout and cash on delivery keeps working.
 */
export function onlinePaymentsConfigured(): boolean {
  return Boolean(env.razorpayKeyId && env.razorpayKeySecret);
}

const RAZORPAY_API = 'https://api.razorpay.com/v1';

function authHeader(): string {
  if (!env.razorpayKeyId || !env.razorpayKeySecret) {
    throw Object.assign(new Error('Online payments are not configured'), { status: 503 });
  }
  return 'Basic ' + Buffer.from(`${env.razorpayKeyId}:${env.razorpayKeySecret}`).toString('base64');
}

export interface PaymentLinkResult {
  linkId: string;
  shortUrl: string;
  amountPaise: number;
}

export async function createPaymentLink(input: {
  orderId: string;
  amountPaise: number;
  customerName: string;
  customerPhone: string;
  customerEmail: string;
  description: string;
}): Promise<PaymentLinkResult> {
  const res = await fetch(`${RAZORPAY_API}/payment_links`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: authHeader() },
    body: JSON.stringify({
      amount: input.amountPaise,
      currency: 'INR',
      accept_partial: false,
      reference_id: input.orderId,
      description: input.description.slice(0, 200),
      customer: {
        name: input.customerName,
        contact: input.customerPhone,
        email: input.customerEmail,
      },
      notify: { sms: true, email: true },
      reminder_enable: false,
    }),
  });
  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw Object.assign(new Error('Payment provider rejected the request'), {
      status: 502, detail: detail.slice(0, 500),
    });
  }
  const link = (await res.json()) as { id: string; short_url: string; amount: number };
  return { linkId: link.id, shortUrl: link.short_url, amountPaise: link.amount };
}

export async function fetchLink(linkId: string): Promise<{ status: string; payments: { id: string; status: string }[] }> {
  const res = await fetch(`${RAZORPAY_API}/payment_links/${encodeURIComponent(linkId)}`, {
    headers: { Authorization: authHeader() },
  });
  if (!res.ok) throw Object.assign(new Error('Payment provider rejected the request'), { status: 502 });
  return (await res.json()) as never;
}

export async function refundPayment(paymentId: string, amountPaise: number): Promise<string> {
  const res = await fetch(`${RAZORPAY_API}/payments/${encodeURIComponent(paymentId)}/refund`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: authHeader() },
    body: JSON.stringify({ amount: amountPaise, speed: 'normal' }),
  });
  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw Object.assign(new Error('Payment provider rejected the refund'), {
      status: 502, detail: detail.slice(0, 500),
    });
  }
  const refund = (await res.json()) as { id: string };
  return refund.id;
}

/** HMAC-SHA256 of the raw webhook body with the webhook secret, hex-encoded. */
export function verifyWebhookSignature(rawBody: Buffer, signature: string | undefined): boolean {
  if (!env.razorpayWebhookSecret || !signature) return false;
  const expected = createHmac('sha256', env.razorpayWebhookSecret).update(rawBody).digest('hex');
  const a = Buffer.from(expected);
  const b = Buffer.from(signature);
  return a.length === b.length && timingSafeEqual(a, b);
}
