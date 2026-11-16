import 'package:etc_meisai/application/usecase/statements/save_vehicle_number_uc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('SaveVehicleNumberUC', () {
    late FakeStatementLineIF lines;
    late SaveVehicleNumberUC uc;

    setUp(() {
      lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(id: 'blank', withoutVehicleNumber: true))
        ..stored.add(
          fakeStatementLine(id: 'filled', exitIc: 'C-IC', vehicleNumber: 1234),
        );
      uc = SaveVehicleNumberUC(statementLines: lines);
    });

    String? numberOf(String id) =>
        lines.stored.firstWhere((l) => l.id == id).vehicleNumber?.toString();

    test('saves the number of a line that has none', () async {
      await uc.execute(id: 'blank', vehicleNumber: 4321);

      expect(numberOf('blank'), '4321');
      // The other line is not touched.
      expect(numberOf('filled'), '1234');
    });

    test('accepts the edges of the range', () async {
      await uc.execute(id: 'blank', vehicleNumber: 1);
      expect(numberOf('blank'), '1');

      lines.stored.add(fakeStatementLine(id: 'b2', withoutVehicleNumber: true));
      await uc.execute(id: 'b2', vehicleNumber: 9999);
      expect(numberOf('b2'), '9999');
    });

    test('rejects a number out of range, saving nothing', () async {
      for (final number in [0, -1, 10000, 123456]) {
        await expectLater(
          uc.execute(id: 'blank', vehicleNumber: number),
          throwsArgumentError,
        );
      }
      expect(numberOf('blank'), isNull);
    });

    test('does not change a line that already has a number', () async {
      await expectLater(
        uc.execute(id: 'filled', vehicleNumber: 1),
        throwsStateError,
      );

      expect(numberOf('filled'), '1234');
    });

    test('cannot be done twice for one line', () async {
      await uc.execute(id: 'blank', vehicleNumber: 4321);

      await expectLater(
        uc.execute(id: 'blank', vehicleNumber: 1),
        throwsStateError,
      );
      expect(numberOf('blank'), '4321');
    });

    test('rejects an id that is not stored', () {
      expect(uc.execute(id: 'nothing', vehicleNumber: 1), throwsStateError);
    });

    test('does not put the number in an error message', () async {
      try {
        await uc.execute(id: 'filled', vehicleNumber: 4321);
        fail('should have thrown');
      } on StateError catch (e) {
        expect(e.message, isNot(contains('4321')));
      }
      try {
        await uc.execute(id: 'blank', vehicleNumber: 12345);
        fail('should have thrown');
      } on ArgumentError catch (e) {
        expect(e.message.toString(), isNot(contains('12345')));
      }
    });

    test('passes on a failure to save', () {
      lines.error = StateError('disk');

      expect(uc.execute(id: 'blank', vehicleNumber: 1), throwsStateError);
    });
  });
}
