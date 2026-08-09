# Shoein' — Trim-Cycle, Dashboard & Scheduling Plan

The retention engine that makes the subscription worth paying for: never miss a
trim/shoe cycle. Build order was ①→②→③→④→⑤ — **all five are built**; this doc is
kept as the reference for how they fit together.

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

## ② Dashboard / "Due" home screen  ✅ (built)

- Becomes the landing tab. Aggregates all horses across clients, grouped
  **Overdue · Due this week · Coming up**, sorted by urgency.
- Each row: horse + client + due date + one-tap **Call / Text / Directions /
  Log visit / Schedule**.
- `dueHorsesProvider` — watch clients → their horses, or a
  `collectionGroup('horses')` query (+ index) depending on read volume.

## ③ Log visit → auto-reschedule  ✅ (built)

- "Log visit" stamps `lastServiceDate = today`, writes a ServiceRecord, and
  `nextDue` recomputes automatically. Optional quick note + cost.
- **Service history** list on the horse detail.

## ④ Local push notifications  ✅ (built)

- `flutter_local_notifications` + `timezone` (on-device, no server).
- One reminder per horse on its next-due date (7am), auto-rescheduled whenever
  the due list or the "Trim reminders" toggle changes.
- iOS notification permission; Android `POST_NOTIFICATIONS` (API 33+).
- (A weekly "N due this week" summary is a possible future addition.)

## ⑤ Scheduling + calendar  ✅ (built)

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
