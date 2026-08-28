# Nestly — deploy (locked launch defaults)

**Launch shape:** soft launch  
**Payments:** Cash on Delivery only  
**Google login:** hidden  
**Android application id:** `in.nestly.app`  
**Hosts:** Render (API + Postgres) + Cloudflare Pages (website)  
**Domain:** free host URLs until you buy one  

You create the two accounts. Then follow this.

---

## 1. Render — API + Postgres

1. Sign up at [https://render.com](https://render.com) with GitHub.
2. **New → PostgreSQL** (Free). Wait until it is running. Copy **Internal Database URL**.
3. **New → Blueprint** and point at this repo (uses `render.yaml`), **or** **New → Web Service**:
   - Root directory: `backend`
   - Build: `npm install && npx prisma generate`
   - Start: `npx prisma db push && npx tsx src/index.ts`
   - Health: `/health`
4. Environment variables:

| Key | Value |
|-----|--------|
| `NODE_ENV` | `production` |
| `DATABASE_URL` | Internal Database URL from step 2 |
| `JWT_SECRET` | long random string (Render can generate) |
| `CORS_ORIGIN` | your Cloudflare Pages URL, e.g. `https://nestly.pages.dev` |
| `DEFAULT_CITY` | `Hyderabad` |

5. **Do not** add a seed command. Seeding wipes all data.
6. After first deploy, open `https://YOUR-SERVICE.onrender.com/health`  
   You should see `"ok": true, "database": "up"`.
7. Load catalog once (optional, local only): run `npm run db:seed` **against a local DB**, not this URL.

Send me the public API URL (e.g. `https://nestly-api.onrender.com`).

---

## 2. Cloudflare Pages — website

1. Sign up at [https://dash.cloudflare.com](https://dash.cloudflare.com).
2. Flutter is not on Cloudflare’s build image, so **build on your PC** then upload:

```powershell
cd C:\homefoods\home_foods
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com
```

3. Cloudflare → **Workers & Pages** → **Create** → **Pages** → **Upload assets**.
4. Upload the folder `build/web`.
5. After it is live, copy the `*.pages.dev` URL.
6. Go back to Render and set `CORS_ORIGIN` to that exact URL (no trailing slash). Redeploy the API.

Later we can add GitHub Actions so each push deploys the web build automatically.

---

## 3. Android (when you are ready)

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com
```

Application id is `in.nestly.app`.  
Release is still signed with the **debug** key until you create a Play upload keystore. That is fine for sideloading; not fine for Play Store.

---

## 4. When you buy a domain

Tell me the domain. You will add two DNS records I send you:

- Website → Cloudflare Pages  
- `api.yourdomain` → Render  

Then we rebuild the app with the new `API_BASE_URL`.

---

## What you send me after accounts exist

```
Render API URL: https://______.onrender.com
Health check: ok / not yet
Cloudflare Pages URL: https://______.pages.dev
CORS updated: yes / no
```
