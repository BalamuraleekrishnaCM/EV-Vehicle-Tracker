# Implementation status

## Available on the implementation branch

- Android and iOS Flutter application with local SQLite storage. Schema v2 preserves existing vehicles and ownership records from the foundation branch.
- Car and scooter profiles with variant, usable battery, odometer, connector, edit, archive and confirmed deletion.
- Editable charging and trip logs with measured energy, SOC, tariffs, charging duration, trip distance and measured trip efficiency.
- Purchase, expense, finance, insurance, maintenance, fault, warranty and document-reference logs. Generate fixed monthly installments and mark each payment individually. Due and expiry dates appear in the app.
- Per-vehicle or fleet reports for this month or all records, including paid amounts by category, metered energy, distance and charging spend per logged kilometre. Finance is listed separately from acquisition expenses.
- CSV export and versioned JSON backup to a file. Restoring a valid backup replaces all ownership records in a single SQLite transaction after confirmation.
- Nearby station search using permission-based GPS or coordinates. Results come from OpenStreetMap via Overpass. Filter by connector, open a station in OpenStreetMap, and view the last cached results offline. Favorite markers are remembered for stations in search results.
- Prompt parsing fills editable trip labels, departure SOC and reserve. Offline estimates use manual distance and consumption. Optional OSRM road routing uses coordinates and screens a limited number of compatible stations for one-stop journeys using road distances.

## Integration and release work

- Android and iOS hardware testing, store signing and a reviewed release.
- City-name geocoding, embedded maps, multi-stop routing, saved route plans, charging-time and price estimates, and dependable live availability.
- File attachments, operating-system notifications, interest and amortization schedules, and advanced ownership comparisons.
- Automated vehicle telemetry, Bluetooth / OBD, and manufacturer APIs. These need a documented compatible vehicle and adapter.
- Optional Supabase sync remains a schema draft. The app runs on local SQLite without an account.
