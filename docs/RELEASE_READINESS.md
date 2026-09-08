# Release Readiness

Status: **not yet cleared for public store submission**. Removing prototype behavior is necessary but does not replace infrastructure, business operations, regulatory review, or acceptance testing. This document separates implemented code from missing configuration and missing capabilities.

## Implemented Release Hardening

- Real SMS verification with no fixed-code bypass; public registration cannot grant seller/admin privileges.
- Current-account authorization, protected socket subscriptions, shared production rate limiting, redacted logs, and restricted public seller serialization.
- Server quotes, idempotent checkout, atomic stock reservations, quantity/expiry checks, immutable address snapshots, and explicit order transitions.
- Human seller approval, stock-safe product archiving, persisted favorites, and reauthenticated account deletion.
- Removed bundled marketplace records, fabricated coupon discounts, simulated courier tracking, and unrelated community screens from the runtime.
- HTTPS release configuration, native secure token storage, Android signing checks, iOS identifiers, and Nestly launcher artwork.
- Compiled non-root API image, separate migrations, TLS reverse-proxy configuration, reference-only seed, and CI checks.

## Owner Setup Before Launch

- Confirm business entity, launch area, permitted seller categories, brand ownership, and `in.nestly.app` identifiers.
- Supply production domains, database, Redis, SMS provider, secret management, monitoring, and backup ownership. See [Deployment](../DEPLOY.md).
- Publish actual privacy, terms, refunds/cancellation, support, and data-deletion information. Explain any transaction retention accurately. Have qualified local advisers review food, packaging, taxation, marketplace, and privacy obligations; fields in the database do not establish compliance.
- Establish seller verification, product moderation, food safety escalation, delivery, cancellation disputes, cash reconciliation, and customer support procedures with named operators.
- Create Google Play and Apple developer accounts, arrange native signing and secure key recovery, and prepare accurate store metadata/screenshots and privacy disclosures.
- Populate real approved sellers and photos. Audit any existing database before import. Historical sample accounts are not deleted by migrations; rotate/revoke insecure legacy credentials rather than carrying them into production.

## Remaining Product Work

The current usable transaction scope is local, single-seller COD. Do not market or enable the following as connected services until they are implemented and tested:

| Capability | Current limit / required work |
| --- | --- |
| Online payments and settlements | No provider checkout, signed webhooks, refund ledger, commissions or seller payouts |
| Delivery coverage | Exact seller pincode and city only; no distance engine, shipping rates, pickup scheduling or courier integration |
| Returns and support | Listing return fields exist; no complete case/refund workflow or support ticket integration |
| Invoicing | Tax-inclusive quote calculation exists; no compliant invoice issuance or financial reconciliation system |
| Media | HTTPS image links only; owner must provide hosting, rights checks and moderation; no upload pipeline |
| Notifications | Live sockets/polling while app is open; no durable background FCM/APNs or transactional email |
| Identity | No email/password recovery, administrator MFA, refresh-token rotation or device-session console |
| Large catalog/history | Customer API pagination exists but UI history paging and large seller-list/search pagination need work |
| Reviews and moderation | Do not represent seeded/legacy ratings as verified buyer reviews; a verified-purchase review/dispute workflow is not established |
| Retention | Anonymization exists; approved retention schedule, automated purge jobs, backup handling and request operations are still needed |

These are engineering gaps, not features that become operational simply by purchasing cloud accounts. Resolve the capabilities and controls required for your actual launch promise before opening ordering to the public.

## Acceptance Gates

- Apply migrations to a clean staging database, then rehearse an upgrade using a sanitized copy of any database intended for import. Confirm backups and perform a timed restore test.
- Test real SMS delivery, invalid/expired codes, throttling, sign-in, seller review, product changes, quotes, retries, stock contention, cancellation, delivery/cash confirmation, and deletion with real staging accounts.
- Verify isolation between unrelated buyers and sellers, revoked-account sessions, failed providers, Redis outages and reconnects, and multiple API replicas.
- Test slow/offline networks, app restarts during checkout, accessibility/text scaling, narrow phones, tablets, desktop browsers and browser refresh/deep links.
- Build a signed Android AAB and iOS IPA on configured native toolchains. Validate on physical Android/iOS devices and store testing tracks before production submission.
- Run dependency review, security testing, load tests with agreed traffic targets, operational alert drills, and a rollback rehearsal. Set a supportable capacity limit from measurements.
- Complete current store requirements in the actual consoles. Do not rely on an old target API number or assume repository changes guarantee approval.

## Local Verification Record

Run `node scripts/release-inventory.mjs` to regenerate `artifacts/release-inventory.json`. It records project paths, hashes, byte sizes, and text line counts, excluding secrets, dependencies, and build output. The inventory covers 255 files at this handoff; it is not a line-by-line semantic audit or a security certification.

The release-hardening work uses an isolated `nestly_test` PostgreSQL database, not the operator's production database. Local automated checks and their final results are recorded in the implementation handoff. Configured CI jobs are not evidence that remote CI or native store builds have passed.

Verification on 2026-09-09:

| Check | Result |
| --- | --- |
| Backend typecheck and compiled build | Passed |
| Backend unit and isolated PostgreSQL integration tests | 19 passed |
| Prisma migrations and schema comparison | Three migrations applied to test database; no schema difference |
| npm dependency audit | Zero reported vulnerabilities at check time |
| Flutter static analysis | Passed |
| Flutter unit/widget checks | 9 passed, including 320px, 390px and 1440px authentication layouts |
| JavaScript release web compilation | Passed with non-routable verification URLs; not a deployment artifact |
| Launcher artwork generator | Passed; generated brand image visually inspected |
| Release PowerShell syntax / Android manifest / iOS plist XML | Parsed successfully |
| Repository inventory | 255 files, no legacy authentication text warnings |

The optional WebAssembly dry-run was stopped after stalling; the successful JavaScript build used `--no-wasm-dry-run`. WebAssembly support is not claimed. Container/Nginx runtime validation, remote CI, store submissions, real SMS delivery and Redis multi-replica/load testing have not been completed here. A vulnerability scan is not a penetration test or a guarantee against unknown vulnerabilities.

Browser automation was unavailable in this workspace session. Android SDK was not installed and iOS requires a Mac, so real browser acceptance, Android release compilation/signing, iOS signing and physical-device testing remain unverified. No production infrastructure was provisioned and no store submission was made.

## Submission References

- [Flutter Android release guide](https://docs.flutter.dev/deployment/android)
- [Flutter iOS release guide](https://docs.flutter.dev/deployment/ios)
- [Google Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
- [Apple in-app account deletion guidance](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play target API policy](https://support.google.com/googleplay/android-developer/answer/11926878)

The app exposes an authenticated deletion flow at `/#/account/delete`. Publish its deployed web URL and appropriate explanatory/support content for users without the app. Check retained transaction data and unresolved-order handling with the published policy and store reviewers before submission; code alone does not certify compliance.
