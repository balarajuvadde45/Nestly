# Nestly on AWS — production setup (initial budget under $200/month)

Nestly is a Flutter app (Android, iOS, web) backed by a Node/Express API with
PostgreSQL and Redis. This plan runs all of it on AWS with a monthly bill well
inside $200 for launch volumes, and each piece scales independently later.

## Architecture

```
                    CloudFront (HTTPS, cached)
                    /          \
   S3 bucket (Flutter web build)    ALB
                                        |
                              ECS Fargate task (API container)
                                        |
            RDS PostgreSQL          Redis (ElastiCache or self-hosted on ECS)
                                        |
                              S3 bucket (product & banner media)
```

- **Flutter web** builds to static files (`flutter build web --release`) and is
  served from S3 behind CloudFront. SPA routing: map CloudFront errors 403/404
  to `/index.html`. The repo's `web/_headers` and `web/_redirects` cover
  cache headers for this.
- **Android/iOS** ship as binaries (Play Store / App Store); they talk to the
  same API host, so one backend serves every platform.
- **API** runs as one Docker image on ECS Fargate (public subnet with public
  IP to skip the NAT gateway at first; add one when traffic grows).
- **Database** is RDS PostgreSQL (single-AZ to start, multi-AZ later).
- **Media** moves from the container's `uploads/` folder to S3 + CloudFront
  once more than one task runs; until then the local `/media` route works.
- **Domain** points at CloudFront (web) and ALB (api.example.com), TLS from
  free ACM certificates.

## Monthly cost estimate (ap-south-1, Mumbai)

| Item | Choice | ~USD/month |
|---|---|---|
| Route 53 hosted zone | 1 zone | $0.50 |
| ALB | 1 load balancer + LCU | $18 |
| ECS Fargate | 1 vCPU / 2 GB, 24x7 | $36 |
| RDS PostgreSQL | db.t4g.micro, 20 GB | $13 |
| S3 storage | web build + media, <50 GB | $2 |
| CloudFront | first 1 TB free tier | $0–10 |
| ECR | image storage | $1 |
| CloudWatch logs | basic | $2 |
| ElastiCache Redis (optional) | cache.t4g.micro | $13 |
| **Total** | | **$85–95** |

That leaves roughly $100/month of headroom inside the $200 cap for bursts,
backups, or a second Fargate task.

## Runbook

1. **VPC + network**: one VPC, 2 public subnets, security groups: ALB accepts
   80/443, ECS task accepts only from the ALB, RDS accepts only from the task.
2. **RDS**: create db.t4g.micro PostgreSQL 16, set `DATABASE_URL` from its
   endpoint, enable automated backups. Run `npx prisma migrate deploy` from a
   one-off ECS job or your machine over VPN/whitelisted IP.
3. **ECR + image**: `docker build -t nestly-api . && docker push` to ECR
   (backend Dockerfile already in repo).
4. **ECS**: cluster + task definition (env vars: NODE_ENV=production,
   PORT=4000, DATABASE_URL, JWT_SECRET 32+ chars, REDIS_URL, Twilio Verify
   creds, RAZORPAY_KEY_ID/KEY_SECRET/WEBHOOK_SECRET, PLATFORM_COMMISSION_RATE,
   UPLOAD_DIR, MEDIA_BASE_URL). Secrets live in AWS Secrets Manager or SSM
   Parameter Store — never in the image or git.
5. **ALB + ACM**: request a free cert for the API domain, validate via DNS in
   Route 53, target group on port 4000, HTTPS listener only.
6. **Web hosting**: `flutter build web --release`, sync `build/web` to S3,
   CloudFront distribution with the domain + ACM cert, error pages 403/404 →
   /index.html with 200.
7. **CI/CD**: GitHub Actions — test → build image → push ECR →
   `aws ecs update-service --force-new-deployment`.
8. **Observability**: enable ECS container logs in CloudWatch; add Sentry to
   the backend for error tracking (free tier covers launch volumes).

## What to keep an eye on

- Unpaid online orders are swept after 30 minutes by the backend itself; no
  cron on AWS needed.
- The notification outbox worker runs inside the API process; when scaling to
  2+ tasks, it stays safe (attempts cap + idempotent send).
- Razorpay webhook URL must be the ALB HTTPS domain
  (`https://<api-domain>/payments/webhook`) and the raw-body route stays
  mounted before the JSON parser — already the case in `app.ts`.

## How Nestly compares (what "advanced" buys us)

- **vs Shopify/Dukaan-style single-store builders**: Nestly is multi-vendor by
  design — many home businesses, each with their own products, serviceable
  pincodes, and earnings ledger; commission per seller (10% default).
- **vs generic marketplaces**: we own the full order lifecycle (COD implies
  paid, unpaid online orders auto-expire with stock restore), verified-purchase
  reviews, GST-style invoices with running numbers, refunds recorded, and a
  durable notification outbox with an in-app fallback.
- **Next upgrades, in order of impact**: image resizing/variants via CloudFront
  + Lambda@Edge or a resize job; search relevance (Meilisearch or OpenSearch
  serverless); Redis caching for hot product lists; personalized "recently
  viewed"; and basic analytics events.
