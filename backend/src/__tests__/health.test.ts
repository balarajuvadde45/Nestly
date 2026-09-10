import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../app';

describe('health endpoints', () => {
  const app = createApp();

  it('GET /healthz returns liveness ok (no DB required)', async () => {
    const res = await request(app).get('/healthz');
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.service).toBe('nestly-api');
  });

  it('unknown route returns 404 with an error body', async () => {
    const res = await request(app).get('/definitely-not-a-route');
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Not found');
  });
});
