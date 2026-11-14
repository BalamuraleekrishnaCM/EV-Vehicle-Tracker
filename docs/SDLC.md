# Software Development Lifecycle

## Branching and changes
- `main` is protected release-quality code; no direct contributor pushes.
- Contributors work in `feat/*`, `fix/*`, `docs/*`, `chore/*` branches.
- Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.
- Every functional change references an issue and uses a pull request.
- Require the owner review, passing CI, resolved conversations and up-to-date branches before merge.
- No force pushes to `main`. Prefer squash merges.

## Definition of ready
Issue describes user problem, affected EV types, data model, privacy implications, acceptance criteria and dependencies.

## Definition of done
Tests pass, format/analyze clean, accessibility considered, docs updated, migration/rollback addressed, security reviewed, owner approved.

## Security and privacy
Least privilege, no mandatory account, on-device records by default, no credential scraping or undocumented vehicle commands. External location/charging APIs require consent, attribution, documented quotas and a failure mode.

## Releases
SemVer; changelog; tagged source; Android/iOS release verification; license/privacy/store compliance; explicit owner approval before publishing. Store signing credentials remain with the owner and never in contributor CI.

## Governance
Owner is final maintainer for roadmap, merge and release decisions. Community contributions may propose and review changes; approval is not implied by submission. CODEOWNERS is advisory until branch rules enforce reviews.

## CI gates
Flutter format, static analysis, tests. Later: dependency scanning, secret scanning, Android build, iOS build on macOS, signed release approvals.
