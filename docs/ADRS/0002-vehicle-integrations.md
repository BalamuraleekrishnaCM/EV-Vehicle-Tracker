# ADR-0002: Capability-gated read-only integrations

Status: Accepted as design direction; implementation pending.

Only documented and authorized BLE/OBD/OEM providers are allowed. Each adapter declares supported models, fields and permissions. Remote commands are out of scope until separately designed, security-reviewed and approved. Unknown or stale values must be shown as unknown.
