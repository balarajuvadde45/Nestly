import path from 'path';
import dotenv from 'dotenv';

// Always load backend/.env (works even if process is started from repo root)
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config(); // fallback: cwd .env

function required(name: string, value: string | undefined): string {
  if (!value || value.trim() === '' || value.includes('CHANGE_ME')) {
    throw new Error(
      `[Nestly config] Missing or placeholder value for ${name}. ` +
        `Edit backend/.env (see backend/.env.example).`,
    );
  }
  return value.trim();
}

function optional(name: string, fallback: string): string {
  const v = process.env[name];
  if (!v || v.trim() === '') return fallback;
  return v.trim();
}

/**
 * Build DATABASE_URL from either:
 * 1) Full DATABASE_URL, or
 * 2) DB_HOST + DB_PORT + DB_USER + DB_PASSWORD + DB_NAME (+ optional DB_SCHEMA, DB_SSL)
 */
function resolveDatabaseUrl(): string {
  const full = process.env.DATABASE_URL?.trim();
  if (full && !full.includes('CHANGE_ME') && !full.includes('YOUR_PASSWORD')) {
    return full;
  }

  const host = process.env.DB_HOST?.trim();
  const user = process.env.DB_USER?.trim();
  const password = process.env.DB_PASSWORD?.trim();
  const name = process.env.DB_NAME?.trim();
  const port = process.env.DB_PORT?.trim() || '5432';
  const schema = process.env.DB_SCHEMA?.trim() || 'public';
  const ssl = (process.env.DB_SSL || 'false').toLowerCase() === 'true';

  if (!host || !user || !password || !name) {
    throw new Error(
      '[Nestly config] Set DATABASE_URL in backend/.env, OR set DB_HOST, DB_USER, DB_PASSWORD, DB_NAME. ' +
        'Copy backend/.env.example → backend/.env and fill real values.',
    );
  }

  if (
    password === 'CHANGE_ME' ||
    password === 'YOUR_PASSWORD' ||
    password.includes('MASKED')
  ) {
    throw new Error(
      '[Nestly config] DB_PASSWORD is still a placeholder. Put your real PostgreSQL password in backend/.env.',
    );
  }

  const encUser = encodeURIComponent(user);
  const encPass = encodeURIComponent(password);
  const sslQuery = ssl ? '&sslmode=require' : '';
  return `postgresql://${encUser}:${encPass}@${host}:${port}/${name}?schema=${schema}${sslQuery}`;
}

const databaseUrl = resolveDatabaseUrl();
// Prisma reads process.env.DATABASE_URL
process.env.DATABASE_URL = databaseUrl;

export const env = {
  nodeEnv: optional('NODE_ENV', 'development'),
  port: Number(optional('PORT', '4000')),
  databaseUrl,
  jwtSecret: required('JWT_SECRET', process.env.JWT_SECRET),
  jwtExpiresIn: optional('JWT_EXPIRES_IN', '7d'),
  corsOrigin: optional('CORS_ORIGIN', '*'),
  defaultCity: optional('DEFAULT_CITY', 'Hyderabad'),
  isDev: optional('NODE_ENV', 'development') !== 'production',
};

/** Safe summary for logs (never prints password). */
export function dbPublicInfo(): string {
  try {
    const u = new URL(env.databaseUrl.replace(/^postgresql:/, 'http:'));
    return `${u.hostname}:${u.port || '5432'}/${u.pathname.replace(/^\//, '')}`;
  } catch {
    return '(invalid DATABASE_URL)';
  }
}
