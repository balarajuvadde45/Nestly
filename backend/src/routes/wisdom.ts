import { Router } from 'express';
import { z } from 'zod';
import { optionalAuth } from '../middleware/auth';

export const wisdomRouter = Router();

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

/** UAT: starts empty — community posts only what users publish. */
const memPosts: MemPost[] = [];

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
