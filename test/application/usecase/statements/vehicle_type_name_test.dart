import 'dart:convert';
import 'dart:io';

import 'package:etc_meisai/application/usecase/statements/vehicle_type_name.dart';
import 'package:etc_meisai/domain/entity/vehicle_type_division_entity.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/infrastructure/repository/ic_mapping/vehicle_type_master_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

/// The real master of the app (assets/vehicle_type_master.json).
Future<List<VehicleTypeDivisionEntity>> _master() => VehicleTypeMasterRepo(
  loadJson: () async => File('assets/vehicle_type_master.json').readAsString(),
).findAll();

void main() {
  group('the master file', () {
    test('has a name or a gap for each of the numbers 1 to 5', () async {
      final divisions = await _master();

      expect(divisions, isNotEmpty);
      for (final d in divisions) {
        expect(d.names, hasLength(5), reason: d.id);
        expect(d.names.first, isNotNull, reason: '${d.id}: 1 is 普通車');
        expect(d.operators, isNotEmpty, reason: d.id);
      }
    });

    test('has the three divisions of NEXCO, by the roads', () async {
      final divisions = {for (final d in await _master()) d.id: d};

      expect(divisions['nexco-1']!.roads, isEmpty);
      expect(divisions['nexco-1']!.names[3], '中型車');
      expect(divisions['nexco-2']!.roads, contains('椎田道路'));
      expect(divisions['nexco-2']!.names[3], isNull);
      expect(divisions['nexco-3']!.roads, ['長崎バイパス']);
      expect(divisions['nexco-3']!.names[4], '軽自動車等');
    });

    test('is read once', () async {
      var reads = 0;
      final repo = VehicleTypeMasterRepo(
        loadJson: () async {
          reads++;
          return jsonEncode({'divisions': <Object>[]});
        },
      );

      expect(await repo.findAll(), isEmpty);
      expect(await repo.findAll(), isEmpty);
      expect(reads, 1);
    });
  });

  group('vehicleTypeNameOf', () {
    late List<VehicleTypeDivisionEntity> divisions;

    setUpAll(() async => divisions = await _master());

    String name(VehicleTypeValue type, List<String> routes) =>
        vehicleTypeNameOf(type, routes, divisions);

    test('uses the division 1 for the roads of NEXCO', () {
      expect(name(VehicleTypeValue.medium, ['東名高速道路']), '中型車');
      expect(name(VehicleTypeValue.light, ['関越自動車道']), '軽自動車等');
    });

    test('uses the division of the road a line ran on, for NEXCO', () {
      // The division 2 has no number 4: the name of the default table.
      expect(name(VehicleTypeValue.large, ['椎田道路']), '大型車');
      expect(name(VehicleTypeValue.medium, ['椎田道路']), '中型車');
      // The division 3 has 軽自動車等 as the number 5.
      expect(name(VehicleTypeValue.light, ['長崎バイパス']), '軽自動車等');
    });

    test('uses the division of the operator', () {
      expect(name(VehicleTypeValue.extraLarge, ['首都高速3号渋谷線']), '特大車');
      // Hiroshima Expressway has no number 4.
      expect(name(VehicleTypeValue.medium, ['広島高速1号線']), '中型車');
    });

    test('uses the default table when the operator is not known', () {
      expect(name(VehicleTypeValue.standard, []), '普通車');
      expect(name(VehicleTypeValue.light, ['未知の道路']), '軽自動車等');
      // Two operators on one line.
      expect(name(VehicleTypeValue.large, ['東名高速道路', '首都高速3号渋谷線']), '大型車');
    });

    test('uses the names of the division of the operator, if they differ', () {
      final custom = [
        const VehicleTypeDivisionEntity(
          id: 'x',
          operators: ['NEXCO東日本'],
          roads: [],
          names: ['普通車', '大型車Ⅰ', '大型車Ⅱ', null, '軽自動車'],
        ),
      ];

      expect(
        vehicleTypeNameOf(VehicleTypeValue.large, ['東北自動車道'], custom),
        '大型車Ⅰ',
      );
      expect(
        vehicleTypeNameOf(VehicleTypeValue.light, ['東北自動車道'], custom),
        '軽自動車',
      );
    });
  });

  group('the line DTOs', () {
    const divisions = [
      VehicleTypeDivisionEntity(
        id: 'x',
        operators: ['NEXCO東日本'],
        roads: [],
        names: ['普通', '大型Ⅰ', '大型Ⅱ', null, null],
      ),
    ];

    test('carry the vehicle type name of the division', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(
          fakeStatementLine(
            entranceIc: '入口',
            exitIc: '出口',
            vehicleType: VehicleTypeValue.large,
          ),
        );
      final points = [
        fakeIcPoint(name: '入口', routeNames: const ['東北自動車道']),
        fakeIcPoint(name: '出口', routeNames: const ['東北自動車道']),
      ];

      final list = await fakeListUC(
        lines,
        points: points,
        divisions: divisions,
      ).execute();
      expect(list.lines.single.vehicleTypeName, '大型Ⅰ');

      final map = await fakeRouteMapUC(
        lines,
        master: FakeIcMasterIF(points),
        divisions: divisions,
      ).execute();
      expect(map.segments.single.line.vehicleTypeName, '大型Ⅰ');
    });

    test('carry the name of the default table without a division', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(vehicleType: VehicleTypeValue.large));

      final list = await fakeListUC(lines).execute();

      expect(list.lines.single.vehicleTypeName, '大型車');
    });
  });
}
