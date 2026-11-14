# External integration contracts

All integrations are optional and are **not** live implementations until verified.

## Charging directory
`GET nearby(lat, lon, radiusKm, connectorFilters)` returns `Station{id, provider, name, coordinate, connectors[], powerKw?, availability: known|unknown, verifiedAt?, attribution}`. Map OCM data through a typed adapter; use API keys only as permitted by provider terms. Cache with TTL, disclose stale data, and open the source listing for verification.

## Geocoding and routing
`searchLocation(text)` -> candidate places with provider attribution. `route(origin, destination, via, vehicleProfile)` -> route geometry, distance, duration, legs and source. Show confirmation before navigating. Follow OSM tile/geocoding usage policies; never assume free public endpoints allow unrestricted commercial traffic.

## Trip planning
Input: vehicle ID, battery usable kWh, observed efficiency, departure SOC, minimum reserve, route, connector compatibility, charging power and user constraints. Output: route options, estimated energy, projected arrival SOC, compatible charging candidates, alternates, warning list and provenance. Require route feasibility checks, charging taper assumptions and a conservative margin; do not promise arrival range.

## Vehicle telemetry
`capabilities(vehicleProfile)`, `discover(consent)`, `connect()`, `readSnapshot()`, `disconnect()`. Snapshot fields may include SOC, odometer, range, fault codes and temperature **only when actually supported**; each reading includes source and timestamp. BLE, OBD and OEM adapters must never imply a universal EV protocol.

## Sync
Local `SyncRecord{id, ownerId, entityType, version, updatedAt, deletedAt, payload}`; upload is opt-in, authenticated, idempotent, retries with backoff. Conflict policy must be explicit and auditable. No server-side authoritative overwrites of local data without confirmation.

## Community
`submitReport(stationId, status, observedAt, evidence?)` requires explicit opt-in and moderation. Reports are unverified user observations, not operator-confirmed availability. Prevent PII leakage and rate-limit abuse.

## Failure handling
Typed failures: permissionDenied, offline, unauthorized, unsupportedVehicle, rateLimited, staleData, unavailable, conflict, invalidInput. Never silently substitute invented station or vehicle data.
