import 'package:flutter_test/flutter_test.dart';

import '../../../workouts/domain/entities/workout_enums.dart';
import '../../domain/entities/protocol.dart';
import 'protocol_model.dart';

void main() {
  group('ProtocolModel', () {
    test('round-trip preserves prescription, dates, and workoutIds', () {
      final start = DateTime.utc(2026, 4, 27);
      final end = DateTime.utc(2026, 6, 8);
      final protocol = Protocol(
        id: 'ground-up-2026-04-27',
        userId: 'u1',
        name: 'From the Ground Up',
        kind: ProtocolKind.physio,
        startDate: start,
        endDate: end,
        durationWeeks: 6,
        prescription: 'All exercises every day, 1 set each, 6 weeks.',
        workoutIds: const ['ground-up'],
        status: ProtocolStatus.active,
      );

      final map = ProtocolModel.fromEntity(protocol).toFirestore();
      expect(map['name'], 'From the Ground Up');
      expect(map['kind'], 'physio');
      expect(map['status'], 'active');
      expect(map['durationWeeks'], 6);
      expect(map['workoutIds'], ['ground-up']);
      expect(
          map['prescription'], 'All exercises every day, 1 set each, 6 weeks.');
    });
  });
}
