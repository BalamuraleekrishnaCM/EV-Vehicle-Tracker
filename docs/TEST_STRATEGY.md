# Test strategy and quality gates

## Pull request gates
1. Format (`dart format --output=none --set-exit-if-changed lib test`).
2. Static analysis (`flutter analyze`).
3. Unit and widget tests (`flutter test`).
4. Android debug build once platform scaffolding exists.
5. Security/dependency scan and no committed secrets.
6. Documentation, changelog and data migration impact.
7. Maintainer approval and resolved review conversations.

## Test matrix
| Area | Required scenarios |
|---|---|
| Garage | car/scooter create, invalid battery, archive, vehicle isolation |
| Charging | energy/cost precision, negative values, timezones, duplicate sessions |
| Trips | reserve edge cases, unknown SOC, unreachable chargers, stale routing |
| Maps | location denied, manual location, offline, connector incompatibility |
| Health | manual issue provenance, repeat faults, no unsupported diagnosis |
| Finance | rounding, zero-interest loan, EMI schedule, payment adjustments |
| SQLite | migration upgrade, foreign keys, backup/restore, corruption handling |
| Sync | cross-account RLS denial, offline retries, conflict/tombstones |
| Accessibility | large text, screen readers, color contrast, touch targets |
| Release | clean checkout, Android/iOS smoke, no keys in build artifacts |

## Environments
Dev uses sample fixtures explicitly labeled as demo; CI uses ephemeral test databases and mock providers; production requires explicit opt-in for external integrations. Never put real VINs, plates, private routes, tokens or personal records in tests.

## Release rules
GitHub test artifacts only after validation and owner approval. Store publication postponed.
