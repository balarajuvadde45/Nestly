process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'isolated-test-signing-key-not-for-release';
process.env.TWILIO_ACCOUNT_SID = '';
process.env.TWILIO_AUTH_TOKEN = '';
process.env.TWILIO_VERIFY_SERVICE_SID = '';
process.env.REDIS_URL = '';
const testUrl = process.env.TEST_DATABASE_URL;
if (testUrl && new URL(testUrl).pathname !== '/nestly_test') {
  throw new Error('TEST_DATABASE_URL must target a dedicated nestly_test database');
}
process.env.DATABASE_URL = testUrl ?? 'postgresql://test:test@127.0.0.1:55439/nestly_test';
