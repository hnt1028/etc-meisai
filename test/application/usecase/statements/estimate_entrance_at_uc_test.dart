import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/usecase/statements/estimate_entrance_at_uc.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

StatementLineDTO _line({
  String? entranceIc = '北',
  String exitIc = '東',
  DateTime? exitAt,
}) => StatementLineDTO(
  entranceAt: null,
  exitAt: exitAt ?? DateTime(2026, 1, 10, 9, 15),
  entranceIc: entranceIc,
  exitIc: exitIc,
  grossFare: null,
  etcDiscount: null,
  fare: 100,
  fareAfterRebate: 100,
  postpaidFare: 100,
  vehicleType: VehicleTypeValue.standard,
  vehicleNumber: 1,
  cardNumberSuffix: '0001',
  status: ConfirmationStatusValue.confirmed,
  discountTypes: const [],
);

/// 北 and 東 are [meters] apart along the road, on [route].
FakeIcMasterIF _master(int meters, {String route = '東名高速道路'}) => FakeIcMasterIF(
  [
    fakeIcPoint(name: '北', routeNames: [route]),
    fakeIcPoint(name: '東', routeNames: [route]),
  ],
  links: [IcLinkEntity(fromId: 'id-北', toId: 'id-東', meters: meters)],
);

EstimateEntranceAtUC _uc(
  FakeIcMasterIF master, {
  FakeIcPositionIF? positions,
}) => EstimateEntranceAtUC(
  icMaster: master,
  icMappings: FakeIcMappingIF(),
  icPositions: positions ?? FakeIcPositionIF(),
);

void main() {
  group('EstimateEntranceAtUC', () {
    test('takes the time at 80 km/h off the exit', () async {
      // 40 km at 80 km/h is 30 minutes: 09:15 - 0:30.
      final at = await _uc(_master(40000)).execute(_line());

      expect(at, DateTime(2026, 1, 10, 8, 45));
    });

    test('uses 60 km/h on an urban expressway', () async {
      // 30 km at 60 km/h is 30 minutes (at 80 km/h, 22.5 minutes).
      final at = await _uc(_master(30000, route: '首都高速4号新宿線')).execute(_line());

      expect(at, DateTime(2026, 1, 10, 8, 45));
    });

    test('uses 80 km/h on the roads of two operators, and of none', () async {
      // 東名 and 首都高: two operators.
      final mixed = FakeIcMasterIF(
        [
          fakeIcPoint(name: '北', routeNames: const ['東名高速道路']),
          fakeIcPoint(name: '東', routeNames: const ['首都高速4号新宿線']),
        ],
        links: const [
          IcLinkEntity(fromId: 'id-北', toId: 'id-東', meters: 40000),
        ],
      );
      expect(await _uc(mixed).execute(_line()), DateTime(2026, 1, 10, 8, 45));

      // A route the table does not know.
      expect(
        await _uc(_master(40000, route: '箱根ターンパイク')).execute(_line()),
        DateTime(2026, 1, 10, 8, 45),
      );
    });

    test('rounds to five minutes: 1 and 2 down, 3 and 4 up', () async {
      // The exit is 09:15, and the entrance would be 8:45 minus a few minutes.
      // 80 km/h: 1 km is 45 seconds.
      Future<DateTime?> at(int meters) => _uc(_master(meters)).execute(_line());

      // 09:15 - 30:00 = 08:45 (exact).
      expect(await at(40000), DateTime(2026, 1, 10, 8, 45));
      // 09:15 - 32:15 (43,000 m) = 08:42:45 -> 08:43 -> 08:45.
      expect(await at(43000), DateTime(2026, 1, 10, 8, 45));
      // 09:15 - 33:45 (45,000 m) = 08:41:15 -> 08:41 -> 08:40.
      expect(await at(45000), DateTime(2026, 1, 10, 8, 40));
      // 09:15 - 35:00 (46,667 m) = 08:40:00 -> 08:40.
      expect(await at(46667), DateTime(2026, 1, 10, 8, 40));
    });

    test('rounds half a minute up before rounding to five minutes', () async {
      // The exit is 09:15:00. 80 km/h: 28,667 m is 21:30 -> 08:53:30 -> 08:54
      // -> 08:55.
      final at = await _uc(_master(28667)).execute(_line());

      expect(at, DateTime(2026, 1, 10, 8, 55));
    });

    test('goes back over midnight to the day before', () async {
      // 40 km at 80 km/h from 00:10 is 23:40 of the day before.
      final at = await _uc(
        _master(40000),
      ).execute(_line(exitAt: DateTime(2026, 1, 10, 0, 10)));

      expect(at, DateTime(2026, 1, 9, 23, 40));
    });

    test('does not put the entrance after the exit', () async {
      // Almost no distance, and an exit that rounds up: 09:13 -> 09:15.
      final exit = DateTime(2026, 1, 10, 9, 13);

      final at = await _uc(_master(0)).execute(_line(exitAt: exit));

      expect(at, exit);
    });

    test('is the exit time when the two ICs are one point', () async {
      final exit = DateTime(2026, 1, 10, 9, 15);

      final at = await _uc(
        _master(1000),
      ).execute(_line(entranceIc: '北', exitIc: '北', exitAt: exit));

      expect(at, exit);
    });

    test('is null when the entrance IC is blank', () async {
      expect(
        await _uc(_master(40000)).execute(_line(entranceIc: null)),
        isNull,
      );
    });

    test('is null when a position is not known', () async {
      expect(await _uc(_master(40000)).execute(_line(exitIc: '不明')), isNull);
      expect(
        await _uc(_master(40000)).execute(_line(entranceIc: '不明')),
        isNull,
      );
    });

    test('measures straight between positions the user chose', () async {
      // 0.4 degrees of latitude are about 44.4 km: 33.3 minutes at 80 km/h.
      final positions = FakeIcPositionIF()
        ..stored.addAll(const [
          IcPositionEntity(icName: '甲', latitude: 35.0, longitude: 139.0),
          IcPositionEntity(icName: '乙', latitude: 35.4, longitude: 139.0),
        ]);

      final at = await _uc(
        FakeIcMasterIF([]),
        positions: positions,
      ).execute(_line(entranceIc: '甲', exitIc: '乙'));

      // 09:15 - 33:20 = 08:41:40 -> 08:42 -> 08:40.
      expect(at, DateTime(2026, 1, 10, 8, 40));
    });

    test('uses the straight distance when the links do not connect', () async {
      // 0.4 degrees of latitude, with no links.
      final master = FakeIcMasterIF([
        fakeIcPoint(name: '北', latitude: 35.0, longitude: 139.0),
        fakeIcPoint(name: '東', latitude: 35.4, longitude: 139.0),
      ]);

      final at = await _uc(master).execute(_line());

      expect(at, DateTime(2026, 1, 10, 8, 40));
    });

    test('passes on a failure to read', () {
      final master = FakeIcMasterIF([])..error = StateError('x');

      expect(_uc(master).execute(_line()), throwsStateError);
    });
  });
}
