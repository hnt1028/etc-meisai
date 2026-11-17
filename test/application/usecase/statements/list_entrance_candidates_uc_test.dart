import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/usecase/statements/list_entrance_candidates_uc.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

StatementLineDTO _line({String exitIc = '出口'}) => StatementLineDTO(
  entranceAt: null,
  exitAt: DateTime(2026, 1, 10, 9),
  entranceIc: null,
  exitIc: exitIc,
  grossFare: null,
  etcDiscount: null,
  fare: 100,
  fareAfterRebate: 0,
  postpaidFare: 100,
  vehicleType: VehicleTypeValue.standard,
  vehicleTypeName: '普通車',
  vehicleNumber: 1,
  cardNumberSuffix: '0001',
  status: ConfirmationStatusValue.confirmed,
  discountTypes: const [],
);

/// 出口 is at (35.0, 139.0) on R1. 近 and 遠 are on R1, 他 is on R2 only.
FakeIcMasterIF _master() => FakeIcMasterIF([
  fakeIcPoint(
    name: '出口',
    routeNames: const ['R1'],
    latitude: 35.0,
    longitude: 139.0,
  ),
  fakeIcPoint(
    name: '遠',
    routeNames: const ['R1'],
    latitude: 35.5,
    longitude: 139.0,
  ),
  fakeIcPoint(
    name: '近',
    routeNames: const ['R1', 'R2'],
    latitude: 35.1,
    longitude: 139.0,
  ),
  fakeIcPoint(
    name: '分岐',
    kind: IcKindValue.junction,
    routeNames: const ['R1'],
    latitude: 35.05,
    longitude: 139.0,
  ),
  fakeIcPoint(
    name: '料金所',
    kind: IcKindValue.other,
    routeNames: const ['R1'],
    latitude: 35.2,
    longitude: 139.0,
  ),
  fakeIcPoint(
    name: '他',
    routeNames: const ['R2'],
    latitude: 35.01,
    longitude: 139.0,
  ),
]);

ListEntranceCandidatesUC _uc(
  FakeStatementLineIF lines, {
  FakeIcMasterIF? master,
  FakeIcMappingIF? mappings,
}) => ListEntranceCandidatesUC(
  statementLines: lines,
  icMaster: master ?? _master(),
  icMappings: mappings ?? FakeIcMappingIF(),
  icPositions: FakeIcPositionIF(),
);

void main() {
  group('the ICs on the routes of the exit', () {
    test('are the points that share a route, the nearest first', () async {
      final result = await _uc(FakeStatementLineIF()).execute(_line());

      // 他 is on another route, 分岐 is a junction, and 出口 is the exit.
      expect(result.sameRoute.map((c) => c.icName), ['近', '料金所', '遠']);
      expect(result.sameRoute.first.routeNames, ['R1', 'R2']);
      expect(result.sameRoute.every((c) => c.uses == 0), isTrue);
      expect(result.used, isEmpty);
    });

    test('are none when the exit is not a point of the master', () async {
      final result = await _uc(
        FakeStatementLineIF(),
      ).execute(_line(exitIc: '不明'));

      expect(result.sameRoute, isEmpty);
    });

    test('are none when the exit has no route', () async {
      final master = FakeIcMasterIF([
        fakeIcPoint(name: '出口', routeNames: const []),
        fakeIcPoint(name: '近', routeNames: const []),
      ]);

      final result = await _uc(
        FakeStatementLineIF(),
        master: master,
      ).execute(_line());

      expect(result.sameRoute, isEmpty);
    });

    test('keep one point for one name', () async {
      final master = FakeIcMasterIF([
        fakeIcPoint(name: '出口', routeNames: const ['R1']),
        fakeIcPoint(id: 'a', name: '同名', routeNames: const ['R1']),
        fakeIcPoint(id: 'b', name: '同名', routeNames: const ['R1']),
      ]);

      final result = await _uc(
        FakeStatementLineIF(),
        master: master,
      ).execute(_line());

      expect(result.sameRoute.map((c) => c.icName), ['同名']);
    });
  });

  group('the ICs in use', () {
    test('count the entrances, those of the same exit first', () async {
      final lines = FakeStatementLineIF()
        ..stored.addAll([
          fakeStatementLine(entranceIc: 'テスト北ＩＣ', exitIc: '出口'),
          fakeStatementLine(entranceIc: 'テスト北ＩＣ', exitIc: '出口'),
          fakeStatementLine(entranceIc: '西ＩＣ', exitIc: '出口'),
          fakeStatementLine(entranceIc: '東ＩＣ', exitIc: '別の出口'),
          fakeStatementLine(entranceIc: '東ＩＣ', exitIc: '別の出口'),
          fakeStatementLine(entranceIc: '東ＩＣ', exitIc: '別の出口'),
          // A blank entrance is not a choice.
          fakeStatementLine(exitIc: '出口', withoutEntrance: true),
        ]);

      final result = await _uc(lines).execute(_line());

      expect(result.used.map((c) => (c.icName, c.uses)), [
        ('テスト北ＩＣ', 2),
        ('西ＩＣ', 1),
        ('東ＩＣ', 0),
      ]);
    });

    test(
      'are ordered by all the uses, then by name, with no exit use',
      () async {
        final lines = FakeStatementLineIF()
          ..stored.addAll([
            fakeStatementLine(entranceIc: 'あ', exitIc: 'x'),
            fakeStatementLine(entranceIc: 'い', exitIc: 'x'),
            fakeStatementLine(entranceIc: 'い', exitIc: 'x'),
            fakeStatementLine(entranceIc: 'う', exitIc: 'x'),
          ]);

        final result = await _uc(lines).execute(_line());

        expect(result.used.map((c) => c.icName), ['い', 'あ', 'う']);
      },
    );

    test('have the routes of the line they would make', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '近', exitIc: '出口'));

      final result = await _uc(lines).execute(_line());

      expect(result.used.single.routeNames, ['R1']);
    });

    test('take out the same point from the list of the same route', () async {
      // 近ＩＣ is the point 近 (by its name without IC), so it is shown once.
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '近ＩＣ', exitIc: '出口'));

      final result = await _uc(lines).execute(_line());

      expect(result.used.map((c) => c.icName), ['近ＩＣ']);
      expect(result.sameRoute.map((c) => c.icName), ['料金所', '遠']);
    });

    test('use what the user has tied to a point, too', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '自宅', exitIc: '出口'));
      final mappings = FakeIcMappingIF()
        ..stored.add(const IcMappingEntity(icName: '自宅', pointId: 'id-遠'));

      final result = await _uc(lines, mappings: mappings).execute(_line());

      expect(result.used.map((c) => c.icName), ['自宅']);
      expect(result.sameRoute.map((c) => c.icName), ['近', '料金所']);
    });
  });

  test('passes on a failure to read', () {
    final lines = FakeStatementLineIF()..readError = StateError('x');

    expect(_uc(lines).execute(_line()), throwsStateError);
  });
}
