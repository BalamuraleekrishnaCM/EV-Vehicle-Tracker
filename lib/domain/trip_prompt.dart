class TripPrompt {
  const TripPrompt({
    required this.origin,
    required this.destination,
    this.socPercent,
    this.reservePercent = 20,
  });
  final String origin;
  final String destination;
  final double? socPercent;
  final double reservePercent;
}

/// Intentionally limited deterministic parser; ambiguous input requires confirmation.
TripPrompt? parseTripPrompt(String prompt) {
  final route = RegExp(
    r'^(?:(?:plan|drive)(?:\s+a\s+trip)?\s+)?(?:from\s+)?(.+?)\s+to\s+(.+?)(?:\s+with\b|\s+starting\b|\s+keep\b|$)',
    caseSensitive: false,
  ).firstMatch(prompt.trim());
  if (route == null) return null;
  final origin = route.group(1)!.trim();
  final destination = route.group(2)!.trim();
  if (origin.isEmpty || destination.isEmpty) return null;
  final soc = RegExp(
    r'(?:with|at|starting(?: at)?)\s+(-?\d+(?:\.\d+)?)\s*%',
    caseSensitive: false,
  ).firstMatch(prompt);
  final reserve = RegExp(
    r'(?:reserve|keep(?: at least)?)\s+(-?\d+(?:\.\d+)?)\s*%',
    caseSensitive: false,
  ).firstMatch(prompt);
  final charge = soc == null ? null : double.parse(soc.group(1)!);
  final minimum = reserve == null ? 20.0 : double.parse(reserve.group(1)!);
  if ((charge != null && (charge < 0 || charge > 100)) ||
      minimum < 0 ||
      minimum > 100) {
    return null;
  }
  return TripPrompt(
    origin: origin,
    destination: destination,
    socPercent: charge,
    reservePercent: minimum,
  );
}
