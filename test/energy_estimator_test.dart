import 'package:flutter_test/flutter_test.dart';
import 'package:ev_vehicle_tracker/domain/energy_estimator.dart';

void main() {
  test('estimates energy and reserve', () {
    final estimate = estimateJourney(
      distanceKm: 60,
      batteryKwh: 4,
      whPerKm: 40,
      departureSocPercent: 90,
      reservePercent: 20,
    );
    expect(estimate.energyKwh, closeTo(2.4, 0.0001));
    expect(estimate.arrivalSocPercent, closeTo(30, 0.0001));
    expect(estimate.feasible, isTrue);
  });
  test('rejects invalid battery capacity', () {
    expect(() => estimateJourney(distanceKm: 20, batteryKwh: 0, whPerKm: 100, departureSocPercent: 80), throwsArgumentError);
  });
}
