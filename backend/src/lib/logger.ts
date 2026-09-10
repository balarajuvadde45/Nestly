import { pino } from 'pino';
import { env } from './env';

const isTest = process.env.NODE_ENV === 'test';
const isProd = env.nodeEnv === 'production';

const level =
  process.env.LOG_LEVEL ?? (isTest ? 'silent' : env.isDev ? 'debug' : 'info');

/**
 * Structured application logger.
 * - local dev: pretty, colorized output (pino-pretty)
 * - production: line-delimited JSON (ingested by the platform log pipeline)
 * - tests: silent
 */
export const logger = pino({
  level,
  redact: {
    paths: ['req.headers.authorization', 'req.headers.cookie', 'res.headers["set-cookie"]', 'password', 'otp', 'token'],
    censor: '[REDACTED]',
  },
  ...(isProd || isTest
    ? {}
    : {
        transport: {
          target: 'pino-pretty',
          options: {
            colorize: true,
            translateTime: 'SYS:standard',
            ignore: 'pid,hostname',
          },
        },
      }),
});
