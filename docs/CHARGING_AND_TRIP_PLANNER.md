# Nearby Charging & Smart Trip Planner

## Purpose
Discover compatible public EV charging stations near a chosen location or along a planned journey, for electric cars and scooters.

## User journeys
1. Nearby: ask for location permission or enter a location manually; display chargers on map and list.
2. Filter: vehicle, connector, AC/DC, power, network, radius, saved favourites.
3. Plan: enter start, destination, battery %, reserve %, and optional waypoints.
4. Prompt: type "Plan Kochi to Thrissur with 45% battery and 20% reserve"; parse into editable fields and confirm before planning.
5. Route: fetch driving route, find compatible chargers in a configurable corridor, estimate remaining energy, recommend feasible stops and display detour and estimated charging time.
6. Navigate: open an installed map application for turn-by-turn navigation.

## Implementation boundaries
- Flutter: geolocator, flutter_map, SQLite and Riverpod; map tiles and charger directory via replaceable provider interfaces.
- Candidate public station source: Open Charge Map. Validate licensing, rate limits, accuracy and coverage; don't assume live occupancy data.
- Routing: provider adapter (self-hosted or approved hosted directions API); provider credentials must not be embedded as secrets in a public build.
- Offline: saved plans and cached stations remain viewable with clear stale-data indicators; fresh search/routing requires network.
- Privacy: device location only with consent; no background tracking by default; route history stays local.

## Planning algorithm (initial)
1. Validate vehicle battery capacity, efficiency and connector compatibility.
2. Determine route distance and geometry.
3. Estimate energy required from observed Wh/km, adjusted by optional user margin; report uncertainty.
4. Search chargers near route, filter for connectors and operational information.
5. Select reachable stops while respecting minimum battery reserve; minimize detours and unnecessary charging time.
6. Flag infeasible routes or missing charger data instead of presenting an unsafe plan.

## Acceptance criteria
- Location denied and GPS unavailable work through manual location.
- Scooter and car connector filters remain separate.
- Never claim a charger is available without reliable live status.
- No route returned if estimated energy makes all proposed stops unreachable; show a warning and alternatives.
- Unit tests cover SOC, range, reserve, connector filtering, route feasibility, and stale cache.
- Screen-reader labels, map/list alternatives, and low-connectivity behaviour are tested.

## Future enhancements
Optional AI-assisted prompt parsing, crowdsourced station reviews, operator deep links and live status integrations when legally available.
