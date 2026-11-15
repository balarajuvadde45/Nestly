# Tamarin

Tamarin is a marketplace for local food businesses, pickle and sweet makers, cloud kitchens, boutiques, and wholesale FMCG distributors. This repository is the **customer app**. The seller experience ships separately in `../Nestly_Seller` (**Tamarin Partner** — onboarding, storefront, products, orders, admin console). Both apps share one Express/PostgreSQL backend: `backend/` in this repository.

| App | Repo | Package / bundle id |
| --- | --- | --- |
| **Tamarin** (customer shop) | this repo (`lib/main.dart`) | `in.tamarin.app` |
| **Tamarin Partner** (seller app) | `../Nestly_Seller` (`lib/main.dart`) | `in.tamarin.partner` |

## Current Transaction Scope

Customers browse approved sellers, save favourites, manage addresses, and place single-seller orders (cash on delivery, plus online payments via Razorpay Payment Links when configured). Checkout validates prices, availability, stock, minimum quantities, case packs, and local serviceability on the server; online payments are confirmed by a signed provider webhook with automatic refunds and reconciliation. Sellers manage their storefront, products, and order status in the Partner app; administrators review business applications there too.

**This repository has release hardening, not a certification of production readiness.** The remaining owner work — payment, SMS, push, logistics and AWS setup — is documented step by step in [INTEGRATIONS.md](INTEGRATIONS.md) and [awshosting.md](awshosting.md). Current delivery is restricted to the seller's city and exact pincode.

## Start Here

- [Integrations you must do (owner checklist)](INTEGRATIONS.md)
- [AWS hosting, step by step](awshosting.md)
- [Local Setup](SETUP.md)
- [Architecture and Data Flow](docs/ARCHITECTURE.md)
- [Deployment, Scaling, and Owner Responsibilities](DEPLOY.md)
- [Release Readiness and Remaining Work](docs/RELEASE_READINESS.md)
- [Code Review Findings](docs/CODE_REVIEW.md)
- [Backend Commands](backend/README.md)

## Repository

| Location | Responsibility |
| --- | --- |
| `lib/main.dart`, `lib/router/app_router.dart` | Customer app entry + navigation |
| `lib/` | Customer screens, providers, models, API and socket clients |
| `backend/src/` | Express routes, access control, checkout, payments, notifications |
| `backend/prisma/` | PostgreSQL schema, versioned migrations, reference categories |
| `backend/src/__tests__/`, `test/` | Backend and Flutter regression tests |
| `android/`, `ios/`, `web/` | Customer platform configuration |
| `config/`, `scripts/`, `deploy/` | Build configuration and deployment helpers |
| `.github/workflows/` | Automated checks and platform compile jobs |
| `tool/`, `assets/brand/` | Reproducible launcher artwork |

Seeds create reference categories only. There are no bundled customer or seller credentials, fixed verification codes, synthetic orders, or simulated courier updates. Existing databases are never automatically cleaned of historical sample records; audit them separately before importing data into production.

Store identifiers: customer `in.tamarin.app` (this repo), partner `in.tamarin.partner` (`Nestly_Seller`). Confirm domain ownership before creating store listings; published identifiers are not casual configuration changes.
