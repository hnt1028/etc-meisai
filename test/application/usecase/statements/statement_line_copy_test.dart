import 'package:etc_meisai/application/usecase/statements/statement_line_copy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('copyWithVehicleNumber', () {
    test('changes only the vehicle number', () {
      final line = fakeStatementLine(
        id: 'a',
        withoutVehicleNumber: true,
        discountTypes: const ['深夜割引'],
        etcDiscount: -100,
        grossFare: 1100,
      );

      final copy = copyWithVehicleNumber(line, 4321);

      expect(copy.vehicleNumber, 4321);
      expect(copy.id, 'a');
      expect(copy.entranceAt, line.entranceAt);
      expect(copy.exitAt, line.exitAt);
      expect(copy.entranceIc, line.entranceIc);
      expect(copy.exitIc, line.exitIc);
      expect(copy.grossFare, 1100);
      expect(copy.etcDiscount, -100);
      expect(copy.fare, line.fare);
      expect(copy.fareAfterRebate, line.fareAfterRebate);
      expect(copy.postpaidFare, line.postpaidFare);
      expect(copy.vehicleType, line.vehicleType);
      expect(copy.cardNumber, line.cardNumber);
      expect(copy.status, line.status);
      expect(copy.discountTypes, ['深夜割引']);
      // The line itself is not changed.
      expect(line.vehicleNumber, isNull);
    });
  });

  group('copyWithEntrance', () {
    test('sets the entrance, and keeps the rest', () {
      final line = fakeStatementLine(id: 'a', withoutEntrance: true);
      final at = DateTime(2026, 1, 10, 8);

      final copy = copyWithEntrance(line, entranceAt: at, entranceIc: '北');

      expect(copy.entranceAt, at);
      expect(copy.entranceIc, '北');
      expect(copy.id, 'a');
      expect(copy.exitIc, line.exitIc);
      expect(copy.vehicleNumber, line.vehicleNumber);
      expect(copy.fare, line.fare);
      expect(line.entranceIc, isNull);
    });

    test('keeps what a null argument leaves', () {
      final line = fakeStatementLine(id: 'a', entranceIc: '南');

      final onlyAt = copyWithEntrance(line, entranceAt: DateTime(2026, 1, 1));
      final onlyIc = copyWithEntrance(line, entranceIc: '北');

      expect(onlyAt.entranceIc, '南');
      expect(onlyAt.entranceAt, DateTime(2026, 1, 1));
      expect(onlyIc.entranceAt, line.entranceAt);
      expect(onlyIc.entranceIc, '北');
    });
  });
}
