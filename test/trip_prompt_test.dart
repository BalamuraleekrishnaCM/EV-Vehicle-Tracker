import 'package:flutter_test/flutter_test.dart';
import 'package:ev_vehicle_tracker/domain/trip_prompt.dart';

void main() {
  test('parses route with battery and reserve', () {
    final plan = parseTripPrompt('from Kochi to Thrissur with 60% keep 20%');
    expect(plan, isNotNull);
    expect(plan!.origin, 'Kochi');
    expect(plan.destination, 'Thrissur');
    expect(plan.socPercent, 60);
    expect(plan.reservePercent, 20);
  });
  test('parses drive and plan prefixes and rejects invalid percentage', () {
    expect(
      parseTripPrompt(
        'Drive from Kochi to Kozhikode starting at 60%, keep 20% reserve',
      )?.origin,
      'Kochi',
    );
    expect(
      parseTripPrompt('Plan Kochi to Thrissur with 45% battery')?.destination,
      'Thrissur',
    );
    expect(parseTripPrompt('from Kochi to Thrissur with -1%'), isNull);
  });
  test('returns null for ambiguous route', () {
    expect(parseTripPrompt('take me somewhere'), isNull);
  });
}
