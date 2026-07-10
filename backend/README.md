# Nestly API

Express + Prisma (SQLite) + Socket.IO backend for the Nestly marketplace.

## Quick start

```bash
npm run setup   # install, generate client, create DB, seed
npm run dev     # http://localhost:4000
```

## Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Hot-reload server (`tsx watch`) |
| `npm run setup` | Fresh install + DB + seed |
| `npm run db:seed` | Re-seed data |
| `npm run db:reset` | Wipe DB + seed |

## Env (`backend/.env`)

```env
PORT=4000
DATABASE_URL="file:./dev.db"
JWT_SECRET=change_me
JWT_EXPIRES_IN=7d
CORS_ORIGIN=*
```

## Seeded logins

Password: `password123`

- Customer: `priya@nestly.app`
- Seller: `amma@nestly.app`
- Seller: `pickles@nestly.app`
- Admin: `admin@nestly.app`
