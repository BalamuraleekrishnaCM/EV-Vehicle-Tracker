class EnergyEstimate {
  const EnergyEstimate({required this.energyKwh, required this.arrivalSocPercent, required this.feasible});
  final double energyKwh;
  final double arrivalSocPercent;
  final bool feasible;
}

EnergyEstimate estimateJourney({
  required double distanceKm,
  required double batteryKwh,
  required double whPerKm,
  required double departureSocPercent,
  double reservePercent = 20,
}) {
  if (distanceKm < 0 || batteryKwh <= 0 || whPerKm <= 0 ||
      departureSocPercent < 0 || departureSocPercent > 100 ||
      reservePercent < 0 || reservePercent > 100) {
    throw ArgumentError('Invalid trip inputs');
  }
  final energyKwh = distanceKm * whPerKm / 1000;
  final arrival = departureSocPercent - energyKwh / batteryKwh * 100;
  return EnergyEstimate(
    energyKwh: energyKwh,
    arrivalSocPercent: arrival,
    feasible: arrival >= reservePercent,
  );
}
