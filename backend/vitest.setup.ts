// Hermetic environment for tests. Set BEFORE app/env modules are imported so
// env.ts validation passes without a real backend/.env (e.g. in CI).
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = process.env.JWT_SECRET ?? 'test-secret-not-for-production';
process.env.DATABASE_URL =
  process.env.DATABASE_URL ??
  'postgresql://test:test@localhost:5432/nestly_test?schema=public';
