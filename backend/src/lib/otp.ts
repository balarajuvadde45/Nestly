/**
 * In-memory OTP store for phone verification.
 * Production: replace with Redis + SMS (Twilio / MSG91 / Firebase).
 */

type OtpEntry = {
  code: string;
  expiresAt: number;
  attempts: number;
};

const store = new Map<string, OtpEntry>();

const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes
const MAX_ATTEMPTS = 5;

export function normalizePhone(phone: string): string {
  return phone.replace(/\D/g, '').slice(-10);
}

export function generateOtp(): string {
  return String(Math.floor(100000 + Math.random() * 900000));
}

export function saveOtp(phone: string, code: string): void {
  const key = normalizePhone(phone);
  store.set(key, {
    code,
    expiresAt: Date.now() + OTP_TTL_MS,
    attempts: 0,
  });
}

export function verifyOtp(
  phone: string,
  code: string,
  options?: { allowMaster?: boolean },
): { ok: true } | { ok: false; error: string } {
  const key = normalizePhone(phone);
  const entry = store.get(key);

  // Master OTP only in development — never in production.
  if (options?.allowMaster && code === '123456') {
    store.delete(key);
    return { ok: true };
  }

  if (!entry) {
    return { ok: false, error: 'OTP expired or not requested. Send OTP again.' };
  }
  if (Date.now() > entry.expiresAt) {
    store.delete(key);
    return { ok: false, error: 'OTP expired. Request a new one.' };
  }
  if (entry.attempts >= MAX_ATTEMPTS) {
    store.delete(key);
    return { ok: false, error: 'Too many attempts. Request a new OTP.' };
  }
  if (entry.code !== code) {
    entry.attempts += 1;
    return { ok: false, error: 'Invalid OTP. Please try again.' };
  }
  store.delete(key);
  return { ok: true };
}

export function peekDevOtp(phone: string): string | null {
  const entry = store.get(normalizePhone(phone));
  if (!entry || Date.now() > entry.expiresAt) return null;
  return entry.code;
}
