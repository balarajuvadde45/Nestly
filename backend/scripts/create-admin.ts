import { randomUUID } from 'crypto';
import { prisma } from '../src/lib/prisma';
import { hashPassword } from '../src/lib/auth';
import { normalizePhone } from '../src/lib/otp';
import { z } from 'zod';

async function main() {
  const input = z.object({
    ADMIN_EMAIL: z.string().email(), ADMIN_NAME: z.string().min(2),
    ADMIN_PHONE: z.string().transform(normalizePhone),
    ADMIN_PASSWORD: z.string().min(16).max(72),
  }).parse(process.env);
  await prisma.user.create({ data: {
    id: randomUUID(), name: input.ADMIN_NAME, email: input.ADMIN_EMAIL.toLowerCase(),
    phone: '+91 ' + input.ADMIN_PHONE, role: 'ADMIN', authProvider: 'email',
    passwordHash: await hashPassword(input.ADMIN_PASSWORD),
  } });
  console.log('Administrator created. Remove ADMIN_PASSWORD from your environment.');
}
main().catch(() => { console.error('Administrator creation failed. Check inputs and account uniqueness.'); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());
