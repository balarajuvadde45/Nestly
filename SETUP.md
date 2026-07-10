# Nestly — Setup Guide (Backend + Maps + Seller)

This document lists **exactly what you need to do** on your machine.

---

## Architecture

| Piece | Tech | Location |
|--------|------|----------|
| API + DB | Node.js, Express, Prisma, SQLite, JWT | `backend/` |
| Live tracking | Socket.IO + order rider lat/lng | `backend/src/socket.ts` |
| Customer app | Flutter (Android + Web) — **Nestly** | `lib/` |
| Seller dashboard | Flutter routes `/seller/*` | `lib/screens/seller/` |
| Maps | `google_maps_flutter` (+ fallback UI) | `lib/screens/tracking/` |
| Wisdom Circle | Community tips & Q&A | `lib/screens/wisdom/` |

---

## What YOU must do

### 1. Start the backend (required)

```bash
cd backend
npm run setup          # first time only (install + DB + seed)
npm run dev            # start API on http://localhost:4000
```

Check: open http://localhost:4000/health → should return `{ "ok": true, "service": "nestly-api", ... }`.

**Demo accounts** (password for all: `password123`):

| Role | Email |
|------|--------|
| Customer | `priya@nestly.app` |
| Seller (Amma's Kitchen) | `amma@nestly.app` |
| Seller (Pickles) | `pickles@nestly.app` |
| Admin | `admin@nestly.app` |
| Phone OTP | any 10 digits + OTP **`123456`** |

### 2. Google Maps API key (optional for real maps)

Without a key, live tracking still works (coordinates + status).

1. [Google Cloud Console](https://console.cloud.google.com/)
2. Enable **Maps SDK for Android** + **Maps JavaScript API**
3. Create an API key

```bash
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY --dart-define=API_BASE_URL=http://localhost:4000
```

Android: put `GOOGLE_MAPS_API_KEY=YOUR_KEY` in `android/local.properties`  
Package for restriction: `com.example.nestly`

### 3. Point the app at the backend

| Where you run Flutter | `API_BASE_URL` |
|------------------------|----------------|
| Chrome / desktop | `http://localhost:4000` |
| Android emulator | `http://10.0.2.2:4000` |
| Physical phone | `http://YOUR_PC_LAN_IP:4000` |

### 4. After rename to Nestly — re-seed DB

If you still have old `homefoods.app` accounts:

```bash
cd backend
npm run db:reset
```

---

## Run full stack

**Terminal 1 — API**
```bash
cd backend
npm run dev
```

**Terminal 2 — Flutter**
```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
```

### Seller dashboard

1. Profile → **Seller dashboard** (or `/seller`)
2. Login: `amma@nestly.app` / `password123`

### Wisdom Circle

Bottom/side nav → **Wisdom** — tips, remedies, Q&A from elders

---

## Coupons

- `NESTLY20` — 20% off up to ₹100  
- `FLAT50` — ₹50 off above ₹199  
- `FIRST100` — ₹100 off  

---

## Troubleshooting

| Issue | Fix |
|--------|------|
| App shows mock data only | Backend not running or wrong `API_BASE_URL` |
| Login fails with old emails | `npm run db:reset` in backend |
| Android can't reach API | Use `10.0.2.2` not `localhost` |
