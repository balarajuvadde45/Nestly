# Nestly

Nestly is a marketplace for local food businesses, pickle and sweet makers, cloud kitchens, boutiques, and wholesale FMCG distributors. Flutter provides the customer, seller, and administration interfaces; Express and PostgreSQL provide the shared backend.

## Current Transaction Scope

Customers can browse approved sellers, save favourites, manage addresses, and place single-seller cash-on-delivery orders. Checkout validates prices, availability, stock, minimum quantities, case packs, and local serviceability on the server. Sellers manage their storefront, products, and order status; administrators review business applications.

**This repository has release hardening, not a certification of production readiness.** Production credentials, legal and operational decisions, native signing, real-device acceptance testing, and the outstanding work in [Release Readiness](docs/RELEASE_READINESS.md) are required before public launch. Current delivery is restricted to the seller's city and exact pincode. Nationwide shipping and online payments are not connected.

## Start Here

- [Local Setup](SETUP.md)
- [Architecture and Data Flow](docs/ARCHITECTURE.md)
- [Deployment, Scaling, and Owner Responsibilities](DEPLOY.md)
- [Release Readiness and Remaining Work](docs/RELEASE_READINESS.md)
- [Backend Commands](backend/README.md)

## Repository

| Location | Responsibility |
| --- | --- |
| `lib/` | Flutter screens, providers, models, routing, API and socket clients |
| `backend/src/` | Express routes, access control, checkout, provider integrations |
| `backend/prisma/` | PostgreSQL schema, versioned migrations, reference categories |
| `backend/src/__tests__/`, `test/` | Backend and Flutter regression tests |
| `android/`, `ios/`, `web/` | Release platform configuration |
| `config/`, `scripts/`, `deploy/` | Build configuration and deployment helpers |
| `.github/workflows/` | Automated checks and platform compile jobs |
| `tool/`, `assets/brand/` | Reproducible launcher artwork |

Seeds create reference categories only. There are no bundled customer or seller credentials, fixed verification codes, synthetic orders, or simulated courier updates. Existing databases are never automatically cleaned of historical sample records; audit them separately before importing data into production.

Android application ID and iOS bundle ID: `in.nestly.app`. Confirm ownership before creating store listings; published identifiers are not casual configuration changes.
