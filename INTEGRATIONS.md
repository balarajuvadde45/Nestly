# Tamarin — Integrations You Must Do (Owner Checklist)

Everything the **code already handles** is marked ✅ CODE-READY. Everything you must do from your side has step-by-step instructions. Two companion guides: `awshosting.md` (infrastructure) and `docs/CODE_REVIEW.md` (known issues).

**How the big apps do it (verified against public sources):** Swiggy and Zomato do not process payments themselves — they integrate **once** with a licensed payment aggregator (primarily **Razorpay**, with Cashfree/PayU as smart-routing alternatives via Razorpay Optimizer / Cashfree FlowWise). The aggregator handles UPI/cards/netbanking/wallets, **split settlements** to each seller (Razorpay *Routes*), and reconciliation (Smart Collect). Tamarin's backend follows the same pattern with Razorpay Payment Links + a seller earnings ledger, so your job is mostly account setup, keys, and webhooks — no payment code to write for launch.

---

## 1. Online payments — Razorpay (required for "Pay Online")

✅ CODE-READY: Payment Link creation (`backend/src/lib/payments.ts`), signed webhook with timing-safe HMAC verification + amount check + superseded-link refund protection (`backend/src/routes/payments.ts`), reconciliation sweep that confirms paid-but-missed-webhook orders, automatic refund execution for cancelled paid orders (`backend/src/lib/order-lifecycle.ts`), 10% platform commission recorded to the seller ledger on delivery.

**Your steps:**
1. Create a Razorpay account at <https://razorpay.com> → complete **KYC** (PAN, GSTIN, bank account, business proof — takes 1–3 days).
2. Dashboard → **Settings → API Keys → Generate Test Keys**. Put them in `backend/.env`:
   ```
   RAZORPAY_KEY_ID=rzp_test_xxxxxxxx
   RAZORPAY_KEY_SECRET=xxxxxxxxxxxx
   RAZORPAY_WEBHOOK_SECRET=my_webhook_secret_value
   ```
3. Dashboard → **Settings → Webhooks → Add New Webhook**:
   - URL: `https://api.<your-domain>/payments/webhook`
   - Secret: the same `RAZORPAY_WEBHOOK_SECRET` value
   - Active events: **payment_link.paid**, **payment_link.payment.failed**, **refund.processed**
4. Test with test cards/UPI (`success@razorpay`) end-to-end: place order → open payment URL → pay → order flips to PAID → seller confirms → deliver → ledger credit.
5. After KYC approval, switch to **Live keys** and add the production webhook.
6. (Later, when volume grows) Enable **Razorpay Route** splits so seller settlements happen automatically instead of via your manual payouts from the earnings ledger.

## 2. SMS OTP — Twilio Verify (required for login/signup)

✅ CODE-READY: Twilio Verify integration, fail-closed when unconfigured, per-phone rate limits.

**Your steps:**
1. Buy an Indian SMS-capable number / enable **Twilio Verify** in your Twilio account (or use an India-focused alternative like **MSG91** — that would need ~50 lines changed in `backend/src/lib/otp.ts`).
2. Create a **Verify Service** → copy the Service SID.
3. `backend/.env`:
   ```
   TWILIO_ACCOUNT_SID=ACxxxxxxxx
   TWILIO_AUTH_TOKEN=xxxxxxxx
   TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxx
   ```
4. India DLT registration: to SMS Indian numbers at scale you must register a **DLT header + templates** with a provider (Jio/Airtel DLT). Twilio Verify handles template wording internally but still needs a registered sender where applicable — confirm with Twilio support for India traffic.

## 3. Push notifications — Firebase Cloud Messaging (recommended day-1)

⚠️ PARTIAL: the notification outbox + worker exist; the FCM channel is a pluggable point (`backend/src/lib/notification-worker.ts` `deliver()`).

**Your steps:**
1. console.firebase.google.com → create project "Tamarin" → add Android app (`in.tamarin.app`) + iOS app + web app → download `google-services.json` (Android) / `GoogleService-Info.plist` (iOS).
2. Add the `firebase_messaging` Flutter package, wire token → backend (new small endpoint), and implement the `deliver()` FCM call using a service account (Firebase Admin SDK for Node).
3. This is the single biggest "feels like Swiggy" gap today — without it users only see updates while the app is open.

## 4. Location, maps & serviceability

✅ CODE-READY (dynamic, Swiggy/Zomato-style):
- **"Use my current location"** in the delivery-location sheet: device GPS (`geolocator`) → **reverse geocoding** via OpenStreetMap Nominatim → area/city/pincode auto-filled, saved with coordinates, header updates live. Web uses the browser Geolocation API (needs HTTPS in production — localhost is exempt).
- Pincode-list serviceability enforced server-side at quote time; addresses CRUD with validation; order address snapshots.

**Your steps (pick one):**
- **Day 1 (₹0):** nothing — GPS detection + Nominatim work out of the box. Keep the pincode-list serviceability model (sellers define serviceable pincodes; checkout refuses unserviceable ones).
- **Growth (recommended at scale):** swap the one function `lib/core/utils/geocoding.dart` to **Google Geocoding API** or **MapmyIndia** (better India accuracy, higher rate limits) and add a map picker for pin-dragging. Google: enable Geocoding API, put the key behind a backend proxy (never ship the key in the app).

## 5. Delivery/logistics (tracking + courier)

✅ CODE-READY: order status history IS the tracking (no fake GPS); sellers advance statuses manually. **Live rider tracking is NOT implemented** — the code intentionally has no simulated courier.

**Your options, in launch order:**
1. **Launch (₹0):** self-delivery — sellers mark statuses; customer sees status timeline. This is exactly how many local marketplaces start.
2. **Hyperlocal partners** (when you want rider tracking): **Shadowfax**, **Dunzo for Business**, **Porter**, **Blowhorn**, or **Delhivery Hyperlocal** — all expose APIs: create shipment → get rider assignment → rider location webhooks. You'll add a `delivery` module that (a) creates a shipment when a seller taps "Out for delivery", (b) stores rider coordinates, (c) feeds `tracking:location` over Socket.IO (the client already has a listener for it).
3. **Nationwide parcels** (boutique/FMCG beyond the city): Delhivery/Bluedart/Shiprocket APIs with label generation + COD remittance.

## 6. Media storage (seller images)

✅ CODE-READY: uploads with magic-byte validation to local disk, served at `/media`. On AWS this must move to durable storage.

**Your steps:** either mount a persistent EFS volume at `UPLOAD_DIR` (simplest) or (better) switch `MEDIA_BASE_URL` to an S3 bucket + CloudFront — see `awshosting.md` §7. No code change needed if you keep disk + EFS; S3 needs a small upload-path change (documented in awshosting.md).

## 7. Email (invoices, passwordless receipts) — optional day-1

⚠️ Invoices are generated as HTML at `/api/orders/:id/invoice` (customer can view/share). To email them: AWS SES (cheapest) → verify domain, create SMTP credentials, plug into the notification worker's email channel.

## 8. Store listings (Google Play / Apple App Store)

**Your steps:**
1. **Google Play Console** account ($25 once) → create TWO apps from the TWO repos:
   - "Tamarin" — package `in.tamarin.app` ← build in this repo (`flutter build appbundle --release`)
   - "Tamarin Partner" — package `in.tamarin.partner` ← build in `../Nestly_Seller`
2. Each listing needs: privacy policy URL, terms URL, refund/cancellation policy (add a refund policy page + route — currently missing, see CODE_REVIEW #27), app icons (already generated), screenshots, data-safety form (collects: name, phone, email, address — declare accordingly).
3. **Apple Developer** account ($99/yr) → same two apps with bundle IDs `in.tamarin.app` / `in.tamarin.partner` (iOS flavors need Xcode schemes — see §9).
4. Account deletion must be reachable in-app (✅ both apps have `/account/delete`).

## 9. iOS, on macOS (one-time)

Each repo builds its own iOS app — no flavors needed:
1. Open `ios/Runner.xcworkspace` in Xcode for each repo, set the team, and set `PRODUCT_BUNDLE_IDENTIFIER`: `in.tamarin.app` (Nestly) / `in.tamarin.partner` (Nestly_Seller) plus display name (Tamarin / Tamarin Partner).
2. `flutter build ipa --release` in each repo.

## 10. Domain, policies & compliance (before store submission)

1. Buy **tamarin.in** (confirmed available 2026-11-14; ~₹699–999/yr on GoDaddy) — then point it per `awshosting.md`.
2. Host three pages on the web app: **Privacy Policy**, **Terms**, **Refund & Cancellation policy** (refund policy page is missing in code — required by Play/App Store for apps with paid orders; content must cover COD + online refunds to source within N business days).
3. Publish **grievance officer** name/contact (India IT Rules) on the contact page.
4. For sellers: collect FSSAI license (food), GSTIN where applicable — ✅ the app already captures these in onboarding; admin approves.
5. Payment regulations: with Razorpay you are the *marketplace*; money flows to sellers via Razorpay settlement — no separate payment-aggregator license needed at this scale. Keep `PLATFORM_COMMISSION_RATE` documented in your terms.

## 11. What to configure per environment (single list)

```env
NODE_ENV=production
DATABASE_URL=postgresql://...sslmode=require   # from RDS (awshosting.md §4)
REDIS_URL=redis://...                          # from ElastiCache (§5)
JWT_SECRET=<64+ random chars>                  # openssl rand -hex 32
JWT_EXPIRES_IN=1d
CORS_ORIGIN=https://tamarin.in,https://partner.tamarin.in
TRUST_PROXY_HOPS=2                             # ALB (+CloudFront if used)
DEFAULT_CITY=Hyderabad
TWILIO_ACCOUNT_SID=... / TWILIO_AUTH_TOKEN=... / TWILIO_VERIFY_SERVICE_SID=...
RAZORPAY_KEY_ID=... / RAZORPAY_KEY_SECRET=... / RAZORPAY_WEBHOOK_SECRET=...
PLATFORM_COMMISSION_RATE=10
UPLOAD_DIR=/app/uploads                        # EFS mount or S3-backed
MEDIA_BASE_URL=https://media.tamarin.in        # CloudFront/S3 or /media route
# COD-only launch without payments: REQUIRE_ONLINE_PAYMENTS=false
```

The production server **refuses to boot** if any required value above is missing — that's intentional; it fails fast instead of failing customers.
