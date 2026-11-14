# Maintainer SDLC checklist

## Issue
- [ ] Problem statement, user story, acceptance criteria, affected EV types
- [ ] UX states, accessibility, privacy, offline and API failure cases
- [ ] Data migration, dependency and security considerations

## PR
- [ ] Feature branch and Conventional Commits
- [ ] Linked issue and updated README/TODO/ROADMAP where applicable
- [ ] Tests for business rules and regression risks
- [ ] Format/analyze/test/build pass; screenshots for UI changes
- [ ] No secrets, personal data or unjustified new permissions
- [ ] CODEOWNERS review and maintainer approval

## Release
- [ ] Version and changelog, signed reproducible builds, QA devices
- [ ] Privacy policy, OSS attribution and provider terms
- [ ] Backup/migration rollback plan
- [ ] Maintainer explicit approval
- [ ] Store submission **not authorized** until separately requested

Repository owner must configure branch rulesets: require PRs, CODEOWNERS review, status checks, no force pushes and no bypass where supported. CODEOWNERS alone does not enforce approvals.
