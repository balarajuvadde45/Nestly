import { env } from './env';

export function normalizePhone(phone: string): string {
  const digits = phone.replace(/[\s()+-]/g, '');
  const local = digits.length === 12 && digits.startsWith('91') ? digits.slice(2) : digits;
  if (!/^[6-9]\d{9}$/.test(local)) {
    throw Object.assign(new Error('Enter a valid Indian mobile number'), { status: 400 });
  }
  return local;
}

async function verifyRequest(resource: string, parameters: Record<string, string>) {
  if (!env.twilioAccountSid || !env.twilioAuthToken || !env.twilioVerifyServiceSid) {
    throw Object.assign(new Error('Phone verification is unavailable. Please try later.'), { status: 503 });
  }
  let response: Response;
  try {
    response = await fetch(
      `https://verify.twilio.com/v2/Services/${encodeURIComponent(env.twilioVerifyServiceSid)}/${resource}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${Buffer.from(env.twilioAccountSid + ':' + env.twilioAuthToken).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams(parameters),
        signal: AbortSignal.timeout(10_000),
      },
    );
  } catch {
    throw Object.assign(new Error('Phone verification is unavailable. Please try later.'), { status: 503 });
  }
  if (response.status === 404 && resource === 'VerificationCheck') return { status: 'expired' };
  if (!response.ok) {
    throw Object.assign(new Error(response.status === 429
      ? 'Too many verification attempts. Please try later.'
      : 'Phone verification failed. Please try later.'), { status: response.status === 429 ? 429 : 503 });
  }
  return await response.json() as { status: string };
}

export async function sendOtp(phone: string): Promise<void> {
  await verifyRequest('Verifications', { To: `+91${normalizePhone(phone)}`, Channel: 'sms' });
}

export async function verifyOtp(phone: string, code: string): Promise<boolean> {
  if (!/^\d{6}$/.test(code)) return false;
  const result = await verifyRequest('VerificationCheck', { To: `+91${normalizePhone(phone)}`, Code: code });
  return result.status === 'approved';
}
