# Roadmap

The following are **planned milestones**, not completed releases.

- **M0 / v0.1.0 — Foundation:** Flutter Android/iOS project, Material 3 theme, routing, CI, linting, tests, docs.
- **M1 / v0.2.0 — Garage:** create/edit/archive car and scooter profiles, odometer validation.
- **M2 / v0.3.0 — Charging:** manual charge logs, tariffs, home/public AC/DC options, cost calculations.
- **M3 / v0.4.0 — Trips:** odometer-based trip records, efficiency and range analytics.
- **M4 / v0.5.0 — Expenses & finance:** categorized costs, loans, insurance, acquisition cost.
- **M5 / v0.6.0 — Maintenance:** service records, warranty and expiry reminders.
- **M6 / v0.7.0 — Documents & backups:** attachments, CSV/JSON export, validated restore.
- **M7 / v0.8.0 — Analytics:** per-vehicle and fleet dashboards, period filters, cost/km.
- **M8 / v0.9.0 — Quality:** accessibility, localization, performance, data migrations and beta testing.
- **M9 / v1.0.0 — Stable:** Android and iOS release builds, release notes, user guide.

### Acceptance gates
Each milestone requires tests, offline functionality, privacy review, documentation, and successful Android build; iOS validation requires macOS/Xcode.

### Community proposals
Support new manufacturers and vehicle categories through optional model metadata and independent feature modules, without requiring official vehicle APIs.

## Charging discovery and trip planner expansion
- **M10 — Nearby charging:** opt-in GPS, manual location, OpenStreetMap map/list, station directory adapter, connector filtering, cache, favourites and attribution.
- **M11 — Route planning:** start/end/waypoints, routing provider adapter, station corridor search, battery reserve, charging stop selection, detour and time/cost estimates.
- **M12 — Prompt planner:** deterministic prompt parsing with confirmation screen, editable inputs, no mandatory AI account/API.
- **M13 — Safety and quality:** station freshness indicators, unknown availability warnings, no-compatible-station handling, permission-denied and offline states, tests for route feasibility and energy calculations.
