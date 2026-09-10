import { createClient } from 'redis';
import { RedisStore } from 'rate-limit-redis';
import { env } from './env';
import { logger } from './logger';

export const redis = env.redisUrl && env.nodeEnv !== 'test'
  ? createClient({ url: env.redisUrl, disableOfflineQueue: true })
  : null;
redis?.on('error', () => logger.error('Redis connection failed'));

export function rateLimitStore(prefix: string) {
  return redis ? new RedisStore({
    prefix: `nestly:limit:${prefix}:`,
    sendCommand: (...args: string[]) => redis.sendCommand(args),
  }) : undefined;
}
