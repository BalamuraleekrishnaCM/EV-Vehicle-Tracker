# Architecture

## Goals
Cross-platform Android/iOS Flutter app; offline-first; multiple EVs (cars and scooters); modular contributions; no mandatory account, cloud, GPS or proprietary vehicle API.

## Layers
- Presentation: Material 3 screens, adaptive layouts, Riverpod state.
- Domain: vehicle, charge, trip, expense, service, finance and document models; validation and calculations.
- Data: repository interfaces, SQLite adapters, schema migrations, import/export.

## Local schema (planned)
- vehicles: id, type (car/scooter), brand, model, variant, battery_kwh, purchase_date, odometer_km.
- charges: id, vehicle_id, started_at, ended_at, soc_start, soc_end, energy_kwh, tariff_per_kwh, amount, charging_type.
- trips: id, vehicle_id, date, odometer_start, odometer_end, energy_kwh, notes.
- expenses: id, vehicle_id, date, category, amount, currency, notes.
- services: id, vehicle_id, date, odometer_km, type, amount, next_due_date, next_due_km.
- documents: id, vehicle_id, kind, local_uri, expiry_date.
- finance: id, vehicle_id, category, amount, due_date, paid_date.

All vehicle-linked tables use foreign keys; SQLite foreign-key enforcement is enabled. Money uses integer minor units where practical; timestamps use UTC with local presentation. Database schema migrations and versioned backup formats are mandatory.

## Calculations
- Charging cost = metered kWh × applicable tariff; if metered energy is missing, report an estimate separately.
- Trip distance = ending odometer − starting odometer, validated nonnegative.
- Energy cost/km = charging spend / tracked distance for the same period (label coverage and limitations).
- Wh/km = 1000 × measured energy kWh / distance km.
- Total cost of ownership reports distinguish acquisition, financing, recurring expenses and estimated depreciation; avoid double-counting principal and purchase price.

## Privacy and security
SQLite database stored in app-private storage; attachments in private app storage. Optional encrypted backup and platform key storage are future enhancements, not currently implemented. No secret keys or personal data in Git. Export/import must validate schema and support recovery from failed imports.

## Modules
garage, charging, trips, expenses, maintenance, finance, documents, analytics, settings, backup.

## Testing
Unit tests for calculations and migrations; widget tests for entry forms; integration tests for backup/restore and multi-vehicle isolation. CI runs formatting, analysis and tests.
