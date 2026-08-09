# Shoein' — Trim-Cycle, Dashboard & Scheduling Plan

The retention engine that makes the subscription worth paying for: never miss a
trim/shoe cycle. Build order is ①→②→③→④→⑤; each step is shippable on its own.

## Data model

- **Horse** gains `intervalWeeks` (default 6). `nextDueDate = lastServiceDate +
  intervalWeeks×7`; `dueStatus` ∈ {neverServiced, overdue, dueThisWeek,
  upcoming, ok}. *(Done in ①.)*
- **ServiceRecord** (new): `{ horseId, clientId, date, workType, notes, cost? }`
  at `users/{uid}/clients/{cid}/horses/{hid}/services/{id}` — visit history, and
  later earnings.
- **Appointment** (new): `{ clientId, clientName, start, durationMinutes, notes,
  status }` at `users/{uid}/appointments/{id}`.

Everything lives under `users/{uid}`, so the existing Firestore rules already
cover it.

## ① Per-horse interval + next-due  ✅ (built)

- "Trim every N weeks" control on the horse form.
- Interval-based `ServiceBadge` (Overdue / Due today / Due in Nd / Nd ago),
  replacing the old fixed 42-day badge.

## ② Dashboard / "Due" home screen

- Becomes the landing tab. Aggregates all horses across clients, grouped
  **Overdue · Due this week · Coming up**, sorted by urgency.
- Each row: horse + client + due date + one-tap **Call / Text / Directions /
  Log visit / Schedule**.
- `dueHorsesProvider` — watch clients → their horses, or a
  `collectionGroup('horses')` query (+ index) depending on read volume.

## ③ Log visit → auto-reschedule

- "Log visit" stamps `lastServiceDate = today`, writes a ServiceRecord, and
  `nextDue` recomputes automatically. Optional quick note + cost.
- **Service history** list on the horse detail.

## ④ Local push notifications

- `flutter_local_notifications` + `timezone` (on-device, no server).
- A weekly summary ("3 horses due this week") + optional per-horse nudges.
- iOS notification permission; Android `POST_NOTIFICATIONS` (API 33+).
- Rescheduled whenever intervals/services change.

## ⑤ Scheduling + calendar

- **Schedule tab**: month calendar (`table_calendar`) + day agenda of
  appointments.
- **Appointment form**: client, date/time, duration, notes. Reachable from the
  Dashboard (prefilled for a due horse) and client detail.
- **Add to phone calendar** per appointment via `add_2_calendar` — native
  add-event sheet prefilled (title "Trim — {client}", time, location = client
  address, notes). No calendar-read permission needed; iOS needs an
  `NSCalendarsUsageDescription` string. (Two-way `device_calendar` sync is a
  later option.)

## Cross-cutting

- **Navigation** grows to **Dashboard · Clients · Schedule · Map · Profile** (5),
  or drop Map to keep 4 (still reachable from client detail).
- **Gating:** every write here (set interval, log visit, create appointment) is
  behind the subscription — read-only users get the paywall, same as the rest of
  the app.

## Later / stretch

Client text reminders (prefilled SMS to the client), hoof photos per visit,
invoicing / payment tracking, day/route map view, earnings summary.
