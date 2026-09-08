# Nestly API

Express 5, Prisma, PostgreSQL, Redis, Twilio Verify, and authenticated Socket.IO. See [Setup](../SETUP.md), [Architecture](../docs/ARCHITECTURE.md), and [Deployment](../DEPLOY.md).

## Commands

| Command | Purpose |
| --- | --- |
| `npm ci` | Install locked dependencies |
| `npm run env:check` | Validate the same environment rules used by the server |
| `npm run db:generate` | Generate Prisma client |
| `npm run db:migrate` | Create/apply migrations in development only |
| `npm run db:migrate:deploy` | Apply committed migrations in staging/production |
| `npm run db:seed` | Upsert reference categories without erasing marketplace data |
| `npm run db:setup` | Configuration check, generation, migrate deploy, reference seed |
| `npm run admin:create` | Provision an administrator from secure environment values |
| `npm run dev` | Development watcher |
| `npm run typecheck` | TypeScript checks including tests |
| `npm test` | Unit tests; integration tests require isolated TEST_DATABASE_URL |
| `npm run build` | Compile runtime to dist |
| `npm start` | Start compiled runtime; does not mutate schema |
| `npm run db:reset` | DESTRUCTIVE, disposable development databases only |

Production requires a strong JWT secret, PostgreSQL URL, Redis URL, exact HTTPS CORS origins, and Twilio Verify credentials. See `.env.example`; never commit populated environment files.

## Contracts

- Authentication: SMS verification or verified-registration email/password. All public registrations create customers.
- Protected requests validate the current database account, not only JWT claims.
- Checkout: `POST /api/orders/quote`, then `POST /api/orders` with the quote hash and UUID idempotency key.
- Only COD and LOCAL_DELIVERY are implemented. Unsupported fulfillment/payment modes are rejected.
- Seller approval is a human administrative decision, not automatic government verification.
- Socket connections and order subscriptions require authorization. Clients must refresh orders after reconnecting.
- `/readyz` checks PostgreSQL and configured Redis; `/health` also reports dependency availability.
- Order history, retained addresses, and deletion policy must be reviewed against the operator's published retention policy.

The release container runs compiled code as a non-root user. Migrations are a separate deployment job, not a command run concurrently by every API replica.
