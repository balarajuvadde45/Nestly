import http from 'http';
import express from 'express';
import cors from 'cors';
import { env } from './lib/env';
import { errorHandler, notFound } from './middleware/error';
import { authRouter } from './routes/auth';
import { catalogRouter } from './routes/catalog';
import { ordersRouter } from './routes/orders';
import { sellerRouter } from './routes/seller';
import { addressesRouter } from './routes/addresses';
import { wisdomRouter } from './routes/wisdom';
import { initSocket } from './socket';

const app = express();
app.use(
  cors({
    origin: env.corsOrigin === '*' ? true : env.corsOrigin.split(','),
  }),
);
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'nestly-api',
    time: new Date().toISOString(),
  });
});

app.use('/api/auth', authRouter);
app.use('/api/catalog', catalogRouter);
app.use('/api/orders', ordersRouter);
app.use('/api/seller', sellerRouter);
app.use('/api/addresses', addressesRouter);
app.use('/api/wisdom', wisdomRouter);

app.use(notFound);
app.use(errorHandler);

const server = http.createServer(app);
initSocket(server);

server.listen(env.port, () => {
  console.log(`Nestly API listening on http://localhost:${env.port}`);
  console.log(`Health: http://localhost:${env.port}/health`);
  console.log(`Socket.IO ready for live tracking`);
});
