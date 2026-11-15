> **Note:** the brand was renamed **Nestly → Tamarin** on 2026-11-14, after this review was written; file paths and code names below use the pre-rename name.

# Full-Project Code Review — 2026-11-14

Every tracked source file was read line-by-line (Flutter `lib/`, backend `backend/src/`, Prisma schema + migrations, tests, CI, deploy configs, docs, platform configs). Findings are consolidated from 12 per-area audits. Severity: **P0** = blocker, **P1** = major, **P2** = minor, **P3** = nit.

---

## P0 — Must fix before anything else

### 1. Razorpay webhook can never succeed — online payments are broken end-to-end
`backend/src/app.ts:53` mounts `/payments` **before** `express.json()` (line 54) to preserve the raw body, but **no `express.raw()` exists anywhere in the backend** (verified by grep). In Express 5, `req.body` stays `undefined`, so `verifyWebhookSignature` (`backend/src/lib/payments.ts:93-99`) calls `createHmac().update(undefined)` → TypeError → **500 on every genuine webhook**.

Consequence chain (verified across `routes/payments.ts`, `routes/orders.ts`, `lib/order-lifecycle.ts`):
- `payment_link.paid` is the only path that marks an online order PAID (`routes/payments.ts:42`) → paid orders stay `PENDING` forever.
- `expireStaleOnlineOrders` (`lib/order-lifecycle.ts:120-151`) then cancels them after 30 minutes and restores stock — **the customer has been charged for a cancelled order**.
- `refundPayment` is never called (see P0-2), so no money comes back.

Fix: `app.use('/payments', express.raw({ type: 'application/json', limit: '256kb' }), paymentsRouter);` plus webhook tests (valid signature → PAID; bad signature → 401; replay → idempotent).

### 2. Refunds are never executed — dead code, and the sweep records the wrong status
- `refundPayment()` (`backend/src/lib/payments.ts:76-90`) has **zero call sites**. `REFUND_DUE` / `refundAmount` are written on cancellation (`lib/order-lifecycle.ts:106-111`) but nothing ever calls the Razorpay refund API.
- Worse: the 30-minute sweep sets `paymentStatus: 'CANCELLED'` (not `REFUND_DUE`) for expired unpaid-looking online orders (`lib/order-lifecycle.ts:120-151`) — combined with P0-1, a *paid* order gets cancelled with no refund debt even recorded.
- `fetchLink()` (`lib/payments.ts:68`) — the reconciliation helper — is also never called.

Fix: fix P0-1, then make the sweep check `fetchLink` before cancelling, set `REFUND_DUE` when a paid link exists, and add a settlement job that executes refunds and marks `REFUNDED`.

### 3. Flutter compile blocker — Orders screen doesn't import ApiClient
`lib/screens/orders/orders_screen.dart:100` calls `context.read<ApiClient>()` but `services/api_client.dart` is not in the file's imports (lines 1–11 verified). This is an "Undefined class" compile error that breaks the **entire orders screen file**, including the Pay Now flow. Fix: add the import. (Also implies CI's Flutter build job wasn't catching it — check the analyze job.)

---

## P1 — Major (fix before launch)

### Backend

4. **No logout endpoint, no token revocation, no refresh tokens.** Single 7-day JWT (`lib/auth.ts:23-31`, `env.ts:75`); `requireAuth` never checks revocation; the Socket.IO 60s session check re-verifies the same static token. Logout / ban / deletion can't invalidate an issued token. → short access tokens + rotating refresh tokens (hashed), session-version check in `requireAuth` + `socket.ts`.

5. **MOQ / case-pack / slab-pricing bypass via duplicate lines.** `routes/orders.ts:51-63` validates MOQ and case pack and computes slab price **per line**, while stock and maxOrderQuantity use the aggregated quantity. Splitting qty 10 into two lines of 5 bypasses `minOrderQuantity: 10`, dodges case packs, and earns the wrong tier. → group items by productId before validation/pricing.

6. **Payment-link races with no reconciliation.** `POST /orders/:id/pay` (`routes/orders.ts:200-233`) is check-then-act: two concurrent calls create two live Razorpay links; the webhook discards payment on the superseded link (`routes/payments.ts:36`) — money captured, order unpaid. Also the webhook vs. 30-min sweep boundary race drops payments permanently. → conditional `updateMany` on `paymentLinkId: null`, treat mismatched-link payments as refund-due, add a `fetchLink` reconciliation sweep.

7. **Webhook responds 200 before processing and swallows all errors.** `routes/payments.ts:22` sends `{ok:true}` first; lines 61-62 wrap processing in an empty `catch {}`. Razorpay sees success and never retries → transient DB failure permanently loses the payment. → process, then respond; 5xx on failure; log.

8. **Notification worker can crash the whole API.** `lib/notification-worker.ts:43-82` — the poll has `try/finally` with **no catch**, invoked as `void this.drain()`; any transient Prisma error becomes an unhandled rejection that kills the process (Node ≥15). Also: outbox rows claimed non-atomically (double-send at scale), `ORDER_PLACED` notification is never queued (`routes/orders.ts:119-130` creates orders without passing through `transitionOrder`).

9. **Rate limiting breaks in production topology.** `TRUST_PROXY_HOPS` defaults to 0 (`lib/env.ts:78`) while `app.ts:36-38` says you sit behind Cloudflare/LB → `req.ip` is the proxy IP for everyone → the 300/min and 30/15min limiters throttle **all users collectively**. And `disableOfflineQueue: true` (`lib/redis.ts:7`) makes any Redis blip fail-closed → **every `/api` request 500s**. → require correct hop count in prod validation; `passOnStoreError: true` on the limiters.

10. **Unpaid online orders can be advanced to OUT_FOR_DELIVERY** (`lib/order-lifecycle.ts:46-54` — only DELIVERED checks PAID), then wedge (no cancel allowed from OUT_FOR_DELIVERY). → block non-COD transitions past PLACED unless PAID.

11. **Application status transitions unvalidated + racy.** `routes/applications.ts:241-288` allows APPROVED→PENDING (demoting an approved vendor) and REJECTED→APPROVED; the read happens outside the transaction (last-write-wins on concurrent admin actions). → state machine + conditional update / Serializable tx.

12. **KYC PII survives account deletion.** Deletion matches applications by `user.phone` = `'+91 9876543210'` (`routes/auth.ts:141`) but applications store the raw `9876543210` (`routes/applications.ts:111`) → GSTIN/PAN/FSSAI of the applicant survive erasure. → normalize phones on both sides.

13. **Production env validation gaps.** `lib/env.ts` requires Twilio/Redis/CORS but not Razorpay creds, `UPLOAD_DIR`, `MEDIA_BASE_URL` (payments silently 503 at runtime), and never enforces DB SSL in prod.

14. **Uploads are broken in the production deployment.** `deploy/nginx.conf.template` has **no `location /media/`** block → every uploaded image resolves to the SPA's index.html. `docker-compose.production.yml:13-14` runs `read_only: true` with **no volume for uploads** → writes fail (EROFS) or vanish. `DEPLOY.md` also omits every new env var (RAZORPAY_*, UPLOAD_DIR, MEDIA_BASE_URL, PLATFORM_COMMISSION_RATE, DEFAULT_CITY).

15. **Vendor PII leaks publicly.** `lib/serializers.ts:78-121` exposes `businessAddress`, `pincode`, `lat/lng` for every vendor (the seller's *home* for HOME_COOK types) and `kycStatus`, `bankVerified`, `ownerId` on all public catalog responses. → public serializer variant without internal fields.

16. **B2B GST invoices are incomplete.** `buyerGstin`/`invoiceRequired` exist in the schema but are never collected (`routes/orders.ts:20-29`); the invoice HTML has no buyer GSTIN, no HSN column, no CGST/SGST split; per-line tax extraction drifts ±1p; fees untaxed.

### Flutter client

17. **`paymentStatus` / `paymentUrl` are never parsed.** `lib/services/api_mappers.dart:510-544` — so the post-checkout online-payment redirect (`checkout_screen.dart:505-509`) can never fire and every order shows "Pay now" (`orders_screen.dart:236`), including paid ones.

18. **No 401 handling / token refresh in the API client** (`lib/services/api_client.dart:78-115`) — expired sessions surface raw "Unauthorized" errors everywhere except `/api/auth/me`.

19. **Socket listener leaks & reconnect loses tracking.** `socket_service.dart` accumulates duplicate handlers on every dashboard load / placed order; `unsubscribeOrder` is never called; after reconnect, `tracking:subscribe` is never re-emitted (connection-scoped rooms silently lost).

20. **Splash never waits for session restore** (`splash_screen.dart:30-32` — fixed 2200ms then `go('/home')`, ignoring `auth.restoring`), and **the router has no auth/role guards** (`app_router.dart`) — deep links into `/checkout`, `/seller/*`, `/admin/*` render while logged out; every screen self-guards.

21. **Order detail fabricates a timeline.** `orders_screen.dart:291-300,424-476` derives a static 5-step stepper from current status instead of rendering the real `order.events` history (which the tracking screen does correctly).

22. **Seller store settings first save always fails.** `seller_onboard_screen.dart:316-318` always sends empty `imageUrl`/`coverUrl`, which the server's HTTPS-URL schema rejects for every new vendor.

23. **Seller approval status is never surfaced.** A brand-new unapproved vendor lands in a fully functional dashboard with no "under review" banner, no rejection reason (`adminNotes` never exposed), no suspended state. **Bank/payout fields have no UI anywhere** (model + server support exist).

24. **Demo image pre-filled on every new product.** `seller_products_screen.dart:214-216` defaults to an Unsplash stock photo.

25. **Fake location & hardcoded taxonomy.** Home header shows hardcoded "Madhapur, Hyderabad" with a fake location-picker chevron (`home_screen.dart:56-87`); hub navigation is hardcoded client-side with unsplash imagery and raw `'cat_food'`-style ID coupling (`hub_screen.dart`, `category_tree.dart`); search sort chips do nothing on the Items tab; "Popular searches" is static.

26. **Admin screen can't actually review KYC.** `admin_applications_screen.dart:291-304` renders presence chips (`'GSTIN'`, `'PAN'`, `'FSSAI'`) — never the values; approve/reject sends no reason and has no confirmation.

27. **No refund/cancellation policy anywhere.** Zero occurrences of "refund" in `lib/`; cancel dialog has no refund wording for online payments; cancel is fire-and-forget (`orders_screen.dart:322-327`); bill shows "Total paid" on unpaid orders.

### Tests & CI

28. **The money path has zero tests** — no test touches the Razorpay webhook or `/pay` flow. CI has no Redis (prod requires it), the integration suites silently skip when `TEST_DATABASE_URL` is missing (an all-green run with zero integration coverage is possible), and the backend has no ESLint at all.

---

## P2 — Minor (fix before or shortly after launch)

| # | Where | Issue |
|---|---|---|
| 29 | `middleware/auth.ts:40-54` | `optionalAuth` trusts JWT payload without DB revalidation (deleted users populate `req.user`) |
| 30 | `routes/payments.ts:39-45` | Payment on already-cancelled order silently dropped (no REFUND_DUE) |
| 31 | `serializers.ts:194`, `order-lifecycle.ts:74-75` | Float money artifacts in API responses; commission math in rupee floats |
| 32 | `schema.prisma` (Order/Product/Ledger) | Money stored as `Float`; consider `Decimal(12,2)` or integer paise |
| 33 | `order-lifecycle.ts:106-111` | `refundAmount` written outside the transaction (lost on crash) |
| 34 | `routes/orders.ts:175` | Stale-order sweep runs inline on every order-list GET (latency under load) |
| 35 | `buyer.ts:86-112` | Concurrent `open-business` double-submit → raw 500 (P2002 uncaught) |
| 36 | `seller.ts:394-398` | `status` query param blind-cast → 500 on invalid value |
| 37 | `media.ts` | No per-user upload quota (disk-fill DoS); uploads not linked to owner records |
| 38 | `applications.ts:86-104` | Unbounded `message`/`documents` JSON on a public endpoint; admin XSS risk; needs stricter rate limit |
| 39 | `catalog.ts` | No cursor pagination (fixed take 24–120, page 2 impossible); query-string type confusion → 500s |
| 40 | `schema.prisma` init migration | Missing indexes: `Address.userId`, `OrderItem.orderId`, `OrderEvent.orderId`, `Order.paymentLinkId`; `Favorite.vendorId` has no FK |
| 41 | `schema.prisma:64-65` | Soft-deleted users permanently block their email/phone (unique without partial index) |
| 42 | `schema.prisma:102-113` | Category "tree" is flat — no `parentId` (hub hierarchy is client-hardcoded instead) |
| 43 | `schema.prisma:139,158` | No DRAFT/SUSPENDED seller states (`kycStatus` comment-enum, `isApproved` boolean) |
| 44 | `schema.prisma:262` | Refunds are a scalar — no refund records model |
| 45 | `render.yaml` | Omits RAZORPAY_*/UPLOAD_DIR/MEDIA_BASE_URL; preDeploy doesn't seed categories |
| 46 | `auth_provider.dart:244-275` | `verifyPhoneOtp` returns success without a token; same for email login/register |
| 47 | `auth_provider.dart:224+` | Redundant `/health` pre-check before every auth request (latency + TOCTOU) |
| 48 | `cart_provider.dart:277` | Vendor PII (PAN/GSTIN/FSSAI/bank) persisted unencrypted in SharedPreferences via cart snapshot |
| 49 | `app_constants.dart:11-14` | Client fee constants duplicate server pricing (cart vs checkout totals can disagree) |
| 50 | `models` | Money is `double` end-to-end in Flutter; no structured net-weight field (Legal Metrology) |
| 51 | `models/vendor.dart:125-177` | `Vendor.copyWith` silently resets `isApproved: false` |
| 52 | `api_mappers.dart:519` | Missing `createdAt` in order events crashes the whole order parse |
| 53 | `api_client.dart:111` | Fragile error extraction; `{message: ...}` shape ignored |
| 54 | `seller screens` | Zero format validation on GSTIN/PAN/FSSAI/pincode (raw Zod errors); image URL check accepts `http://`; GST rate uncapped client-side |
| 55 | `seller_products_screen.dart` | Food compliance fields never required for food products; no MRP ≥ price check; past expiry accepted; veg flag shown/applied to sarees |
| 56 | `seller_orders_screen.dart:105-122` | Seller can't cancel after CONFIRMED (server allows CONFIRMED/PREPARING → CANCELLED) |
| 57 | `addresses_screen.dart` | No serviceability check; hardcoded `'Hyderabad'` city default; delete without confirmation |
| 58 | `legal_screens.dart` | Legal pages are external-link stubs; no in-app grievance-officer/contact info |
| 59 | `orders_screen.dart:271-289` | Order detail never fetches by id — cold deep link shows "Order not found" forever |
| 60 | veg_badge.dart:26 | Non-veg badge is a red rectangle, not the FSSAI brown triangle; no Semantics |
| 61 | product_card.dart:136-149 | No out-of-stock visual state — ADD stays tappable; stepper has no disabled/max feedback |
| 62 | product_card.dart:140 | Card ADD adds a full MOQ per tap (cart adds case-pack step) — inconsistent semantics |
| 63 | `socket_service.dart:82-90` | Client listens for `tracking:location`, which the server never emits; `riderLat/Lng` dead payload (serializers.ts:248) |
| 64 | `schema.prisma:341-350`, cart/checkout | Coupon scaffolding (model + zero-UI state + discount row) with no route — dead feature |
| 65 | checkout retries | Idempotent replay returns a CANCELLED order on retry after payment failure (client must mint a new key) |

## P3 — Nits (selected)

- `middleware/error.ts` leaks raw `err.message` for 4xx; no `headersSent` guard; Prisma 500 logs drop message/stack.
- `env.ts:107-112`: `CORS_ORIGIN='*'` in prod crashes startup with a raw `new URL('*')` TypeError instead of the intended message.
- `index.ts`: shutdown races; no `server.on('error')` for EADDRINUSE; catch message blames Postgres even when Redis failed.
- `bcrypt` cost 10; `jwt.verify` without `algorithms` pin (defense-in-depth).
- Admin screen dev leftovers (`'(admin@nestly.app)'` hint, Prisma-table phrasing, raw DB ids in cards).
- "Home business / homemade" positioning leftovers in live strings (`seller_entry_screen.dart:101,241,245,328`, `seller_dashboard_screen.dart:264`); dead screens `BecomeSellerScreen` / `SellerOnboardScreen` contain the worst copy ("worldwide", hardcoded Madhapur) and are unreachable.
- Dead code: `become_seller_screen.dart` (unrouted), most of `seller_onboard_screen.dart` (endpoint 410), `socket_service.offAll`, `banner_item.actionRoute`, `product.extras`, unused `gstPercent`/anim constants, unused `flutter_staggered_grid_view` dep.
- `pubspec.yaml` google_fonts fetched at runtime — bundle Poppins for offline first launch.
- No web session persistence (tokens memory-only on web — users logged out on refresh; intentional but document it).
- `widget_test.dart` asserts only the app name; no widget tests for ProductCard/stepper/veg badge/replace-cart dialog.
- macOS/windows/linux runners still carry `com.example.homeFoods` / `home_foods` branding; `linux/CMakeLists.txt:10` has `com.example.nestly`.
- `backend/Implemented_thr_codex.md` (a pasted chat transcript) shouldn't ship in the repo; `backend/uploads/*` should be gitignored beyond `.gitkeep`.
- Accessibility gaps across screens: no Semantics on veg badge, stepper, rating chips, decorative icons; several 10–11px fonts.

---

## Requirement coverage summary

| Requirement | Status |
|---|---|
| Multi-category local-business marketplace (food, pickles, sweets, cloud kitchen, boutique, FMCG wholesale) | ✅ implemented end-to-end (schema → routes → UI) |
| Sellers from business premises (not home-only) | ✅ `premisesType` captured; ⚠️ "homemade" copy leftovers (P3) |
| KYC/FSSAI/GST/PAN collection + admin approval | ⚠️ collected & admin-reviewed, but admin can't see values (26), no reason capture, no suspended state (43), status transitions unvalidated (11) |
| Bank/payout fields | ❌ backend only — no UI (23) |
| Server-authoritative checkout (prices, stock, MOQ, case packs, slabs, serviceability) | ✅ core solid; ❌ duplicate-line bypass (5) |
| COD + online payments | ⚠️ implemented but **P0-1/P0-2 make online payments dangerous**; Flutter can't even parse payment status (17) |
| Order lifecycle, stock restore, tracking via real history | ✅ state machine solid; ⚠️ unpaid-order wedge (10), fabricated detail timeline (21) |
| Invoices | ⚠️ issued with numbering; not B2B-GST compliant (16) |
| Reviews (verified purchase only) | ✅ delivered-order gating, one per item, admin moderation |
| Media uploads | ✅ magic-byte validated; ❌ broken in prod deploy (14), no quotas (37) |
| Notifications (outbox + worker) | ⚠️ outbox solid; worker can crash the API (8); PLACED never queued; no client inbox UI |
| No demo/MVP leftovers, no fixed OTPs, no simulated tracking | ✅ Twilio-only OTP, no fake courier; ⚠️ Unsplash product prefill (24), hardcoded home location/hubs (25), coupon scaffolding (64) |
| Auth security | ⚠️ Twilio Verify fail-closed ✅, but no logout/revocation/refresh (4), 7-day tokens |
| Docs accuracy | ❌ README/ARCHITECTURE/RELEASE_READINESS/DEPLOY are stale vs the commerce commit (they claim no payments/uploads/invoices/reviews — all now exist); only AWS_DEPLOYMENT.md is current |

**Verified-good (no action needed):** checkout idempotency (`@@unique(customerId, idempotencyKey)` + requestHash 409), Serializable stock decrement (race-free), quote-hash binding, schema↔migrations exact 1:1 sync, timing-safe HMAC comparison (once the body bug is fixed), seed is reference-categories-only, create-admin has no backdoor, `.env.example` clean, no keystores/`.env` committed, release signing refuses debug fallback, `in.nestly.app` consistent across Android/iOS, docker hardening (non-root, read-only, no-new-privileges), TLS config in nginx.

---

## Rename research — domain availability

Checked 136 species names against the authoritative registries via RDAP (the same registry data GoDaddy uses; final premium-price confirmation happens in the GoDaddy cart). **Every single-word species `.com` that resolved is already registered (0 of 136 available)** — common-species `.com`s are gone. On `.in`, 22 names are unregistered (standard GoDaddy `.in` retail ≈ ₹699–999/yr, within budget):

Available `.in`: firefinch, tamarin, tarsier, curlew, numbat, bilby, quoll, lory, munia, waxbill, tenrec, cuscus, dunnart, kowari, agouti, viscacha, fulmar, pratincole, degu, danio, crake, sifaka.

Shortlist (brandability × global reach × food/marketplace fit):
1. **Firefinch** — fire + finch; cooking warmth + bird; two common English words, easy globally. *(recommended)*
2. **Tamarin** — monkey; sounds premium; echoes "tamarind" (food recall); easy to pronounce in India & abroad.
3. **Tarsier** — famous big-eyed primate (meme reach); slightly harder spelling.
4. **Bilby** — short & cute; lesser-known outside Australia.
