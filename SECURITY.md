# Security Policy

## Sensitive data
The repository must never contain real vehicle identifiers, VINs, registration documents, loan details, payment credentials, personal locations, charging histories or exported user databases.

## Reporting
Do not disclose security vulnerabilities in public issues. Contact the maintainer privately through their GitHub profile until a dedicated security advisory workflow is enabled.

## Local-first safeguards
- Store app records and attachments in app-private directories.
- Request permissions only when a feature requires them.
- Do not send telemetry or backups to third parties by default.
- Validate imported files, limit attachment sizes, and use parameterized SQL.
- Do not log personal records or credentials.
- Protect exported backups; unencrypted exports may contain sensitive data.

Encryption at rest and encrypted backups are future work, not a guarantee of the initial starter.
