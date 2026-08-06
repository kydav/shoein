# Shoein'

Client & horse management for farriers. Track your clients, their addresses (on a
map), and each horse's notes and last service date.

Flutter + Riverpod + go_router + Firebase — same house stack as the other apps.

## Status — MVP scaffold

Runs in **demo mode** (in-memory sample data) before Firebase is configured, so
it's fully browsable right away.

- **Clients** — searchable list; add/edit/delete. Each client has name, phone,
  email, address, and notes.
- **Client detail** — mini-map of their location, one-tap Call / Text /
  Directions, and their list of horses.
- **Horses** — per client, with breed, notes, and a **last service date**. A
  badge flags horses that are due (42+ days) or coming up.
- **Map** — every client with a geocoded address shown as a pin; tap to open.
- **Auth** — Firebase email/password (demo login until configured).

## Architecture
Feature-first, mirroring the other apps:
```
lib/
  core/
    models/         Client, Horse
    providers/      auth, data (clients/horses streams)
    services/       shoein_repository (Firestore + in-memory demo),
                    geocoding, firebase_bootstrap
    presentation/   app_shell (bottom nav), shared widgets
    router/         go_router with auth redirect
    theme/
  features/{auth,clients,horses,map,profile}/presentation/
```

`ShoeinRepository` is the seam: `FirestoreRepository` for real data,
`DemoRepository` (seeded, in-memory) when Firebase isn't configured.

### Map & geocoding
Uses `flutter_map` and the `geocoding` package (native platform geocoder, no API
key) to turn a client's address into a map pin when you save it.

**Map tiles:** production builds use **Stadia Maps** (free tier, no credit card —
get a key at https://client.stadiamaps.com/ and allow the `app.auaha.shoein`
bundle id). Pass the key at build time:

```bash
flutter run --dart-define=STADIA_API_KEY=YOUR_KEY
```

The CI deploy workflows read it from the `STADIA_API_KEY` repo secret. Without a
key the app falls back to OpenStreetMap's public tiles — fine for local dev, but
they must **not** ship to production (hence the console usage-policy warning).
Tile source + attribution live in `lib/core/presentation/map_tiles.dart`.

## Running
```bash
flutter pub get
flutter run   # demo mode; any email/password signs in
```
Min iOS deployment target is **15.0** (Firebase).

### Enabling Firebase
1. `flutterfire configure` (generates `lib/firebase_options.dart` + native config)
2. In `lib/core/services/firebase_bootstrap.dart`, initialize with
   `DefaultFirebaseOptions.currentPlatform`. `firebaseReady` flips true and the
   app switches from the demo store to Firestore automatically.
3. Deploy the security rules: `firebase deploy --only firestore:rules`
   (`firestore.rules` = each farrier can only access their own data).

## Firestore layout
```
users/{uid}/clients/{clientId}
users/{uid}/clients/{clientId}/horses/{horseId}
```

## Roadmap
- Service history log per horse (not just last date) + reminders
- Invoicing / cost per visit
- Route planning across a day's clients
