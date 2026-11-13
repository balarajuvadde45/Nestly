import { Router } from 'express';
import { createHash } from 'crypto';
import fs from 'fs';
import path from 'path';
import { z } from 'zod';
import { env } from '../lib/env';
import { AuthedRequest, requireAuth, requireSellerAccess } from '../middleware/auth';

export const mediaRouter = Router();

const MAX_IMAGE_BYTES = 1_400_000; // 1.4 MB decoded, within the 2 MB JSON body limit
const EXT_BY_MAGIC: { type: string; ext: string; test: (b: Buffer) => boolean }[] = [
  { type: 'image/jpeg', ext: 'jpg', test: b => b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff },
  { type: 'image/png', ext: 'png', test: b => b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47 },
  { type: 'image/webp', ext: 'webp', test: b => b.slice(0, 4).toString() === 'RIFF' && b.slice(8, 12).toString() === 'WEBP' },
  { type: 'image/gif', ext: 'gif', test: b => b.slice(0, 3).toString() === 'GIF' },
];

export function uploadDir(): string {
  return env.uploadDir || path.resolve(__dirname, '../../uploads');
}

/**
 * Seller image upload. The body is JSON with base64 image bytes so it passes
 * the shared JSON parser and rate limiter; the magic bytes decide the type,
 * never the client-declared content type. Files are served from /media.
 * Swap UPLOAD_DIR to object-storage mount points without changing callers.
 */
mediaRouter.post('/upload', requireAuth, requireSellerAccess(), async (req: AuthedRequest, res, next) => {
  try {
    const input = z.object({
      filename: z.string().min(1).max(120),
      dataBase64: z.string().min(50).max(Math.ceil(MAX_IMAGE_BYTES * 4 / 3) + 1000),
    }).parse(req.body);
    const bytes = Buffer.from(input.dataBase64, 'base64');
    if (bytes.length < 64 || bytes.length > MAX_IMAGE_BYTES) {
      throw Object.assign(new Error('Image must be between 64 bytes and 1.4 MB'), { status: 400 });
    }
    const kind = EXT_BY_MAGIC.find(k => k.test(bytes.subarray(0, 16)));
    if (!kind) throw Object.assign(new Error('Only JPEG, PNG, WebP or GIF images are accepted'), { status: 415 });

    const dir = uploadDir();
    await fs.promises.mkdir(dir, { recursive: true });
    const digest = createHash('sha256').update(bytes).digest('hex').slice(0, 20);
    const safe = input.filename.replace(/[^a-zA-Z0-9._-]+/g, '-').replace(/^[.-]+/, '').slice(0, 60) || 'image';
    const name = `${digest}-${safe}.${kind.ext}`;
    await fs.promises.writeFile(path.join(dir, name), bytes, { mode: 0o644 });
    const base = env.mediaBaseUrl || `${req.protocol}://${req.get('host') ?? 'localhost'}`;
    res.status(201).json({ url: `${base.replace(/\/$/, '')}/media/${name}`, bytes: bytes.length, contentType: kind.type });
  } catch (e) { next(e); }
});
