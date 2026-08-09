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
The `geocoding` package (native platform geocoder, no API key) turns a client's
address into a map pin when you save it.

**Maps:** the app uses **Mapbox** (`mapbox_maps_flutter`) — modern vector maps,
same as the Prior app. The user switches map style from the layers button on the
Map screen (Standard / Satellite / Outdoors / Dark).

- The **public access token** is embedded in `lib/core/config/map_config.dart`
  (override with `--dart-define=MAPBOX_ACCESS_TOKEN=...` for a Shoein'-specific
  one). Public tokens are safe to ship; usage is billed to the Mapbox account.
  Mapbox's mobile free tier (25k MAU) covers this app's volume, commercial use
  included.
- Building requires Mapbox's **secret downloads token** (`MAPBOX_DOWNLOADS_TOKEN`,
  scope `downloads:read`) in your global `~/.gradle/gradle.properties` (Android)
  and `~/.netrc` (iOS) — the same one-time setup the Prior app uses. In CI it's
  provided as a secret.

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
