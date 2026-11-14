# EV Vehicle Tracker — UX, features and implementation architecture

## Design source
Minimal light EV visual direction approved in conversation: white and soft green surfaces, green accent, ample spacing, rounded cards, readable typography, restrained imagery. Do not reproduce concept-art battery/health/availability values as live telemetry.

## Information architecture
Bottom tabs: Home, Garage, Charge, Trips, More.
- **Home**: selected vehicle, battery/range *only if connected or manually recorded with timestamp*, odometer, charging and trip quick actions, latest activity, permission status.
- **Garage**: add/edit/archive car or scooter; brand, model, variant, usable battery capacity, connector metadata, odometer, warranty.
- **Charge**: manual sessions, charging history, nearby map/list, compatibility, last-verified availability, favourite chargers, charger reports.
- **Trips**: start/end/waypoints, prompt parser with editable confirmation, vehicle selection, route, conservative SOC prediction, reachable charger stops, alternatives, trip log.
- **More**: health and issue tracking, service/warranty, ownership finance and analytics, documents, backup, settings, connectivity and community.

## Flutter package boundaries
```text
lib/
  main.dart
  ui/
    ev_theme.dart
    widgets/ev_widgets.dart
  features/
    dashboard/dashboard_shell.dart   # responsive app navigation and current UX
    garage/garage_screen.dart        # existing local CRUD
    charging/                       # future: station discovery, charge sessions
    trips/                          # future: routing and prompt planning
    vehicle_health/                 # future: issues, warranty and service
    analytics/                      # future: cost and efficiency charts
    connectivity/                   # future: authorized BLE/OBD/cloud
  domain/
    vehicle.dart
    ownership_record.dart
    energy_estimator.dart
    trip_prompt.dart
    charging_station.dart
  data/
    local_store.dart
```

## Architecture rules
1. UI never calls arbitrary external services directly; use typed repository/provider interfaces.
2. Domain calculations are pure Dart with unit tests; represent missing telemetry as unknown, not 0 or a fabricated number.
3. SQLite is the source of truth for personal records. Version schema and migrations; persist monetary amounts in minor units.
4. API integrations are optional, read-only by default, authenticated, permission-aware, rate-limited, and independently testable.
5. Vehicle-specific capabilities live in adapter metadata, not scattered conditional UI logic.
6. Charger availability must distinguish provider-verified, community-reported, stale and unknown; never imply real-time availability from a directory listing.
7. Navigation estimates require a usable battery estimate, SOC, realistic consumption and safety reserve. Do not claim a charger is reachable without route geometry and compatibility.
8. Cloud sync and community sharing must be opt-in; never upload location, VIN, plate or diagnostic records by default.
9. UI uses accessible tap targets, dynamic text, screen reader labels, loading/error/empty states and platform-safe areas.
10. Contributed code requires maintainer review; official releases and stores require explicit owner approval.

## Suggested data model (future schema migrations)
- vehicle: type, make/model/variant, battery usable kWh, odometer, plug types, archive flag
- charge_session: vehicle, start/end, SOC, measured kWh, cost, tariff, charger, AC/DC, evidence
- trip: vehicle, route, start/end odometer, start/end SOC, distance, conditions, consumption
- expense: vehicle, category, minor units, currency, date, receipt
- service_case: vehicle, severity, symptoms, evidence, warranty, job cards, timeline, resolution
- reminder: vehicle, trigger by date/odometer, completion
- vehicle_telemetry: vehicle, provider, field, unit, observed timestamp, provenance
- charger_cache: provider ID, coordinates, connectors, capacity, freshness, source
- community_report: opt-in moderated submission with privacy filtering
- sync_metadata: opt-in backend state, conflict version, last sync

## Milestones
1. **UX foundation**: theme, five-tab shell, safe empty states, data-bound garage and manual trip estimator.
2. **Core ownership**: structured charge sessions, expenses, trip log, maintenance, documents and migration tests.
3. **Discovery**: permission-based location/manual fallback, map, station API, cache, connectors, status provenance.
4. **Trip intelligence**: routing, corridor charger search, reserve calculations, prompt parsing, stop alternatives.
5. **Vehicle health**: case history, service/warranty, maintenance reminders, optional verified diagnostics.
6. **Insights**: monthly trends, cost/km, energy and battery history, per-vehicle comparison.
7. **Connectivity**: BLE, OBD and authorized OEM adapter framework, real-device tests.
8. **Community & quality**: accessible UI, localization, opt-in reports, CI, security, export/import.
9. **Release readiness**: Android/iOS QA and GitHub test artifacts. Store publication deferred.

## Definition of done
Design review; implemented and verified behavior; tests; security/privacy review; accessibility; documented limitations; no mock data presented as fact; owner-approved PR. Current dashboard implementation is UI foundation only and is not a complete product.
