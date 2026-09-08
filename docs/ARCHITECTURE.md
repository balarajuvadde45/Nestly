# Architecture

## Shape

Nestly is a modular monolith with one shared transactional database. This is an implementation description, not a claim of audited security or unlimited capacity.

```text
Flutter Android / iOS / Web
        | HTTPS REST + authenticated WebSocket
Managed ingress or Nginx
        |
Express API replicas
  | Prisma       | shared limits and socket fan-out   | verification
PostgreSQL      Redis                               Twilio Verify

Web assets and seller-owned HTTPS photos -> static hosting / object storage / CDN
```

Flutter screens use ChangeNotifier providers, explicit model mapping, a common API client, and GoRouter. Customer, seller, and administration experiences share one app; the API enforces roles and ownership independently of navigation. Android and iOS use secure token storage. Web tokens are memory-only, so refreshing the web app requires signing in again.

## Modules

| Path | Ownership |
| --- | --- |
| `lib/screens/auth`, `lib/providers/auth_provider.dart` | Verification, sessions, profile, addresses, favorites |
| `lib/screens/home`, `category`, `vendor`, `product` | Discovery and listing details |
| `lib/providers/cart_provider.dart`, `order_provider.dart` | Local cart, server quotes, retry-safe checkout and orders |
| `lib/screens/seller`, `lib/providers/seller_provider.dart` | Business onboarding, catalog and fulfillment |
| `lib/screens/admin` | Application review |
| `lib/screens/profile`, `legal`, `tracking` | Account deletion, hosted policies, actual order events |
| `backend/src/routes/auth.ts`, `middleware/auth.ts` | Account verification and request authorization |
| `backend/src/routes/buyer.ts`, `seller.ts`, `applications.ts` | Business ownership and approval |
| `backend/src/routes/catalog.ts`, `favorites.ts`, `addresses.ts` | Read catalog and customer-owned resources |
| `backend/src/routes/orders.ts`, `lib/pricing.ts`, `lib/order-lifecycle.ts` | Quotes, inventory, order transitions |
| `backend/src/lib/otp.ts`, `redis.ts`, `socket.ts` | External verification and multi-instance coordination |
| `backend/prisma/schema.prisma`, `migrations/` | Persistence contract and ordered schema evolution |

The desktop platform scaffold directories remain in the repository but are not supported distribution targets in this release process. Generated files, migrations, dependency locks, and tests are not expendable release clutter.

## Business and Catalog

A customer opens a business at a declared premises. Its storefront starts unapproved. An administrator reviews the application and real business details before the public catalog exposes it. Changes to sensitive business identity details require another review. Product removal archives availability so order history is preserved.

Products support food and boutique attributes, shelf life, expiry, dispatch lead time, wholesale tiers, minimum order quantity, case-pack size, and finite stock. Store and product images currently use seller-supplied URLs; there is no integrated image upload, scanning, transformation, or moderation pipeline. Administrative verification is manual and does not establish regulatory compliance by itself.

## Checkout and Fulfillment

1. The API verifies address ownership, seller approval/open state, same city and exact pincode, product ownership/availability, expiry, quantity rules, variants, and stock.
2. A quote computes authoritative totals and hashes the relevant request, items, address, and prices. Product prices are GST-inclusive; tax is extracted, not charged twice. Calculations round to integer paise, although existing monetary database columns remain floating-point and should migrate to integer minor units or fixed decimals before advanced settlement accounting.
3. The customer confirms the quote. A UUID idempotency key and request hash prevent retrying the same checkout from creating a second order.
4. A serializable PostgreSQL transaction conditionally reserves stock and creates the order, items, immutable address snapshot, and initial event. Stale prices and conflicting stock reservations fail instead of silently changing the purchase.
5. Sellers explicitly move orders through PLACED, CONFIRMED, PREPARING, OUT_FOR_DELIVERY, and DELIVERED. Delivery requires acknowledgement that cash was collected. Cancellation restores finite stock once; customers can cancel only before confirmation.
6. Authenticated sockets notify authorized users; clients can reload persisted events. Redis Pub/Sub is not a durable delivery guarantee. There is no synthetic courier movement, automatic status timer, or integrated dispatch fleet.

Current fee policy is coded in `lib/pricing.ts`: delivery and platform fees require operator approval before release. Single-seller COD checkout does not implement a payment ledger, commissions, payouts, GST invoice issuance, refunds, chargebacks, multi-seller carts, or nationwide logistics.

## Security and Data Lifecycle

SMS verification goes through Twilio Verify. Provider failures fail closed. Production startup rejects missing verification/Redis configuration, weak JWT configuration, and non-HTTPS CORS origins. Rate limiting is shared across replicas. Tokens, credentials, and verification codes must not appear in logs.

Protected API requests re-check the current account and role. Socket subscriptions check order access. Account deletion requires reauthentication, blocks unresolved orders, removes favorites and activity data, deactivates the storefront, and anonymizes the account. Order-linked addresses and transaction records are retained; the operator must define lawful reasons, duration, restricted access, and eventual purge procedures. Automated time-based retention cleanup is not implemented.

Secrets belong in the host's secret manager, not Flutter build defines. Flutter defines are public configuration. Administrator MFA, password recovery, refresh-token rotation, session management, a dedicated moderation audit ledger, and independent penetration testing remain release/security work to evaluate before broad public access.

## Scaling Boundaries

Use a managed PostgreSQL primary with backups/PITR and a private connection path. Tune the total connection budget across API replicas. Redis provides shared throttling and authenticated socket fan-out, not the database of record. WebSockets avoid the Socket.IO polling sticky-session requirement, but ingress must support upgrade headers and appropriate timeouts.

Start with measured API capacity and managed ingress. Add replicas after checkout concurrency, Redis failure/recovery, and reconnect tests. Catalog queries and seller lists need pagination/search work before large catalogs; do not assume a bounded home feed makes every query scalable. Later asynchronous email, push, media processing, or payment reconciliation should use a durable worker queue and transactional outbox where correctness requires it. Kafka is not a prerequisite and is not integrated.

## Etsy Reference

Etsy is useful for seller identity, authentic photography, clear processing times, and accountable shop policies. Nestly's FMCG and local food model is different and must have its own permitted-products and operational rules; Etsy's resale restrictions should not be copied blindly. No Etsy catalog, photos, or proprietary design was imported. Reference: [Etsy Seller Policy](https://www.etsy.com/legal/sellers/).
