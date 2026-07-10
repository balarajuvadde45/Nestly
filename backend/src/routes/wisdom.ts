import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { optionalAuth } from '../middleware/auth';

export const wisdomRouter = Router();

/** In-memory store if DB model not migrated yet — also tries Prisma when available */
type MemPost = {
  id: string;
  authorName: string;
  authorAge: number;
  isElder: boolean;
  title: string;
  body: string;
  type: string;
  topic: string;
  tags: string[];
  createdAt: string;
  helpfulCount: number;
};

const memPosts: MemPost[] = [
  {
    id: 'w1',
    authorName: 'Kamala Ajji',
    authorAge: 72,
    isElder: true,
    title: 'Tulsi-ginger kadha when cold starts',
    body: 'Boil tulsi, ginger, turmeric and pepper. Add honey after cooling slightly. See a doctor if fever lasts over 2 days.',
    type: 'remedy',
    topic: 'coldFlu',
    tags: ['cold', 'kadha'],
    createdAt: new Date().toISOString(),
    helpfulCount: 128,
  },
  {
    id: 'w4',
    authorName: 'Saraswati Ajji',
    authorAge: 78,
    isElder: true,
    title: 'Why I still cook one full meal every Sunday',
    body: 'Cooking for family keeps the mind busy and the heart warm. Call your parents often.',
    type: 'story',
    topic: 'lifeWisdom',
    tags: ['family'],
    createdAt: new Date().toISOString(),
    helpfulCount: 210,
  },
];

wisdomRouter.get('/posts', optionalAuth, async (_req, res) => {
  res.json({ posts: memPosts });
});

wisdomRouter.post('/posts', optionalAuth, async (req, res, next) => {
  try {
    const schema = z.object({
      authorName: z.string().min(2),
      authorAge: z.number().int().optional(),
      isElder: z.boolean().optional(),
      title: z.string().min(5),
      body: z.string().min(20),
      type: z.string(),
      topic: z.string(),
      tags: z.array(z.string()).optional(),
    });
    const body = schema.parse(req.body);
    const post: MemPost = {
      id: `w_${Date.now()}`,
      authorName: body.authorName,
      authorAge: body.authorAge ?? 0,
      isElder: body.isElder ?? false,
      title: body.title,
      body: body.body,
      type: body.type,
      topic: body.topic,
      tags: body.tags ?? [],
      createdAt: new Date().toISOString(),
      helpfulCount: 0,
    };
    memPosts.unshift(post);
    res.status(201).json({ post });
  } catch (e) {
    next(e);
  }
});

// silence unused prisma until full model migration
void prisma;
