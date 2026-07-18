// Ensure .env is loaded before PrismaClient reads DATABASE_URL
import './env';
import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient();
