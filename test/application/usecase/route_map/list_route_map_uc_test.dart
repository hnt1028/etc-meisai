import 'package:etc_meisai/application/usecase/route_map/delete_ic_position_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_ic_position_uc.dart';
import 'package:etc_meisai/domain/entity/geo_point_entity.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/ic_place_source_value.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

FakeIcMasterIF _master() => FakeIcMasterIF([
  fakeIcPoint(
    name: '北',
    routeNames: const ['R1'],
    latitude: 35.1,
    longitude: 139.1,
  ),
  fakeIcPoint(
    name: '東',
    routeNames: const ['R2'],
    latitude: 35.2,
    longitude: 139.2,
  ),
  fakeIcPoint(name: '高井戸', latitude: 35.3, longitude: 139.3),
]);

void main() {
  group('ListRouteMapUC', () {
    test('is empty when nothing is stored', () async {
      final result = await fakeRouteMapUC(FakeStatementLineIF()).execute();

      expect(result.segments, isEmpty);
      expect(result.places, isEmpty);
      expect(result.unlocated, isEmpty);
      expect(result.undrawnLineCount, 0);
      expect(result.lineCount, 0);
    });

    test('draws a segment when both positions are known', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '東'));

      final result = await fakeRouteMapUC(lines, master: _master()).execute();

      expect(result.segments, hasLength(1));
      final segment = result.segments.single;
      expect(segment.fromIcName, '北');
      expect(segment.toIcName, '東');
      expect(segment.fromLatitude, 35.1);
      expect(segment.fromLongitude, 139.1);
      expect(segment.toLatitude, 35.2);
      expect(segment.toLongitude, 139.2);
      expect(segment.line.exitIc, '東');
      expect(segment.line.routeNames, ['R1', 'R2']);
      expect(result.undrawnLineCount, 0);
      expect(result.lineCount, 1);
    });

    test(
      'draws a blank entrance of a two-IC road from the other end',
      () async {
        FakeIcMasterIF master() => FakeIcMasterIF([
          fakeIcPoint(
            name: '中ノ湯',
            routeNames: const ['安房峠道路'],
            latitude: 36.2,
            longitude: 137.6,
          ),
          fakeIcPoint(
            name: '平湯',
            routeNames: const ['安房峠道路'],
            latitude: 36.18,
            longitude: 137.55,
          ),
          fakeIcPoint(name: '北', routeNames: const ['R1']),
        ]);
        for (final (exit, from) in [('平湯', '中ノ湯'), ('中ノ湯', '平湯')]) {
          final lines = FakeStatementLineIF()
            ..stored.add(
              fakeStatementLine(exitIc: exit, withoutEntrance: true),
            );
          final result = await fakeRouteMapUC(
            lines,
            master: master(),
          ).execute();

          expect(result.segments.single.fromIcName, from);
          expect(result.segments.single.toIcName, exit);
          expect(result.undrawnLineCount, 0);
        }

        // An IC of another road is not completed.
        final other = FakeStatementLineIF()
          ..stored.add(fakeStatementLine(exitIc: '北', withoutEntrance: true));
        final result = await fakeRouteMapUC(other, master: master()).execute();
        expect(result.segments, isEmpty);
        expect(result.undrawnLineCount, 1);
      },
    );

    test('makes one marker for an IC name, with the number of lines', () async {
      final lines = FakeStatementLineIF()
        ..stored.addAll([
          fakeStatementLine(entranceIc: '北', exitIc: '東'),
          fakeStatementLine(
            entranceIc: '東',
            exitIc: '北',
            entranceAt: DateTime(2026, 1, 11),
            exitAt: DateTime(2026, 1, 11, 1),
          ),
          fakeStatementLine(
            entranceIc: '北',
            exitIc: '北',
            entranceAt: DateTime(2026, 1, 12),
            exitAt: DateTime(2026, 1, 12, 1),
          ),
        ]);

      final result = await fakeRouteMapUC(lines, master: _master()).execute();

      expect(result.places.map((p) => p.icName), ['北', '東']);
      // The line from 北 to 北 counts once for 北.
      expect(result.places.map((p) => p.lineCount), [3, 2]);
      expect(result.places.first.routeNames, ['R1']);
      expect(result.places.first.source, IcPlaceSourceValue.master);
      expect(result.places.first.approximate, isFalse);
    });

    test('does not draw a line with an unknown IC, and lists the IC', () async {
      final lines = FakeStatementLineIF()
        ..stored.addAll([
          fakeStatementLine(entranceIc: '北', exitIc: '不明'),
          fakeStatementLine(
            entranceIc: '不明',
            exitIc: '東',
            entranceAt: DateTime(2026, 1, 11),
            exitAt: DateTime(2026, 1, 11, 1),
          ),
          fakeStatementLine(
            entranceIc: '北',
            exitIc: '別',
            entranceAt: DateTime(2026, 1, 12),
            exitAt: DateTime(2026, 1, 12, 1),
          ),
        ]);

      final result = await fakeRouteMapUC(lines, master: _master()).execute();

      expect(result.segments, isEmpty);
      expect(result.undrawnLineCount, 3);
      expect(result.unlocated.map((u) => u.icName), ['不明', '別']);
      expect(result.unlocated.map((u) => u.lineCount), [2, 1]);
      // The known ICs still have a marker.
      expect(result.places.map((p) => p.icName), ['北', '東']);
    });

    test(
      'does not draw a line without an entrance, but marks its exit',
      () async {
        final lines = FakeStatementLineIF()
          ..stored.add(fakeStatementLine(exitIc: '東', withoutEntrance: true));

        final result = await fakeRouteMapUC(lines, master: _master()).execute();

        expect(result.segments, isEmpty);
        expect(result.undrawnLineCount, 1);
        expect(result.unlocated, isEmpty);
        expect(result.places.single.icName, '東');
      },
    );

    test('puts the position the user chose before the master', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '東'));
      final positions = FakeIcPositionIF()
        ..stored.add(
          const IcPositionEntity(icName: '東', latitude: 40.0, longitude: 141.0),
        );

      final result = await fakeRouteMapUC(
        lines,
        master: _master(),
        positions: positions,
      ).execute();

      expect(result.segments.single.toLatitude, 40.0);
      expect(result.segments.single.toLongitude, 141.0);
      final east = result.places.singleWhere((p) => p.icName == '東');
      expect(east.source, IcPlaceSourceValue.specified);
      expect(east.routeNames, isEmpty);
    });

    test('draws an IC name that has only a chosen position', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '不明'));
      final positions = FakeIcPositionIF()
        ..stored.add(
          const IcPositionEntity(
            icName: '不明',
            latitude: 36.0,
            longitude: 140.0,
          ),
        );

      final result = await fakeRouteMapUC(
        lines,
        master: _master(),
        positions: positions,
      ).execute();

      expect(result.segments, hasLength(1));
      expect(result.unlocated, isEmpty);
    });

    test('follows a mapping the user registered', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '不明'));
      final mappings = FakeIcMappingIF()
        ..stored.add(const IcMappingEntity(icName: '不明', pointId: 'id-東'));

      final result = await fakeRouteMapUC(
        lines,
        master: _master(),
        mappings: mappings,
      ).execute();

      expect(result.segments.single.toLatitude, 35.2);
    });

    test('marks a toll gate (本線) as approximate', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '高井戸本線'));

      final result = await fakeRouteMapUC(lines, master: _master()).execute();

      final gate = result.places.singleWhere((p) => p.icName == '高井戸本線');
      expect(gate.approximate, isTrue);
      expect(gate.latitude, 35.3);
      expect(
        result.places.singleWhere((p) => p.icName == '北').approximate,
        isFalse,
      );
    });

    test('filters like the statement list, keeping the choices', () async {
      final lines = FakeStatementLineIF()
        ..stored.addAll([
          fakeStatementLine(
            entranceIc: '北',
            exitIc: '東',
            vehicleNumber: 1,
            cardNumber: '0000-****-0001',
            exitAt: DateTime(2026, 1, 10, 9),
          ),
          fakeStatementLine(
            entranceIc: '東',
            exitIc: '北',
            vehicleNumber: 2,
            cardNumber: '0000-****-0002',
            entranceAt: DateTime(2026, 2, 10),
            exitAt: DateTime(2026, 2, 10, 1),
            status: ConfirmationStatusValue.pending,
          ),
        ]);
      final uc = fakeRouteMapUC(lines, master: _master());

      final byPeriod = await uc.execute(
        from: DateTime(2026, 2, 1),
        to: DateTime(2026, 2, 28),
      );
      final byVehicle = await uc.execute(vehicleNumber: 1);
      final byCard = await uc.execute(cardNumberSuffix: '0002');

      expect(byPeriod.segments.single.fromIcName, '東');
      expect(
        byPeriod.segments.single.line.status,
        ConfirmationStatusValue.pending,
      );
      expect(byVehicle.segments.single.fromIcName, '北');
      expect(byCard.lineCount, 1);
      expect(byPeriod.vehicleNumberChoices, [1, 2]);
      expect(byPeriod.cardNumberChoices, ['0001', '0002']);
    });

    test('passes on a failure to read', () {
      final lines = FakeStatementLineIF()..readError = StateError('x');

      expect(fakeRouteMapUC(lines).execute(), throwsStateError);
    });
  });

  group('the line through the ICs between', () {
    // 北 - 中 - 東 along a road (中 has a position between the two).
    FakeIcMasterIF road() => FakeIcMasterIF(
      [
        fakeIcPoint(name: '北', latitude: 35.1, longitude: 139.1),
        fakeIcPoint(name: '中', latitude: 35.5, longitude: 139.2),
        fakeIcPoint(name: '東', latitude: 35.2, longitude: 139.2),
      ],
      links: const [
        IcLinkEntity(fromId: 'id-北', toId: 'id-中', meters: 1000),
        IcLinkEntity(fromId: 'id-中', toId: 'id-東', meters: 1000),
      ],
    );

    test('goes through the points on the way, in order', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '東'));

      final result = await fakeRouteMapUC(lines, master: road()).execute();

      final segment = result.segments.single;
      expect(segment.via, hasLength(1));
      expect(segment.via.single.latitude, 35.5);
      expect(segment.via.single.longitude, 139.2);
      // The ends are as before.
      expect(segment.fromLatitude, 35.1);
      expect(segment.toLatitude, 35.2);
    });

    test('follows the shape of the roads between the points', () async {
      final shaped = FakeIcMasterIF(
        [
          fakeIcPoint(name: '北', latitude: 35.1, longitude: 139.1),
          fakeIcPoint(name: '中', latitude: 35.5, longitude: 139.2),
          fakeIcPoint(name: '東', latitude: 35.2, longitude: 139.2),
        ],
        links: const [
          IcLinkEntity(
            fromId: 'id-北',
            toId: 'id-中',
            meters: 1000,
            shape: [GeoPointEntity(latitude: 35.2, longitude: 139.15)],
          ),
          IcLinkEntity(
            fromId: 'id-中',
            toId: 'id-東',
            meters: 1000,
            shape: [
              GeoPointEntity(latitude: 35.4, longitude: 139.25),
              GeoPointEntity(latitude: 35.3, longitude: 139.3),
            ],
          ),
        ],
      );
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '東'));

      final result = await fakeRouteMapUC(lines, master: shaped).execute();

      // The bend, the point 中, and the two bends.
      expect(
        result.segments.single.via.map((v) => '${v.latitude},${v.longitude}'),
        ['35.2,139.15', '35.5,139.2', '35.4,139.25', '35.3,139.3'],
      );
    });

    test('goes through them in the order of the way, backwards too', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '東', exitIc: '北'));

      final result = await fakeRouteMapUC(lines, master: road()).execute();

      expect(result.segments.single.via.single.latitude, 35.5);
      expect(result.segments.single.fromLatitude, 35.2);
    });

    test(
      'has no point between two points that are next to each other',
      () async {
        final lines = FakeStatementLineIF()
          ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '中'));

        final result = await fakeRouteMapUC(lines, master: road()).execute();

        expect(result.segments.single.via, isEmpty);
      },
    );

    test('is straight when there is no way over the links', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '東'));
      final noLinks = FakeIcMasterIF([
        fakeIcPoint(name: '北', latitude: 35.1, longitude: 139.1),
        fakeIcPoint(name: '東', latitude: 35.2, longitude: 139.2),
      ]);

      final result = await fakeRouteMapUC(lines, master: noLinks).execute();

      expect(result.segments.single.via, isEmpty);
    });

    test('is straight when the user chose a position of an end', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '東'));
      final positions = FakeIcPositionIF()
        ..stored.add(
          const IcPositionEntity(icName: '東', latitude: 36, longitude: 140),
        );

      final result = await fakeRouteMapUC(
        lines,
        master: road(),
        positions: positions,
      ).execute();

      expect(result.segments.single.via, isEmpty);
      expect(result.segments.single.toLatitude, 36);
    });

    test('passes on a failure to read the links', () {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(entranceIc: '北', exitIc: '東'));
      final master = road()..error = StateError('x');

      expect(fakeRouteMapUC(lines, master: master).execute(), throwsStateError);
    });
  });

  group('SaveIcPositionUC', () {
    test('stores the position and replaces one of the same IC name', () async {
      final positions = FakeIcPositionIF();
      final uc = SaveIcPositionUC(icPositions: positions);

      await uc.execute(icName: '高井戸本線', latitude: 35.0, longitude: 139.0);
      await uc.execute(icName: '高井戸本線', latitude: 35.5, longitude: 139.5);

      expect(positions.stored, hasLength(1));
      expect(positions.stored.single.latitude, 35.5);
      expect(positions.stored.single.longitude, 139.5);
    });

    test('accepts the edges of the range', () async {
      final positions = FakeIcPositionIF();
      final uc = SaveIcPositionUC(icPositions: positions);

      await uc.execute(icName: 'a', latitude: 90, longitude: 180);
      await uc.execute(icName: 'b', latitude: -90, longitude: -180);

      expect(positions.stored, hasLength(2));
    });

    test('rejects a position out of range, storing nothing', () async {
      final positions = FakeIcPositionIF();
      final uc = SaveIcPositionUC(icPositions: positions);

      for (final (lat, lon) in [
        (90.1, 0.0),
        (-90.1, 0.0),
        (0.0, 180.1),
        (0.0, -180.1),
        (double.nan, 0.0),
        (0.0, double.nan),
      ]) {
        await expectLater(
          uc.execute(icName: 'x', latitude: lat, longitude: lon),
          throwsArgumentError,
        );
      }
      expect(positions.stored, isEmpty);
    });

    test('passes on a failure to store', () {
      final positions = FakeIcPositionIF()..error = StateError('disk');

      expect(
        SaveIcPositionUC(
          icPositions: positions,
        ).execute(icName: 'x', latitude: 1, longitude: 1),
        throwsStateError,
      );
    });
  });

  group('DeleteIcPositionUC', () {
    test('removes the position, and does nothing when there is none', () async {
      final positions = FakeIcPositionIF()
        ..stored.add(
          const IcPositionEntity(icName: 'x', latitude: 1, longitude: 1),
        );
      final uc = DeleteIcPositionUC(icPositions: positions);

      await uc.execute('x');
      await uc.execute('x');

      expect(positions.stored, isEmpty);
    });

    test('passes on a failure', () {
      final positions = FakeIcPositionIF()..error = StateError('disk');

      expect(
        DeleteIcPositionUC(icPositions: positions).execute('x'),
        throwsStateError,
      );
    });
  });
}
