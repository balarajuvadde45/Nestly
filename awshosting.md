# Tamarin on AWS — Step-by-Step Hosting Guide

Target: production-grade, low-cost (~$80–180/month at launch scale), following AWS best practices: private databases, load-balanced API, auto-scaling, HTTPS everywhere. Build this in order — each section assumes the previous one.

**Architecture you're building:**

```
                        Route 53 (DNS)
                              │
              ┌───────────────┴────────────────┐
              │   CloudFront (web + media)     │   S3 (web build + uploads)
              └───────────────┬────────────────┘
                              │ HTTPS (ACM cert)
                       Application Load Balancer
                 (public subnets, 2 availability zones)
                              │
                    ECS Fargate: tamarin-api containers
                 (private subnets, auto-scaling 2→6 tasks)
                       │                  │
             RDS PostgreSQL         ElastiCache Redis
             (Multi-AZ, private)    (private)
```

> Web can also start on Cloudflare Pages / Netlify free tier (simpler) with AWS only for the API — see §10 for the cheaper variant.

---

## 0. Account & safety rails (15 min)

1. Create the AWS account, then in IAM **create an admin user for yourself** with MFA — never use the root user day-to-day.
2. Set a **billing budget**: Billing → Budgets → Create budget → Monthly cost $200 → alert at 80%/100% → email.
3. Choose your home region: **ap-south-1 (Mumbai)** for Indian users. Use it everywhere below (screenshots show `ap-south-1`).

## 1. Networking — VPC (30 min)

1. VPC console → **Create VPC** → choose "VPC and more":
   - Name: `tamarin-vpc`, CIDR `10.0.0.0/16`, **2 Availability Zones**, **2 public subnets**, **2 private subnets**, 1 NAT gateway ($32/mo — required so private containers can reach Twilio/Razorpay).
2. VPC → Your VPCs → `tamarin-vpc` → enable **DNS hostnames** (Actions → Edit VPC settings).
3. Security groups (EC2 → Security Groups → Create):
   - `alb-sg`: inbound **443** + **80** from `0.0.0.0/0`.
   - `api-sg`: inbound **4000** from `alb-sg` only.
   - `rds-sg`: inbound **5432** from `api-sg` only.
   - `redis-sg`: inbound **6379** from `api-sg` only.

## 2. Database — RDS PostgreSQL (30 min + ~15 min provision)

1. RDS → Create database → **PostgreSQL 17** → Templates: **Free tier** (db.t4g.micro, fine for launch) or Production.
2. Settings: DB id `tamarin-db`, master username `tamarin_admin`, **store the password in Secrets Manager** (checkbox).
3. Connectivity: VPC `tamarin-vpc`, **private subnets only** (create a DB subnet group from the two private subnets), public access **No**, security group `rds-sg`.
4. Enable: automatic backups (7 days), deletion protection. Multi-AZ can wait until revenue (it doubles DB cost).
5. When created, note the **endpoint** (`tamarin-db.xxxx.ap-south-1.rds.amazonaws.com`).
6. One-time schema setup: from your machine (or a bastion/CloudShell with access):
   ```
   psql "postgresql://tamarin_admin:<pw>@<endpoint>:5432/postgres?sslmode=require" \
     -c "CREATE DATABASE tamarin;"
   # then run migrations from a CI job or your machine with the prod URL:
   cd backend && DATABASE_URL="postgresql://...tamarin?sslmode=require" npx prisma migrate deploy
   # reference categories (safe, idempotent):
   DATABASE_URL="postgresql://...tamarin?sslmode=require" npx tsx prisma/seed.ts
   # first admin (the script enforces a 16+ char password):
   DATABASE_URL="postgresql://...sslmode=require" ADMIN_EMAIL=you@tamarin.in ADMIN_PASSWORD='...' npx tsx scripts/create-admin.ts
   ```

## 3. Cache — ElastiCache Redis (15 min)

1. ElastiCache → Create → **Redis OSS** → Serverless or `cache.t4g.micro` (cheaper), name `tamarin-redis`.
2. VPC `tamarin-vpc`, **private subnet group**, security group `redis-sg`, no auth token needed (network-private) — or enable AUTH and store the token in Secrets Manager.
3. Note the **endpoint** (`tamarin-redis.xxxx.ng.0001.aps1.cache.amazonaws.com:6379`).

## 4. Container image — ECR (10 min)

1. ECR → Create repository → `tamarin-api` (private).
2. Authenticate + push from your machine:
   ```
   aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <acct>.dkr.ecr.ap-south-1.amazonaws.com
   docker build -t tamarin-api backend/
   docker tag tamarin-api:latest <acct>.dkr.ecr.ap-south-1.amazonaws.com/tamarin-api:v1
   docker push <acct>.dkr.ecr.ap-south-1.amazonaws.com/tamarin-api:v1
   ```
   (The Dockerfile is multi-stage and hardened — non-root, healthcheck via `/readyz`.)

## 5. Run the API — ECS Fargate + Load Balancer (45 min)

1. **Certificates first**: ACM → Request certificate → `api.tamarin.in` (and `tamarin.in`, `partner.tamarin.in` if hosting web here) → **DNS validation** → add the CNAME records it shows (they go into Route 53 in §6).
2. EC2 → **Load Balancers** → Create → **Application Load Balancer**, name `tamarin-alb`, scheme **internet-facing**, VPC `tamarin-vpc`, **both public subnets**, security group `alb-sg`.
   - Listener **HTTPS:443** → new target group `tamarin-api-tg` (target type **IP**, protocol HTTP:4000, health check path **`/healthz`**) — attach ACM cert.
   - Listener HTTP:80 → redirect to HTTPS.
   - Register nothing yet (ECS will register tasks as IPs).
3. ECS → Create **Cluster** → Networking-only (Fargate), name `tamarin`.
4. ECS → Task definitions → Create new → **Fargate**:
   - Name `tamarin-api`, CPU **0.5 vCPU**, Memory **1 GB** (raise later under load).
   - Container `api`: image = the ECR URI from §4, port 4000, health check `curl -f http://localhost:4000/readyz || exit 1`.
   - **Environment variables** ( Secrets): `NODE_ENV=production`, `DATABASE_URL=postgresql://tamarin_admin:<pw>@<rds-endpoint>:5432/tamarin?schema=public&sslmode=require`, `REDIS_URL=redis://<redis-endpoint>:6379`, `JWT_SECRET=<openssl rand -hex 32>`, `JWT_EXPIRES_IN=1d`, `CORS_ORIGIN=https://tamarin.in,https://partner.tamarin.in`, `TRUST_PROXY_HOPS=1`, `DEFAULT_CITY=Hyderabad`, Twilio trio, Razorpay trio, `PLATFORM_COMMISSION_RATE=10`, `UPLOAD_DIR=/app/uploads`, `MEDIA_BASE_URL=https://media.tamarin.in`.
   - Use **secrets** from Secrets Manager for DB password / JWT / Twilio / Razorpay values (ECS task definition supports `secrets` → ARN).
5. ECS → Create **Service**: cluster `tamarin`, task def `tamarin-api`, **2 tasks**, VPC + **private subnets**, security group `api-sg`, Load balancer → `tamarin-alb` / `tamarin-api-tg`, **Service auto-scaling**: target-tracking on ALB RequestCountPerTarget ≈ 400, min 2 max 6; plus CPU 70% scaling.
6. Wait for tasks to pass health checks. Test: `curl https://<alb-dns>/healthz`.

## 6. DNS — Route 53 (20 min)

1. Buy/transfer the domain (GoDaddy `tamarin.in` → either keep GoDaddy DNS and add records there, or Route 53 → Hosted zones → Create `tamarin.in` → copy the 4 NS records into GoDaddy).
2. Create records (hosted zone or GoDaddy, same values):
   | Record | Type | Value |
   |---|---|---|
   | `api.tamarin.in` | A (Alias) | the ALB (double-click alias target) |
   | `tamarin.in` + `www` | A (Alias) | CloudFront distribution (§7) |
   | `partner.tamarin.in` | A (Alias) | CloudFront (partner web build) |
   | `media.tamarin.in` | A (Alias) | CloudFront media distribution (§7) |
3. Validate the ACM cert if not already done (it validates against these records automatically).

## 7. Web + media — S3 + CloudFront (30 min)

**Web (two static sites):**
1. S3 → Create bucket `tamarin-web-customer` (and `tamarin-web-partner`), Block Public Access **ON**.
2. Build locally: `flutter build web --release --dart-define-from-file=config/release.json` (see `config/release.example.json` for the five HTTPS URLs) → upload `build/web/*` to the bucket (AWS CLI: `aws s3 sync build/web s3://tamarin-web-customer --delete`). Build the partner web the same way inside `../Nestly_Seller` → partner bucket.
3. CloudFront → Create distribution → origin = the bucket (OAC enabled), default root object `index.html`, viewer protocol HTTPS-only, compress yes, **price class limited to NA+EU+India** (cheaper).
4. Custom error response: 403/404 → `/index.html` **200** (needed for SPA routes).
5. Alternate domain name `tamarin.in` (+ `partner.tamarin.in`) with the ACM cert. Update Route 53 aliases (§6).
6. **Deploys** = re-upload the new build (or automate in GitHub Actions — see §9). Add a `Cache-Control` metadata of `max-age=300` for `index.html` and `max-age=31536000, immutable` for `assets/*` (hashed files).

**Media (uploads):**
- **Simplest (no code change):** create an **EFS** filesystem, mount it into the ECS tasks at `/app/uploads` (task definition → volumes → EFS), keep `UPLOAD_DIR=/app/uploads`, and serve `media.tamarin.in` via a CloudFront origin pointing at `https://<alb>/media` (cache images, forward nothing). Set `MEDIA_BASE_URL=https://media.tamarin.in`.
- **Better at scale (small code change):** S3 bucket `tamarin-media` + CloudFront → change `backend/src/routes/media.ts` to `PutObject` and return the CloudFront URL. Note it in the repo when you do it.

## 8. Observability & ops (20 min)

1. CloudWatch Logs: ECS sends container stdout to `/ecs/tamarin-api` automatically — create a **Logs Insights** saved query for `level >= 40` (warnings/errors).
2. Alarms: ALB `HTTPCode_Target_5XX_Count > 10 in 5 min` → SNS → your email; RDS `CPUUtilization > 80%`; task health-check failures.
3. Backups: RDS automatic (verify 7-day retention). Redis: enable snapshotting (or accept cache-loss — it only holds rate-limit counters; sessions are JWT).
4. Deploys: push a new image tag → `aws ecs update-service --cluster tamarin --service tamarin-api --force-new-deployment` (rolling, health-checked). Wire this into GitHub Actions after tests pass.

## 9. CI/CD (optional but recommended, 30 min)

GitHub Actions: backend job (exists in `.github/workflows/ci.yml`) → add a `deploy` job gated on `main` + version tag:
```
aws ecr get-login-password | docker login ...
docker build -t backend/ --build-arg ... -t $ECR:$GITHUB_SHA backend/
docker push $ECR:$GITHUB_SHA
aws ecs update-service --force-new-deployment (with task def rendered from the new image)
```
Store `AWS_ACCESS_KEY_ID/SECRET` as GitHub OIDC role (preferred) or repo secrets. Web: sync `build/web` to S3 in the same workflow.

## 10. Cheaper day-1 variant (~$55/mo)

- Web: Cloudflare Pages / Netlify **free** (both support SPA fallback) — skip §7 web part; keep S3+CloudFront for media only.
- DB: RDS `db.t4g.micro` free-tier eligible for 12 months.
- Redis: ElastiCache `cache.t4g.micro` (~$12/mo).
- Compute: **one** ECS Fargate task (0.25 vCPU/512MB, ~$9/mo) + ALB (~$18/mo); scale when the 5XX or CPU alarms fire.
- NAT gateway is the sneaky cost ($32/mo) — for day 1 you can put the API in a **public** subnet with `api-sg` restricted to `alb-sg` and skip NAT (add it back before HIPAA-style rigor matters). The production env-validation still forces the correct security posture.

## Launch checklist (tick before going live)

- [ ] `https://api.tamarin.in/healthz` = 200 and `/readyz` = 200 (DB + Redis up)
- [ ] CORS_ORIGIN matches the exact web domains (the API refuses to boot otherwise)
- [ ] TRUST_PROXY_HOPS matches reality (1 behind ALB) — otherwise rate limiting throttles everyone
- [ ] Razorpay **live** webhook registered + one real ₹1 transaction tested end-to-end (place → pay → PAID → deliver → ledger)
- [ ] One real refund tested (cancel a paid order → REFUND_DUE → sweep → REFUNDED)
- [ ] Twilio OTP delivered to a real Indian number
- [ ] Seller onboarding + admin approval tested on the Partner app against production
- [ ] RDS snapshot taken; restore procedure written down
- [ ] Budget alarm + 5XX alarm configured
- [ ] Legal pages live (privacy, terms, refund policy, grievance officer)
