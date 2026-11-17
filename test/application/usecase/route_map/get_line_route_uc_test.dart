import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/get_line_route_uc.dart';
import 'package:etc_meisai/domain/entity/geo_point_entity.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/ic_place_source_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

StatementLineDTO _line({String? entranceIc = '北', String exitIc = '東'}) {
  return StatementLineDTO(
    entranceAt: DateTime(2026, 1, 10, 8),
    exitAt: DateTime(2026, 1, 10, 9),
    entranceIc: entranceIc,
    exitIc: exitIc,
    grossFare: null,
    etcDiscount: null,
    fare: 100,
    fareAfterRebate: 100,
    postpaidFare: 100,
    vehicleType: VehicleTypeValue.standard,
    vehicleTypeName: '普通車',
    vehicleNumber: 1,
    cardNumberSuffix: '0001',
    status: ConfirmationStatusValue.confirmed,
    discountTypes: const [],
  );
}

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

GetLineRouteUC _uc({
  FakeIcMasterIF? master,
  FakeIcMappingIF? mappings,
  FakeIcPositionIF? positions,
}) => GetLineRouteUC(
  icMaster: master ?? _master(),
  icMappings: mappings ?? FakeIcMappingIF(),
  icPositions: positions ?? FakeIcPositionIF(),
);

void main() {
  group('GetLineRouteUC', () {
    test('draws the segment and marks the entrance and the exit', () async {
      final line = _line();

      final route = await _uc().execute(line);

      final segment = route.segment!;
      expect(segment.line, same(line));
      expect(segment.fromIcName, '北');
      expect(segment.toIcName, '東');
      expect(segment.fromLatitude, 35.1);
      expect(segment.toLongitude, 139.2);
      expect(route.places.map((p) => p.icName), ['北', '東']);
      expect(route.places.map((p) => p.lineCount), [1, 1]);
      expect(route.places.first.routeNames, ['R1']);
      expect(route.places.first.source, IcPlaceSourceValue.master);
      expect(route.places.first.approximate, isFalse);
      expect(route.unlocatedIcNames, isEmpty);
    });

    test('marks the exit only when the entrance is blank', () async {
      final route = await _uc().execute(_line(entranceIc: null));

      expect(route.segment, isNull);
      expect(route.places.map((p) => p.icName), ['東']);
      expect(route.unlocatedIcNames, isEmpty);
    });

    test(
      'draws a blank entrance of a two-IC road from the other end',
      () async {
        final uc = GetLineRouteUC(
          icMaster: FakeIcMasterIF([
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
          ]),
          icMappings: FakeIcMappingIF(),
          icPositions: FakeIcPositionIF(),
        );
        final route = await uc.execute(_line(entranceIc: null, exitIc: '平湯'));

        expect(route.segment!.fromIcName, '中ノ湯');
        expect(route.segment!.fromLatitude, 36.2);
        expect(route.segment!.toLongitude, 137.55);
      },
    );

    test('does not draw a line with an unknown IC, and lists it', () async {
      final route = await _uc().execute(_line(exitIc: '不明'));

      expect(route.segment, isNull);
      expect(route.places.map((p) => p.icName), ['北']);
      expect(route.unlocatedIcNames, ['不明']);
    });

    test('lists the unknown ICs in the order of the entrance, exit', () async {
      final route = await _uc().execute(_line(entranceIc: 'a', exitIc: 'b'));

      expect(route.places, isEmpty);
      expect(route.unlocatedIcNames, ['a', 'b']);
    });

    test(
      'makes one marker when the entrance and the exit are one IC',
      () async {
        final route = await _uc().execute(_line(entranceIc: '北', exitIc: '北'));

        expect(route.places, hasLength(1));
        expect(route.segment, isNotNull);

        final unknown = await _uc().execute(
          _line(entranceIc: 'a', exitIc: 'a'),
        );
        expect(unknown.unlocatedIcNames, ['a']);
      },
    );

    test('puts the position the user chose before the master', () async {
      final positions = FakeIcPositionIF()
        ..stored.add(
          const IcPositionEntity(icName: '東', latitude: 40.0, longitude: 141.0),
        );

      final route = await _uc(positions: positions).execute(_line());

      expect(route.segment!.toLatitude, 40.0);
      final east = route.places.singleWhere((p) => p.icName == '東');
      expect(east.source, IcPlaceSourceValue.specified);
      expect(east.routeNames, isEmpty);
    });

    test('follows a mapping the user registered', () async {
      final mappings = FakeIcMappingIF()
        ..stored.add(const IcMappingEntity(icName: '不明', pointId: 'id-東'));

      final route = await _uc(mappings: mappings).execute(_line(exitIc: '不明'));

      expect(route.segment!.toLatitude, 35.2);
    });

    test('marks a toll gate (本線) as approximate', () async {
      final route = await _uc().execute(_line(exitIc: '高井戸本線'));

      final gate = route.places.singleWhere((p) => p.icName == '高井戸本線');
      expect(gate.approximate, isTrue);
      expect(gate.latitude, 35.3);
    });

    test('passes on a failure to read', () {
      final positions = FakeIcPositionIF()..error = StateError('x');

      expect(_uc(positions: positions).execute(_line()), throwsStateError);
    });
    test('goes through the points on the way, in order', () async {
      final master = FakeIcMasterIF(
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

      final route = await _uc(master: master).execute(_line());

      final via = route.segment!.via;
      expect(via, hasLength(1));
      expect(via.single.latitude, 35.5);
      // The markers are the entrance and the exit only.
      expect(route.places.map((p) => p.icName), ['北', '東']);
    });

    test('follows the shape of the road', () async {
      final master = FakeIcMasterIF(
        [
          fakeIcPoint(name: '北', latitude: 35.1, longitude: 139.1),
          fakeIcPoint(name: '東', latitude: 35.2, longitude: 139.2),
        ],
        links: const [
          IcLinkEntity(
            fromId: 'id-北',
            toId: 'id-東',
            meters: 1000,
            shape: [
              GeoPointEntity(latitude: 35.3, longitude: 139.15),
              GeoPointEntity(latitude: 35.0, longitude: 139.18),
            ],
          ),
        ],
      );

      final route = await _uc(master: master).execute(_line());

      expect(route.segment!.via.map((v) => v.latitude), [35.3, 35.0]);
    });

    test('is straight when the user chose a position', () async {
      final master = FakeIcMasterIF(
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
      final positions = FakeIcPositionIF()
        ..stored.add(
          const IcPositionEntity(icName: '東', latitude: 36, longitude: 140),
        );

      final route = await _uc(
        master: master,
        positions: positions,
      ).execute(_line());

      expect(route.segment!.via, isEmpty);
    });

    test('is straight when the points are not linked', () async {
      final route = await _uc().execute(_line());

      expect(route.segment!.via, isEmpty);
    });
  });
}
