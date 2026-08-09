# Shoein' — Monetization

Shoein' uses a **14-day free trial → paid subscription** model. There is **no
permanent free tier**; when the trial ends the app becomes **read-only** until
the user subscribes.

## The model

- **Trial:** 14 days of full access, no credit card required to start.
- **Plans:** Monthly **$6.99** and Annual **$49.99** (annual ≈ $4.17/mo).
- **After expiry:** the app is **read-only** — the user can still view their
  clients, horses, and map, but can't add or edit anything until they subscribe.
  Their data is never deleted.

## How it works (code)

The trial is **app-managed**, not store-managed, so starting it is frictionless
(no purchase sheet up front) and can't be reset by reinstalling:

- On first sign-in, a **write-once** `trialStartedAt` server timestamp is written
  to `users/{uid}` in Firestore (`TrialService` in
  `lib/core/providers/access_providers.dart`). A Firestore rule prevents it from
  ever changing.
- `accessProvider` combines the RevenueCat entitlement + the trial date into
  `trialing | subscribed | expired`.
- `isReadOnlyProvider` is true when `expired`. It gates the add/edit entry points
  (Client + Horse FABs, edit/delete) — they route to `/paywall` instead.
- `AccessBanner` shows the trial countdown, or the read-only notice after expiry.
- The paywall (`lib/features/subscription/presentation/paywall_screen.dart`)
  lists the plans from the RevenueCat offering and handles purchase + restore.

Config lives in `lib/core/config/revenue_cat_config.dart`:
- `kEntitlementId = 'Shoein Pro'`
- `kTrialDays = 14`
- `kRevenueCatIosKey` / `kRevenueCatAndroidKey` (fill in real keys)
- `kPaywallEnabled` — set `--dart-define=PAYWALL_ENABLED=false` to bypass gating
  while developing.

Demo mode (before Firebase is configured) and `PAYWALL_ENABLED=false` both grant
full access. On a transient Firestore read error the app **fails open** (never
locks out a legitimate user).

## Store + RevenueCat setup (one-time)

Shoein' gets its **own RevenueCat project** (per the per-app RevenueCat setup).

1. **RevenueCat:** create the project → add the iOS + Android apps for
   `app.auaha.shoein` → create an entitlement named exactly **`Shoein Pro`**.
2. **App Store Connect:** a subscription group with two auto-renewable products,
   `shoein_pro_monthly` ($6.99) and `shoein_pro_annual` ($49.99). **Do not add a
   store free-trial intro offer** — the 14 days are handled in-app, so avoid a
   double trial.
3. **Google Play:** one subscription `shoein_pro` with monthly + annual base
   plans.
4. Attach both products to the `Shoein Pro` entitlement in RevenueCat, and create
   an **Offering** (`default`, set as current) with the monthly + annual packages.
5. Copy the public SDK keys (`appl_…`, `goog_…`) into `revenue_cat_config.dart`.
6. Deploy the Firestore rules (adds the write-once trial field):
   ```
   firebase deploy --only firestore:rules
   ```

## Testing

- Bypass the paywall while developing: `flutter run --dart-define=PAYWALL_ENABLED=false`.
- Test the real flow with **sandbox** accounts (App Store sandbox tester / Play
  license tester) once the products exist. Check: trial countdown, expiry →
  read-only, purchase → full access, restore on a fresh install.
