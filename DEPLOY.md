# Deployment and Operations

Read [Release Readiness](docs/RELEASE_READINESS.md) before enabling public orders. No infrastructure or store account is provisioned by these files.

## Recommended Starting Architecture

Use a managed API host, managed PostgreSQL with backups and point-in-time recovery, managed Redis, a static web host/CDN, Twilio Verify, and object storage/CDN for genuine seller images. This is an engineering recommendation for this codebase, not a provider price or capacity guarantee.

| Service | Required now | Purpose |
| --- | --- | --- |
| PostgreSQL | Yes | Accounts, businesses, inventory, orders and events |
| Redis | Yes in production | Shared throttling and Socket.IO fan-out |
| Node API host | Yes | Run the compiled Express service |
| HTTPS web hosting / CDN | Yes for web | Serve Flutter output and public policy/support pages |
| Twilio Verify | Yes | Real phone verification and deletion reauthentication |
| Media hosting | Yes for real catalog | Publish authorized HTTPS photos; app currently accepts URLs |
| Secret manager, monitoring, backups | Yes | Operational safety and incident response |
| Nginx | Only for self-hosting | TLS termination and routing; managed ingress can replace it |
| Kafka | No | Not integrated and not needed for current request/transaction flow |
| Worker queue | Future integration | Durable notifications, media jobs, reconciliation; not implemented |
| Payment/courier services | When adding those capabilities | Buying credentials alone does not implement their workflows |

Keep database and Redis off the public internet. Use TLS for external service connections and least-privilege access. Separate development, staging, and production resources and secrets. Use a dedicated database account, not a database superuser for the API.

## Production API

1. Provision PostgreSQL and Redis in the same region as the API and enable backup/restore features appropriate to your recovery objectives.
2. Set production environment values below in the host's secret manager.
3. Install locked dependencies, generate Prisma, typecheck/test, and compile.
4. Back up any existing database. Run committed migrations once as a controlled deployment job; verify schema and application compatibility.
5. Run the reference category seed once as an administrative task. Provision a real administrator using the separate secured command in [Setup](SETUP.md).
6. Deploy compiled code and require `/readyz` to pass before routing traffic.

```text
NODE_ENV=production
PORT=4000
DATABASE_URL=<provider connection URL with appropriate TLS>
REDIS_URL=<private authenticated Redis URL; rediss where required>
JWT_SECRET=<cryptographically random secret, at least 32 characters>
JWT_EXPIRES_IN=1d
CORS_ORIGIN=<exact HTTPS web origin; comma-separated only for approved origins>
TRUST_PROXY_HOPS=<actual known proxy count>
TWILIO_ACCOUNT_SID=<secret configuration>
TWILIO_AUTH_TOKEN=<secret configuration>
TWILIO_VERIFY_SERVICE_SID=<Verify service>
LOG_LEVEL=info
```

Do not send credentials through chat or commit them. Flutter build defines cannot protect secrets.

API build/release commands, run from `backend/` in the configured environment:

```text
npm ci
npm run db:generate
npm run typecheck
npm test
npm run build
npm run db:migrate:deploy
npm start
```

The test database is separate: integration tests run only when `TEST_DATABASE_URL` names an isolated `nestly_test` database. Do not set it to production. Never use `prisma db push`, `db:reset`, or `migrate reset` as a deployment step.

`render.yaml` supplies the managed API build, pre-deploy migration, compiled start and readiness settings. It does not create your PostgreSQL, Redis, domains, SMS service, monitoring or web hosting. Confirm the host's actual proxy topology before accepting the configured one-hop trust value.

## Self-Hosted Alternative

The production Compose file expects managed/external PostgreSQL and Redis. It deliberately does not expose database ports.

1. Build and scan `backend/Dockerfile`, push an immutable image tag/digest, and set `API_IMAGE` to it.
2. Put API environment configuration in root `.env.production` using restricted filesystem permissions; this file is ignored by Git.
3. Set `PUBLIC_HOST` to your real hostname. Set `TLS_DIRECTORY` to an absolute directory containing `fullchain.pem` and `privkey.pem`.
4. Build the web app into `build/web` with the same public HTTPS host as API base URL when using the provided single-host proxy.
5. Apply migrations once before starting API traffic. For example, run `npx prisma migrate deploy` as an ephemeral container command with the same protected environment and database access.
6. Validate configuration with `docker compose -f docker-compose.production.yml config --quiet`, then deploy with `docker compose -f docker-compose.production.yml up -d`.
7. Verify TLS, readiness, REST requests and WebSocket upgrades from outside the server. Only expose ports 80 and 443.

You must arrange certificate issuance, automated renewal/reload, OS patches, image updates, persistent log collection, firewall rules and recovery. These are not automated by this Compose file. The Nginx template assumes it is the direct public proxy and overwrites forwarded client addresses. Additional CDN/load-balancer hops require a reviewed trusted-proxy configuration. Compose on one host is not high availability or an autoscaling solution.

## Web Release

Populate `config/release.json` using `config/release.example.json`:

- `API_BASE_URL`: deployed HTTPS API origin.
- `PUBLIC_WEB_URL`: deployed HTTPS application origin.
- `PRIVACY_URL`, `TERMS_URL`, `SUPPORT_URL`: actual public owner-operated pages.

The legal screens link to these pages; they are not generated legal policies. Deploy support and policies before submission. Provide a public account-deletion link at `https://<web-host>/#/account/delete`, with clear retention/support information for people who no longer have the app.

```powershell
./scripts/build-release.ps1 -Target web
```

Upload `build/web` to the chosen static host or mount it for Nginx. Preserve routing fallbacks and cache headers in `web/_redirects` and `web/_headers` where supported, or configure equivalents on your host. Test first load, updates from an older build, direct links, policy links, CORS and image loading. Web sessions intentionally do not persist bearer tokens across refreshes.

## Android Release

Confirm the application ID `in.nestly.app`, install Android SDK/JDK, accept SDK licenses, and resolve `flutter doctor` issues. Create a protected upload keystore and populate `android/key.properties` from its example. Back up the upload key securely and configure Play App Signing. Release tasks refuse debug-key fallback.

```powershell
./scripts/build-release.ps1 -Target android
```

Expected artifact: `build/app/outputs/bundle/release/app-release.aab`. Increment `version` in `pubspec.yaml` for each store upload. Use internal testing first. Complete the current target API, content rating, privacy/data safety, account deletion, app-access and testing requirements shown by Play Console. Reference: [Flutter Android release](https://docs.flutter.dev/deployment/android), [Play account deletion](https://support.google.com/googleplay/android-developer/answer/13327111).

## iOS Release

Use a Mac with Xcode and a paid Apple developer account. Register `in.nestly.app`, configure the correct team/signing capabilities in `ios/Runner.xcworkspace`, and verify provisioning and plugin entitlements. Never commit signing certificates or profiles.

On macOS with PowerShell installed, use `./scripts/build-release.ps1 -Target ios`; alternatively run the same analyze/test checks and `flutter build ipa --release --dart-define-from-file=config/release.json`. Upload the resulting archive through the Apple-supported distribution flow, validate with TestFlight and physical devices, and complete privacy, encryption and app-review disclosures.

Reference: [Flutter iOS release](https://docs.flutter.dev/deployment/ios), [Apple account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/). Native release builds and store submissions have not been executed in this Windows workspace.

## Operations and Scaling

- Define expected daily orders, peak concurrent users, launch geography, recovery point/time objectives and a monthly spending limit. Benchmark those workloads before choosing replica counts or promising capacity.
- Alert on failed readiness, API error/latency rates, DB connection saturation, slow queries/locks, Redis failures, SMS rejection/throttling, failed checkouts, inventory conflicts, and stale unfulfilled orders.
- Collect structured redacted logs with retention limits. Configure crash/error reporting with consent and PII filtering; no monitoring vendor is automatically connected.
- Schedule PostgreSQL backups/PITR and regularly restore into a separate environment. Protect media and encryption/signing keys separately. Write and rehearse incident and recovery runbooks.
- Add API replicas only after measuring bottlenecks and testing Redis-backed throttling, authorized socket fan-out, connection budgets and concurrent checkout. Large seller catalogs and history navigation need pagination work described in Release Readiness.
- Treat Redis socket fan-out as transient notifications; persisted orders/events are authoritative. Add a transactional outbox and durable queue for workflows where retries and eventual delivery are necessary. Evaluate Kafka only when measured event volume, replay and multiple independent consumers justify its operational cost.
- Reconcile seller cash and platform fees with actual business processes. The code does not remit money, issue invoices, or resolve customer disputes automatically.
- Deploy additive migrations first. Keep the prior immutable API image and web bundle for rollback. Do not roll back a database by deleting data or rewriting applied migrations; rehearse a compatible forward fix and restore procedure.

## What You Need to Provide

Business/legal ownership, final brand and store IDs, launch service area, approved fee/refund/retention policies, production domains and cloud accounts, real SMS configuration, media hosting, a vetted seller catalog, store developer accounts and signing access, a Mac/iOS build environment, and named owners for support, seller review, delivery, cash reconciliation, backups and alerts.

Provide non-secret URLs and decisions in the project; install credentials through your secret manager. Missing payment, courier, returns, notification, moderation and recovery capabilities require implementation, not just configuration. The full set of known limitations and acceptance gates is in [Release Readiness](docs/RELEASE_READINESS.md).
