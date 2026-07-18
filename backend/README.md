# Nestly API

Express + Prisma + **PostgreSQL** + Socket.IO backend for Nestly.

All secrets live in **`backend/.env`** (never commit it).

## 1. Configure environment

```bash
cd backend
copy .env.example .env
```

Edit **`.env`** and set at least:

```env
DATABASE_URL=postgresql://postgres:YOUR_REAL_PASSWORD@localhost:5432/postgres?schema=public
JWT_SECRET=any_long_random_string
```

Or use separate fields:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=YOUR_REAL_PASSWORD
DB_NAME=postgres
```

## 2. Create tables + seed demo data

```bash
npm run db:setup
```

This will:
1. Validate `.env`
2. Generate Prisma client
3. Push schema to PostgreSQL
4. Seed demo users, sellers, products

## 3. Run API

```bash
npm run dev
```

Health: http://localhost:4000/health  

## Scripts

| Script | Description |
|--------|-------------|
| `npm run env:check` | Validate `.env` (no secrets printed) |
| `npm run db:setup` | check env + push schema + seed |
| `npm run db:push` | Apply Prisma schema only |
| `npm run db:seed` | Re-seed data |
| `npm run db:reset` | Wipe tables + re-seed |
| `npm run dev` | Start API with hot reload |

## Demo logins (after seed)

Password: `password123`

- Customer: `priya@nestly.app`
- Seller: `amma@nestly.app`
- Admin: `admin@nestly.app`

## Seller data

Products and store changes from the **Seller dashboard** are saved in **PostgreSQL** via Prisma (`Product`, `Vendor`, `Order`, etc.).
