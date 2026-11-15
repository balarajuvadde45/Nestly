# Live UI/UX Verification — 2026-11-15

The app was built and run for real on this machine: **Web (Chrome engine, mobile + desktop viewports)** and **Android (Pixel 6 API-36 emulator, debug APK)**. iOS cannot run on Windows (requires macOS/Xcode) — code-level verification + a Mac checklist are below.

## What was run

| Platform | How | Result |
|---|---|---|
| Web | Flutter 3.47.2 `flutter run -d web-server` on http://127.0.0.1:8088, walked through via browser automation at 390×844 (mobile) and 1280×800 (desktop) | ✅ runs; full flow tested |
| Android | `flutter build apk --debug` → Pixel 6 emulator (API 36) → `adb install` + `adb reverse tcp:4000 tcp:4000` → live API | ✅ builds & runs; home/vendor/product verified |
| iOS | Code/config audit (Info.plist, theme, SafeArea, transitions) | ⚠️ not runnable on Windows — see checklist |

Local stack used: PostgreSQL 18 private instance on port 5433 (DB `tamarin`), API on :4000, reference seed + local demo data (`backend/scripts/local-demo-data.ts`, untracked — creates 4 approved sellers, 13 products, buyer/seller/admin accounts; local-only, do not commit).

## Bugs found live & fixed in this pass

1. **[P1 visual] Home "Top rated sellers" cards overflowed by 106–130px at mobile width** — yellow/black render-error stripes on the main screen (`home_screen.dart:451`, grid aspect 1.55 gave ~219px for ~350px of content). Fixed: aspect `0.95`. Verified clean on Android.
2. **[P1 visual] Hub cards ("Clothes"/"Wholesale") overflowed by 2.4px at mobile width** (`marketplace_header.dart:381`, aspect 1.15). Fixed: `1.0` on mobile. Verified clean on Android.
3. **[P0 build] `orders_screen.dart` missing `ApiClient` import** — whole file failed to compile (fixed earlier, same pass).
4. **[P0 build] `product_screen.dart` missing `ApiClient` import** — found by `flutter analyze` once the toolchain was available (fixed).
5. **[P0 build] `app_theme.dart` missing `cupertino.dart` import** — `CupertinoPageTransitionsBuilder` undefined; app-wide theme failed to compile (fixed).
6. **[P0 build] Android manifest merge failure** — debug overlay's `usesCleartextTraffic="true"` conflicts with main's `false`; **the Android app could not build at all**. Fixed with `tools:replace="android:usesCleartextTraffic"` in `android/app/src/debug/AndroidManifest.xml`. APK now builds.

After fixes: `flutter analyze` clean (2 pre-existing lints), **9/9 Flutter tests pass**, debug APK builds, app runs on web + Android.

## Confirmed working (verified live)

- Buyer flow end-to-end: home → category (accurate counts) → product (veg badge, ₹149 vs ₹189 MRP strikethrough, honest "21% OFF", stock chip, full Legal-Metrology table: HSN/GST/FSSAI/batch/best-before/shelf-life/manufacturer/packer) → reviews empty-state → add to cart → cart (transparent fees: 149+29+5=183, reverse-GST ₹15.96, free-delivery nudge) → checkout (COD + Pay Online, Terms/Privacy links) → order placed via server-authoritative quote (₹303 = 2×149, free delivery correctly applied ≥₹199) — cart and pricing math all correct.
- Login gate: in-place "Login required" screen on checkout ✓; no fixed OTP hints; password visibility toggle; autofill hints.
- Seller entry: "Start selling from your place" — business-place-first positioning ✓.
- Desktop web (1280px): top nav + NavigationRail, 4-across hubs, cart badge, no overflow errors.
- Android native: status-bar insets correct (SliverAppBar), vendor page with cover image, FSSAI trust line, veg/non-veg badges, ADD buttons, images loading from API.
- Rename: "Tamarin" live in web title, login, Android bottom nav, iOS plist, order invoice strings.

## Remaining UI/UX issues (not fixed in this pass)

- **[P1] Web: page refresh logs the user out** (auth token is memory-only on web by design). Every reload wiped the session during testing. Needs a web session strategy before web launch.
- **[P1] Fake location header**: "Madhapur ⌄" is hardcoded with a chevron implying a tappable picker that doesn't exist; mic icon implies voice search.
- **[P2] Category pill chips clipped on Android** ("Fooc", "Pickle", "Clothe") — consistent with runtime-fetched Poppins metrics; bundling the font (already recommended in CODE_REVIEW P3) is the proper fix.
- **[P2] Out-of-stock product (Biryani, stock 0) still shows an enabled ADD button** with only a snackbar after tap — needs a disabled "Out of stock" state (already P1 in CODE_REVIEW).
- **[P3] Hub/vendor cards have generous empty space** between icon and title at some widths (aspect-ratio headroom).
- **[P3] Order detail deep-links show misleading empty states when logged out** (confirmed: `/orders` showed "No orders yet" instead of a login prompt).
- **[P3] IAB/browser transient double-width render glitch** observed in clipped screenshots only — not reproduced in full-screen; monitor.

## iOS — verified in code + Mac checklist

Verified in code: display name "Tamarin" (`ios/Runner/Info.plist`), bundle id `in.tamarin.app`, Cupertino page transitions for iOS (`app_theme.dart:34`), SafeArea on bottom bars + SliverAppBar/AppBar top insets, no permission usage-strings needed (PHPicker gallery-only), orientations incl. iPad.

**Mac simulator checklist (15 min):**
1. `flutter emulators --launch apple_ios_simulator` → iPhone 15/16.
2. `flutter run -d <sim-id> --dart-define=API_BASE_URL=https://<staging>` — verify: status-bar/notch spacing on home & splash, swipe-back gesture from product/vendor, keyboard: email/password fields + OTP field paste, scroll bounce,veg/non-veg badges, bottom-bar home-indicator overlap (SafeArea bottom already used).
3. Check pull-to-refresh absence (not implemented — fine) and dark-mode (app forces light; system dark mode must not invert).
4. Store screenshots at 6.7" and 5.5" via Simulator ⌘+S.

## How to re-run this locally

```powershell
# 1. DB (private instance, already created at D:\dev\tamarin-pg-data)
& "C:\Program Files\PostgreSQL\18\bin\pg_ctl.exe" -D "D:\dev\tamarin-pg-data" -o "-p 5433" start

# 2. API (backend/.env already points at localhost:5433)
cd backend; npm run dev          # or: npx tsx src/index.ts

# 3. Web
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8088

# 4. Android emulator (AVD on D: to avoid C: disk limit)
set ANDROID_AVD_HOME=D:\dev\avd
D:\dev\android-sdk\emulator\emulator.exe -avd Tamarin_Phone -gpu swiftshader_indirect &
D:\dev\android-sdk\platform-tools\adb.exe reverse tcp:4000 tcp:4000
flutter build apk --debug && adb install -r build\app\outputs\flutter-apk\app-debug.apk

# 5. Demo data (local only)
cd backend && npx tsx scripts/local-demo-data.ts
# buyer@tamarin.test / Buyer#Tamarin2026 · seller@tamarin.test / Seller#Tamarin2026 · admin@tamarin.local / Admin#Tamarin2026
```

Note: Flutter SDK lives at `D:\dev\flutter` (add `D:\dev\flutter\bin` to PATH); Android SDK at `D:\dev\android-sdk`; JDK 17 at `D:\dev\jdk-17.*`. The C: drive is ~96% full — keep SDKs on D:.
