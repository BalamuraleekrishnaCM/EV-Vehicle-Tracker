# TODO — EV Vehicle Tracker

> Source of truth for delivery work. See [ROADMAP.md](ROADMAP.md), [GitHub Issues](https://github.com/BalamuraleekrishnaCM/EV-Vehicle-Tracker/issues), and [implementation status](docs/IMPLEMENTATION_STATUS.md).
> Checked boxes require verified tests/builds, not merely committed code.

## P0 — Make foundation buildable
- [x] Add initial Flutter source, SQLite schema, basic UI, domain calculations and unit-test source (PR #1; **unverified**).
- [x] Add CI workflow, contribution templates, CODEOWNERS and SDLC documentation (PR #1; enforcement pending).
- [ ] Generate Android and iOS Flutter platform projects and verify clean checkout. (#2)
- [ ] Run formatter, analyzer, tests and Android debug build; fix all failures. (#2)
- [ ] Establish automated coverage, migration tests and reproducible dependency lockfile.
- [ ] Configure protected main, required status checks and maintainer review. (#7)

## P1 — Core ownership
- [ ] Vehicle create/edit/archive/delete with confirmation, variant, odometer and validation.
- [ ] Structured charge sessions, energy, SOC, tariff, home/public and cost.
- [ ] Trips, efficiency history, range estimates and reserve warnings.
- [ ] Expenses, purchase, insurance, financing and EMI schedules.
- [ ] Maintenance, service, warranty cases, fault timeline and reminders. (#6)
- [ ] Documents, export/import, versioned backup, integrity and restore tests.
- [ ] Per-vehicle and overall cost/energy dashboards.

## P2 — Charging and route planning
- [ ] Opt-in device location and manual location; map/list UI. (#3)
- [ ] Provider integration, attribution, cache, freshness, connector compatibility and favourites. (#3)
- [ ] Route geometry, stop selection, alternate chargers, detours and conservative battery budget. (#4)
- [ ] Prompt-to-trip parsing with editable confirmation, failure handling and no mandatory paid AI. (#4)
- [ ] Verify charger availability claims; distinguish live, reported and unknown states.

## P3 — Optional connectivity
- [ ] Capability-based vehicle data provider and explicit consent. (#5)
- [ ] BLE scan/connect for documented compatible interfaces.
- [ ] Read-only OBD profiles with verified vehicle/adapter support.
- [ ] Authorized manufacturer API integrations only; no password scraping or undocumented commands.
- [ ] Device simulator and hardware test matrix.

## P4 — Open-source quality
- [ ] Add accessibility and localization checks, contribution guide and architecture decision records.
- [ ] Add security/dependency/secret scans and privacy review.
- [ ] Add community feedback/charger reports only with opt-in sharing and moderation.
- [ ] Create contributor-friendly good-first-issues and maintainers' triage process.
- [ ] Verify Android and iOS release candidates on physical devices.
- [ ] Publish GitHub test builds only after validation and maintainer approval.
- [ ] **Store publication deferred** until explicit owner request.

## Governance
All contributions use issues and pull requests. @BalamuraleekrishnaCM approves merges and official releases. A checklist is not an authorization to merge or publish. Keep TODO, README, ROADMAP, implementation status and issues aligned with verified functionality.

## Minimal EV dashboard UI workstream
- [x] Implement light EV theme and reusable UI primitives (code added; build verification pending).
- [x] Implement five-tab navigation shell and local garage entry point (code added; build verification pending).
- [x] Add safe charging/health/analytics placeholders without fake live data.
- [x] Add editable trip energy estimate UI using domain calculations.
- [ ] Validate dashboard on Flutter SDK, run analyzer/tests and fix layout/overflow errors.
- [ ] Wire charging, trip logs, health and analytics to structured SQLite models and migrations.
- [ ] Implement live station provider, map, routing and charger compatibility.
- [ ] Add accessibility, widget tests, offline/error handling and responsive tablet layouts.

## Full-stack architecture implementation backlog
- [x] Document full frontend/backend feature boundaries, data entities and provider contracts (design only).
- [x] Add architecture decision records and security/test strategy (design only).
- [x] Add optional Supabase SQL schema **draft** with owner-scoped RLS (not deployed/tested).
- [x] Add read-only telemetry and routing provider interfaces with offline contracts (unverified tests).
- [ ] Generate native Flutter Android/iOS scaffolding; run format/analyze/tests/build.
- [ ] Implement SQLite schema migrations and structured repositories for all entities.
- [ ] Wire screens to real use cases, forms, loading/empty/error states and accessible navigation.
- [ ] Implement and contract-test external charging, routing and geocoding adapters.
- [ ] Implement opt-in sync with conflict handling, RLS isolation tests and private storage policies.
- [ ] Configure GitHub branch protection, status checks, code owner approval and security scans.
- [ ] Run Android/iOS end-to-end tests and owner-approved GitHub beta release.
- [ ] Store publication remains deferred.
