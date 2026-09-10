# Local Setup

## Prerequisites

Use Node.js 22, npm, PostgreSQL, and Flutter 3.47.2 (the current CI pin). Install Android Studio/SDK for Android. iOS compilation and signing require macOS and Xcode. Run `flutter doctor -v` before native builds.

## Backend

From the repository root:

```powershell
Copy-Item backend/.env.example backend/.env
cd backend
npm ci
```

Edit `backend/.env` with a dedicated local database URL and a randomly generated JWT secret. Do not use a production database for development. Configure Twilio Verify for real SMS authentication. Missing provider configuration fails closed; there is no alternate verification code.

Redis is required in production. For local development without Redis, leave `REDIS_URL` blank. Set `CORS_ORIGIN` to the exact local web origin, such as `http://localhost:8080`, and `TRUST_PROXY_HOPS=0` for direct requests.

```powershell
npm run db:setup
npm run dev
```

The setup command validates configuration, generates Prisma, applies versioned migrations, and upserts reference categories. It does not create accounts or a catalog. Check `http://localhost:4000/readyz`.

Optional local PostgreSQL and Redis containers are defined in `docker-compose.yml`. Its database credentials are local-only; do not expose its ports publicly or reuse it as the production deployment.

## Application

In a second terminal at the repository root:

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:4000
```

For an Android emulator, use `API_BASE_URL=http://10.0.2.2:4000` and the device ID from `flutter devices`. Physical devices need a reachable development host. Cleartext HTTP is allowed only by the Android debug configuration.

Create a customer using a real verified phone number. Open a business from that account, complete its address and store image, add products, then have an administrator review it. Empty catalog screens are intentional until approved sellers publish real products.

## First Administrator

In an administrative terminal, provide `ADMIN_EMAIL`, `ADMIN_NAME`, `ADMIN_PHONE`, and `ADMIN_PASSWORD` through secure environment configuration, then run `npm run admin:create` from `backend/`. The password must contain 16-72 characters. The command creates a new administrator; it does not overwrite an existing account. Clear temporary environment secrets afterwards. Never put credentials into documentation or source control.

## Verification

```powershell
flutter analyze
flutter test
cd backend
npm run typecheck
npm test
npm run build
npm audit
```

Database integration tests require `TEST_DATABASE_URL` pointing to an isolated database named exactly `nestly_test`. Apply migrations there first. Without that variable the integration suite is skipped; a green unit run alone does not validate checkout transactions.

Never use `db:reset`, `migrate reset`, or `db push` on production. See [Deployment](DEPLOY.md) for signed releases and migration procedures.
