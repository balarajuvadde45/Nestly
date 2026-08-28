# syntax=docker/dockerfile:1
# Multi-stage build for the Nestly API. Produces a small production image
# that runs the compiled JS (dist/) on Node 22 LTS.

FROM node:22-bookworm-slim AS base
WORKDIR /app
# Prisma needs OpenSSL at build (generate) and run time.
RUN apt-get update \
  && apt-get install -y --no-install-recommends openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# ---- install all deps (incl. dev) for building ----
FROM base AS deps
COPY package.json package-lock.json* ./
RUN npm ci

# ---- typecheck-free build: generate Prisma client + compile TS ----
FROM deps AS build
COPY prisma ./prisma
RUN npx prisma generate
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build

# ---- lean runtime image ----
FROM base AS runtime
ENV NODE_ENV=production
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev
COPY prisma ./prisma
RUN npx prisma generate
COPY --from=build /app/dist ./dist
EXPOSE 4000
# Apply pending migrations, then start. `migrate deploy` is safe & idempotent.
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
