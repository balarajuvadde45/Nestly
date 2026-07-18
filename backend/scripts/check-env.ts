/**
 * Validate backend/.env without starting the full API.
 * Usage: npx tsx scripts/check-env.ts
 */
import path from 'path';
import dotenv from 'dotenv';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const missing: string[] = [];
const placeholders: string[] = [];

function check(name: string, opts?: { allowPlaceholder?: boolean }) {
  const v = process.env[name]?.trim();
  if (!v) {
    missing.push(name);
    return;
  }
  if (
    !opts?.allowPlaceholder &&
    (v.includes('YOUR_PASSWORD') ||
      v.includes('CHANGE_ME') ||
      v.includes('MASKED') ||
      v === 'changeme')
  ) {
    placeholders.push(name);
  }
}

const hasFullUrl =
  process.env.DATABASE_URL &&
  !process.env.DATABASE_URL.includes('YOUR_PASSWORD') &&
  !process.env.DATABASE_URL.includes('CHANGE_ME');

if (!hasFullUrl) {
  check('DB_HOST');
  check('DB_USER');
  check('DB_PASSWORD');
  check('DB_NAME');
} else {
  console.log('DATABASE_URL: set (value hidden)');
}

check('JWT_SECRET');
check('PORT', { allowPlaceholder: true });

if (missing.length || placeholders.length) {
  console.error('Nestly env check FAILED');
  if (missing.length) console.error('  Missing:', missing.join(', '));
  if (placeholders.length)
    console.error('  Still placeholders:', placeholders.join(', '));
  console.error('Edit backend/.env using backend/.env.example as a guide.');
  process.exit(1);
}

console.log('Nestly env check OK');
console.log('  PORT =', process.env.PORT || '4000');
console.log('  JWT_SECRET = (set)');
console.log('  Database config = ready');
