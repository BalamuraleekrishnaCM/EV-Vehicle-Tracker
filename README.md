# EV Vehicle Tracker

**One app. Every EV. Every kilometre.**

EV Vehicle Tracker is an independent, offline-first Flutter app for managing **electric cars and scooters** on Android and iOS. Track vehicle purchases, charging, trips, expenses, maintenance, warranties, documents and lifetime ownership costs without creating an account or relying on a cloud database.

> Status: project initialization. Features listed below are planned; do not assume they are implemented yet.

## Features
- **Multi-vehicle garage:** electric cars and scooters, configurable brands, models, variants, battery capacities and odometer readings.
- **Purchase & finance:** quotes, on-road cost, down payment, loan/EMI schedules, insurance, registration and accessories.
- **Charging:** home/public, AC/DC where applicable, start/end state of charge, measured kWh, tariff, duration, cost and location.
- **Trips:** distance, odometer, route notes, efficiency (Wh/km or km/kWh) and estimated running cost.
- **Service:** service history, consumables, repairs, warranty claims, reminders and receipts.
- **Expenses:** charging, service, parking, tolls, insurance, subscriptions and other vehicle-linked costs.
- **Reports:** monthly/yearly spending, energy cost/km, total ownership cost and per-vehicle comparisons.
- **Portable data:** offline SQLite, CSV export and versioned JSON backup/restore.

## Tech stack
Flutter / Dart · Riverpod · GoRouter · SQLite · Material 3 · fl_chart · GitHub Actions.

## Architecture
Feature-first modules with presentation, domain and data layers. Every record is associated with a local vehicle ID; type-specific optional fields support scooters and cars without duplicating the app. See [ARCHITECTURE.md](ARCHITECTURE.md).

## Getting started
Install Flutter and Android Studio (or VS Code); macOS and Xcode are required for iOS builds.

```bash
git clone https://github.com/BalamuraleekrishnaCM/EV-Vehicle-Tracker.git
cd EV-Vehicle-Tracker
flutter pub get
flutter run
```

These commands will work once the Flutter starter application and platform folders have been committed.

## Roadmap
See [ROADMAP.md](ROADMAP.md). Contributions and feature proposals are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md).

## Privacy
All vehicle and financial records remain on-device by default. Never commit actual registration numbers, invoices, VINs, personal routes, credentials or backups. See [SECURITY.md](SECURITY.md).

## Disclaimer
Independent community project, not affiliated with any vehicle manufacturer. Vehicle telemetry integrations require official authorization and are not included by default.

## License
MIT — see LICENSE once added.

## Nearby charging & smart trip planning (planned)
- Permission-based device location, with manual city/map-pin selection when GPS is unavailable or denied.
- Nearby charger map/list with vehicle connector compatibility, network, power, distance and last-known data freshness.
- Route-aware charging stops, detours, energy/range estimates, battery reserve and estimated cost.
- Prompt entry, e.g. "Drive from Kochi to Kozhikode starting at 60%, keep 20% reserve and stop at compatible chargers." Initial version uses deterministic parsing, not a mandatory paid AI service.
- Open external navigation, save favourites, cache station metadata, and allow user feedback.
- Charger listings are not guarantees of availability or working status; verify before travelling.

See [docs/CHARGING_AND_TRIP_PLANNER.md](docs/CHARGING_AND_TRIP_PLANNER.md).

## Development and governance
A Flutter foundation is being developed in a review branch. Current functionality is limited; check [implementation status](docs/IMPLEMENTATION_STATUS.md) before claiming a feature works. The complete phased plan is in [ROADMAP.md](ROADMAP.md).

This project welcomes community contributions under [CONTRIBUTING.md](CONTRIBUTING.md), follows the [SDLC policy](docs/SDLC.md), and requires maintainer approval for official releases under [RELEASE_POLICY.md](docs/RELEASE_POLICY.md). Community PRs must pass checks and receive owner review; GitHub branch protection must be enabled by the repository owner to enforce that rule.

## Project task tracking
- [TODO.md](TODO.md) — prioritized development checklist, linked to GitHub issues.
- [ROADMAP.md](ROADMAP.md) — release milestones and acceptance gates.
- [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) — implemented versus planned, with verification caveats.
- [docs/SDLC.md](docs/SDLC.md) — development process, reviews and quality requirements.
- [docs/RELEASE_POLICY.md](docs/RELEASE_POLICY.md) — official release and store publication controls.

**Store publication is deferred.** The maintainer must explicitly approve merges and future official releases. The foundation code is in a draft PR and has not yet passed build validation.

## Minimal EV dashboard UI
The light-green, mobile-first dashboard implementation is proposed in `feat/minimal-ev-dashboard-architecture` (not merged). It includes Home, Garage, Charge, Trips and More navigation, shared design tokens, reusable cards and safe empty states. The garage and trip energy estimate use existing local logic; live charger discovery, real telemetry and health scores are **not implemented**. See [UX architecture](docs/UX_ARCHITECTURE.md) for detailed feature design, data boundaries and phased delivery. Do not treat concept screenshots as real vehicle measurements.

## Full-stack architecture and SDLC
The proposed end-to-end design is in [Full-stack architecture](docs/FULLSTACK_ARCHITECTURE.md), [API contracts](docs/API_CONTRACTS.md), [Test strategy](docs/TEST_STRATEGY.md), and [SDLC checklist](docs/SDLC_CHECKLIST.md). [Architecture decisions](docs/ADRS/) document local-first storage and vehicle adapter safety. An **unapplied** optional backend draft with owner-scoped RLS is in [backend/supabase/schema_draft.sql](backend/supabase/schema_draft.sql). None of this implies a live Supabase deployment, verified builds, or completed feature modules. Store publication remains deferred.
