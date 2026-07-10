# Nestly

Marketplace for **home cooks**, **cloud kitchens**, **pickles & spices**, **home boutiques**, and **community wisdom** — built with Flutter for **Android** and **Web**.

**Nestly** = products and wisdom that come from home to home.

## Features

- **Hubs** — Food · Pickles · Clothes (Boutiques) · Wisdom Circle
- **Home feed** — banners, categories, popular sellers, bestsellers
- **Seller storefronts** — menu/catalog, offers, veg filter
- **Cart & checkout** — coupons, bill, addresses, payments (demo)
- **Orders** — status timeline, live map tracking
- **Seller dashboard** — products, orders, store settings
- **Wisdom Circle** — elders’ tips, remedies, Q&A (senior-friendly UI)
- **Responsive** — bottom nav on mobile, header + rail on web

## Run (full stack)

**1. Backend**
```bash
cd backend
npm run setup   # first time
npm run dev     # http://localhost:4000
```

**2. Flutter**
```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
# Android emulator:
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:4000
```

See **[SETUP.md](./SETUP.md)** for Google Maps key and full configuration.

## Demo credentials

| Role | Value |
|--------|--------|
| Customer | `priya@nestly.app` / `password123` |
| Seller | `amma@nestly.app` / `password123` |
| Phone OTP | any 10 digits + OTP `123456` |
| Coupons | `NESTLY20`, `FLAT50`, `FIRST100` |
| Guest | Profile → Continue as guest |

## Project structure

```
lib/           # Flutter app (Nestly)
backend/       # Nestly API (Express + Prisma + Socket.IO)
```

## Brand

- App name: **Nestly**
- Tagline: *Food · Pickles · Clothes · Wisdom — from home to home*
- Primary: `#E23744`
