# Shoein' — Store Submission Pack

Everything you paste into App Store Connect / Google Play Console. Copy is
written to the current feature set: dashboard, trim-cycle reminders, visit log +
history, scheduling + calendar, invoicing, route optimizer, hoof photos, and an
earnings dashboard.

---

## 1. Names & subtitles

- **App name:** `Shoein'`
- **Subtitle (App Store, ≤30 chars):** `Farrier client & trim manager`
- **Short description (Play, ≤80 chars):**
  `Client, horse & trim-cycle manager for farriers. Never miss a trim again.`
- **Promotional text (App Store, ≤170 chars, editable anytime):**
  `Know exactly who's due today. Shoein' tracks every horse's trim cycle, reminds you before it's due, and keeps directions, invoices and photos in one place.`

### Keywords (App Store, ≤100 chars, comma-separated, no spaces)
```
farrier,horseshoe,trim,hoof,equine,horse,shoeing,barefoot,invoice,scheduling
```

---

## 2. Full description (App Store description / Play full description)

> Shoein' is the client and trim-cycle manager built for working farriers.
> Instead of juggling a notebook, texts, and your memory, you get one place that
> tells you exactly which horses are due and makes the next step one tap away.
>
> **See who's due today**
> The dashboard pulls every horse across every client into one list — Overdue,
> Due this week, and Coming up — sorted by urgency. Each horse is one tap from
> Call, Text, Directions, Log visit, or Schedule.
>
> **Set a cycle per horse**
> Trim every 6 weeks, every 8 — set the interval per horse and Shoein' figures
> out the next due date automatically every time you log a visit.
>
> **Log visits in seconds**
> Record the work, add a note, cost, and photos of the hoof. The horse's history
> builds itself, and the next due date rolls forward on its own.
>
> **Get reminded before it's due**
> On-device reminders fire the morning a horse is due — no server, no extra
> account. Toggle them on or off anytime.
>
> **Plan your day**
> A month calendar and day agenda hold your appointments. Add any appointment to
> your phone's calendar with directions to the client's address baked in.
>
> **Build the smartest route**
> Pick several clients and Shoein' orders them into an efficient route so you're
> not backtracking across the county.
>
> **Get paid**
> Log a cost as paid on the spot, or send a clean invoice by text or email with
> your own payment link (Venmo, Stripe, whatever you use).
>
> **See your income**
> An earnings dashboard shows what you've made this month and year, what's still
> outstanding, a six-month income trend, and your top clients — no spreadsheets.
>
> **Your data, protected**
> Everything is tied to your account and synced securely. Sign in with email,
> Google, or Apple.
>
> Shoein' starts with a 14-day free trial — full access, no card required. After
> that it's $6.99/month or $49.99/year. If the trial ends, your data stays safe
> and viewable; you just re-subscribe to keep editing.

### Subscription disclosure (append to the Play full description; App Store
shows it automatically from the products, but include it to be safe)
```
Shoein' Pro subscription:
• Monthly — $6.99 / month
• Annual — $49.99 / year
A 14-day free trial is included. Payment is charged to your Google/Apple
account. Subscriptions renew automatically unless canceled at least 24 hours
before the end of the period. Manage or cancel anytime in your account settings.
Privacy Policy: https://auaha.app/shoein/privacy
Terms of Use: https://auaha.app/shoein/terms
```

---

## 3. What's New (version 1.0.0)
```
First release of Shoein' — the trim-cycle manager for farriers. Track clients
and horses, see who's due, log visits with photos, schedule appointments,
optimize your route, send invoices, and watch your earnings. Thanks for trying
it!
```

---

## 4. Support / marketing URLs (already live)
- Support URL: `https://auaha.app/shoein/support`
- Marketing URL: `https://auaha.app/shoein`
- Privacy Policy: `https://auaha.app/shoein/privacy`
- Terms of Use (EULA): `https://auaha.app/shoein/terms`

---

## 5. Apple — App Privacy questionnaire

Answer "Yes, we collect data." Then declare these types. None are used for
tracking; all are **linked to the user's identity** and used for **App
Functionality** only.

| Data type | Collected | Linked | Tracking | Purpose |
|---|---|---|---|---|
| Email address | Yes | Yes | No | App Functionality (account) |
| Name | Yes | Yes | No | App Functionality (account) |
| User ID | Yes | Yes | No | App Functionality (auth / subscription) |
| Purchase history | Yes | Yes | No | App Functionality (subscription status via RevenueCat) |
| Photos (hoof photos) | Yes | Yes | No | App Functionality |
| Other user content (client/horse records, addresses, notes) | Yes | Yes | No | App Functionality |

**Precise Location:** the app requests "when in use" location only to center the
map and give directions **on the device**. That location is **not transmitted or
stored on our servers**, so it is *not* declared as collected. (Client addresses
are user-entered content, already covered by "Other user content.") If App
Review pushes back, the honest framing is: location is used on-device for maps,
not collected.

**Not collected:** browsing history, search history, contacts, health, financial
info, sensitive info, diagnostics/analytics (the app ships no analytics SDK).

---

## 6. Google Play — Data safety form (mirror of the above)

- **Does your app collect or share user data?** Yes, collect. **Share?** No.
- **Is all data encrypted in transit?** Yes.
- **Can users request data deletion?** Yes — via support (auaha.app/shoein/support).

Declare:
- **Personal info → Name, Email address** — Collected, not shared, required,
  purpose: Account management, App functionality.
- **Personal info → User IDs** — Collected, App functionality / Account.
- **Financial info → Purchase history** — Collected, App functionality (subs).
- **Photos and videos → Photos** — Collected, App functionality.
- **App activity / Other user-generated content** (client & horse records) —
  Collected, App functionality.
- **Location → Approximate/Precise location** — only if you keep the on-device
  map centering; mark **App functionality**. If you'd rather avoid the section,
  it's defensible to leave location out since nothing leaves the device, but be
  consistent with the manifest permission.

---

## 7. Content / age rating
- **Apple age rating:** 4+ (no objectionable content).
- **Play content rating (IARC questionnaire):** answer No to all
  violence/sexual/gambling/etc. questions → **Everyone**.

---

## 8. Screenshot shot-list

Capture on a real device or simulator with a few clients + horses loaded so the
screens look real (not empty states). Turn on a couple of "overdue" horses so
the dashboard has color.

**iPhone 6.7" (1290×2796) — required, 3–5 shots:**
1. **Dashboard** — "Overdue / Due this week" list with color badges. Caption:
   *"See exactly who's due today."*
2. **Horse detail + service history** with a couple logged visits + a hoof
   photo. Caption: *"Every horse's history in one place."*
3. **Log visit sheet** open (work type chips, cost, photo thumbnails). Caption:
   *"Log a visit in seconds."*
4. **Schedule** — month calendar with the day agenda. Caption: *"Plan your day,
   sync to your calendar."*
5. **Map / route** — clients on the Mapbox map (or the route planner). Caption:
   *"Build the shortest route."*

**iPhone 6.5" (1242×2688)** — same five (App Store can reuse 6.7" if you skip
this, but providing both is cleaner).

**iPad** — only if you enable iPad support; otherwise leave off.

**Android phone (min 2, up to 8; 1080×1920 or device-native):** reuse shots 1–5.

**Android feature graphic (1024×500, required):** forge-charcoal background,
Shoein' mark + wordmark left, tagline "Never miss a trim." right. (I can generate
this — just say the word.)

**App icon 1024×1024:** export `assets/icon/icon.png` (already the source art) at
1024 with no alpha for App Store.

---

## 9. Final pre-submit checklist
- [ ] Paid Applications agreement signed (App Store Connect → Business).
- [ ] `shoein_pro_monthly` ($6.99) + `shoein_pro_annual` ($49.99) created, **no**
      store intro/trial offer (the 14 days are in-app).
- [ ] Play `shoein_pro` monthly + annual base plans Active; app pushed to
      Internal Testing once so products resolve.
- [ ] RevenueCat offering set as **Current** with both packages ✅ (done).
- [ ] Firestore + Storage rules deployed to prod (owner-only).
- [ ] Google & Apple sign-in enabled in Firebase (see SOCIAL_SIGNIN_SETUP.md).
- [ ] Tested trial → read-only → purchase → restore on a real device.
