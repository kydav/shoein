# Shoein' — Roadmap

Post-v1 features, roughly in priority order. Shipped items live in
[FEATURES.md](FEATURES.md); payments have their own doc in
[PAYMENTS.md](PAYMENTS.md).

---

## 1. Card payments (Stripe) — see [PAYMENTS.md](PAYMENTS.md)

Stripe Connect + Firebase Cloud Functions so an invoice opens a hosted page
pre-loaded with the exact total and auto-marks paid via webhook. Biggest lever
for justifying the subscription. Full architecture is in PAYMENTS.md.

## 2. Data export + CSV import

**Export (do first — cheap, high trust):** an "Export data" action that writes a
CSV of clients + service history (and/or an earnings CSV for taxes) and hands it
to the share sheet. `csv` package, no backend. Signals data isn't locked in and
doubles as a bookkeeping/tax feature.

**Import (bigger):** reduce switching friction for a farrier with an existing
spreadsheet.
- **Template-based (preferred for v1):** provide a downloadable CSV template
  with fixed headers (name, phone, email, address, notes); they fill/upload it.
- Column-mapping (fancier) can come later.
- Flow: `file_picker` → `csv` parse → validate + **preview** rows → geocode
  addresses (already have geocoding) → batched Firestore writes (chunks of 500)
  → dedupe by name/phone.
- **Clients first** — a flat CSV maps cleanly to clients; horses are 1-per-row
  and trickier, so import those in a second pass (keyed by client name) or add
  by hand initially.

## 3. Inventory management + order-to-dealer

Track farrier supplies (shoes by size, nails, pads, etc.) with on-hand counts
that draw down as visits are logged, plus low-stock flags.
- **Order to dealer via text:** compose a restock order from low/selected items
  and send it as a prefilled SMS (or email) to a saved dealer contact — same
  `sms:`/email pattern already used for invoices.
- Data: a new `inventory/{id}` collection under the user (`{ name, size, onHand,
  reorderAt, unit }`) and a saved dealer contact on the user doc.
- Nice-to-have later: auto-decrement stock from a visit's work type (e.g. "Full
  set" = 4 shoes + N nails), configurable per work type.

## 4. Client appointment reminders (SMS + email, with .ics)

Today reminders are **on-device for the farrier**. Add reminders **to the
client** ahead of an appointment.
- **v1 (no backend):** a one-tap "Remind client" on an appointment that opens a
  prefilled SMS/email with the date/time/location — and attach an **`.ics`**
  calendar invite the client can add to their own calendar. Generate the ICS
  locally (VEVENT with title, start/end, location, notes); attach via email, or
  share the `.ics` file.
- **v2 (automated, needs backend):** scheduled sends (e.g. 24h before) via a
  Cloud Function + Twilio/SendGrid. Bigger lift; deferred.

## 5. Offline-first / cacheable data + draft visits

Farriers work in rural areas with poor signal, so the app must be fully usable
offline.
- **Caching:** Firestore offline persistence is on by default; audit that every
  read path works from cache and nothing hard-requires the network. Cache visit
  **photos** locally too (they currently upload to Storage immediately).
- **Log a visit without service / upload later:** allow creating a visit while
  offline (or intentionally as a draft) — store it locally with any photos and
  **sync when back online**. Needs a local queue (e.g. a `pending` flag +
  local file paths) and a background flush that writes to Firestore/Storage
  once connectivity returns. `connectivity_plus` to detect, and a small
  outbox in local storage.

## 6. Horse profile photos

A profile picture per horse (in addition to the per-visit hoof photos we already
have).
- Add `photoUrl` to the `Horse` model; pick/capture via `image_picker`, upload
  to Storage under `users/{uid}/horses/{id}/…` (reuse `PhotoService`).
- Show as an avatar on the horse tile (client detail), horse form, and anywhere
  a horse is listed — falls back to the current horse-head icon when unset.

---

## Also noted (from the release readiness review)
- **Pricing:** keep the low intro price to win early adopters, but grandfather
  them so it can be raised later without burning anyone.
- **Auto client reminders** and **inventory auto-draw-down** are the kind of
  "sticky" features that defend the subscription over time.
