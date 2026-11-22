# EV Vehicle Tracker

EV Vehicle Tracker is an offline-first Flutter app for electric cars and scooters on Android and iOS.

## Features

- Manage multiple vehicles and track charging, trips, purchases, expenses, installments, maintenance, warranty and insurance.
- Review paid amounts by category, metered energy, trip efficiency and due dates.
- Save a JSON backup, restore local records or export records as CSV.
- Find nearby mapped chargers by GPS or coordinates, filter by connector and open a result in OpenStreetMap.
- Turn a trip prompt into editable fields and calculate an offline energy estimate. Development builds can point to an OSRM service for road distances and one-stop charging checks.

See the [implementation status](docs/IMPLEMENTATION_STATUS.md) and [roadmap](ROADMAP.md) for outstanding work.

## Run locally

Install Flutter 3.38.9 or later, then set up the Android SDK or Xcode. iOS builds require macOS.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Online charger searches send the requested coordinates to an Overpass instance. Configure an approved instance using the optional `EV_OVERPASS_URL` Dart define. Road routing is enabled when `EV_OSRM_URL` is set to an approved OSRM base URL.

```bash
flutter run --dart-define=EV_OSRM_URL=https://routing.example.org
```

Trip estimates depend on your input. Station listings indicate mapped infrastructure. Confirm vehicle access and operating status before setting out.

## Data and development

Ownership records are saved to SQLite on your device. Backup files contain the same personal data and should be stored privately. See [SECURITY.md](SECURITY.md) and [ARCHITECTURE.md](ARCHITECTURE.md).

The [contribution guide](CONTRIBUTING.md), [development checklist](TODO.md) and [release policy](docs/RELEASE_POLICY.md) describe review and validation. The [optional Supabase schema draft](backend/supabase/schema_draft.sql) is separate from the running app. Official releases require maintainer approval.

This independent project has no vehicle manufacturer affiliation. Licensed under [MIT](LICENSE).
