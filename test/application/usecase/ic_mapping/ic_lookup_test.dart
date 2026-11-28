import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/value/ic_place_source_value.dart';
import 'package:etc_meisai/domain/value/ic_match_value.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

IcLookup _lookup(
  List<String> names, {
  List<IcMappingEntity> mappings = const [],
}) => IcLookup(
  points: [for (final n in names) fakeIcPoint(id: 'id-$n', name: n)],
  mappings: mappings,
);

void main() {
  group('fold', () {
    test('makes full-width letters half-width and ignores case and spaces', () {
      expect(IcLookup.fold('テスト北ＩＣ'), 'テスト北ic');
      expect(IcLookup.fold('テスト 北　Ic'), 'テスト北ic');
      expect(IcLookup.fold('ＡＢＣ１２３'), 'abc123');
    });
  });

  group('baseName', () {
    test('removes one suffix of a road operator', () {
      expect(IcLookup.baseName('東京IC'), '東京');
      expect(IcLookup.baseName('東京ＩＣ'), '東京');
      expect(IcLookup.baseName('東京JCT'), '東京');
      expect(IcLookup.baseName('東京SIC'), '東京');
      expect(IcLookup.baseName('東京スマートIC'), '東京');
      expect(IcLookup.baseName('東京スマート'), '東京');
      expect(IcLookup.baseName('霞が関出入口'), '霞が関');
      expect(IcLookup.baseName('霞が関入口'), '霞が関');
      expect(IcLookup.baseName('霞が関出口'), '霞が関');
      expect(IcLookup.baseName('高井戸本線'), '高井戸');
    });

    test('keeps a name without a suffix, and a name that would be empty', () {
      expect(IcLookup.baseName('東京'), '東京');
      expect(IcLookup.baseName('IC'), 'ic');
      expect(IcLookup.baseName('入口'), '入口');
      expect(IcLookup.baseName('本線'), '本線');
    });
  });

  group('resolve', () {
    test('matches the name as it is', () {
      final r = _lookup(['東京', '東京JCT']).resolve('東京');

      expect(r.state, IcMatchValue.matched);
      expect(r.point!.name, '東京');
    });

    test('matches a name that differs in width and case', () {
      final r = _lookup(['TOKYO']).resolve('ＴＯＫＹＯ');

      expect(r.state, IcMatchValue.matched);
    });

    test('matches the name without the suffix of either side', () {
      expect(_lookup(['七尾']).resolve('七尾ＩＣ').state, IcMatchValue.matched);
      expect(_lookup(['七尾IC']).resolve('七尾').state, IcMatchValue.matched);
      expect(_lookup(['幸手SIC']).resolve('幸手スマート').state, IcMatchValue.matched);
      expect(_lookup(['霞が関出入口']).resolve('霞が関入口').state, IcMatchValue.matched);
      expect(_lookup(['高井戸']).resolve('高井戸本線').state, IcMatchValue.matched);
    });

    test('matches a name without its direction or number, approximately', () {
      for (final name in ['永福上', '横浜公園下', '霞が関内', '東扇島第二', '東扇島西']) {
        final point = name.substring(
          0,
          name.length - (name.endsWith('第二') ? 2 : 1),
        );
        final r = _lookup([point]).resolve(name);

        expect(r.state, IcMatchValue.matched, reason: name);
        expect(r.point!.name, point, reason: name);
        expect(r.approximate, isTrue, reason: name);
      }
    });

    test('does not strip a direction when the name matches as it is', () {
      final r = _lookup(['木更津北', '木更津']).resolve('木更津北');

      expect(r.point!.name, '木更津北');
      expect(r.approximate, isFalse);
    });

    test('does not strip a direction from a name of one character', () {
      expect(_lookup(['東']).resolve('東西').state, IcMatchValue.unknown);
      expect(_lookup(['甲']).resolve('甲上').state, IcMatchValue.unknown);
    });

    test('is ambiguous when two points fit without the direction', () {
      final r = _lookup(['永福IC', '永福出入口']).resolve('永福上');

      expect(r.state, IcMatchValue.ambiguous);
      expect(r.approximate, isTrue);
    });

    test('is unknown when the name without the direction fits nothing', () {
      expect(_lookup(['永福']).resolve('別上').state, IcMatchValue.unknown);
    });

    test('is ambiguous when several points fit', () {
      final r = _lookup(['東京IC', '東京JCT']).resolve('東京');

      expect(r.state, IcMatchValue.ambiguous);
      expect(r.point, isNull);
      expect(r.candidates.map((p) => p.name), ['東京IC', '東京JCT']);
    });

    test('is ambiguous when the same name is used twice', () {
      final lookup = IcLookup(
        points: [
          fakeIcPoint(id: 'a', name: '同名'),
          fakeIcPoint(id: 'b', name: '同名'),
        ],
        mappings: const [],
      );

      expect(lookup.resolve('同名').state, IcMatchValue.ambiguous);
      expect(lookup.resolve('同名').candidates, hasLength(2));
    });

    test('is unknown when no point fits', () {
      final r = _lookup(['東京']).resolve('大阪本線');

      expect(r.state, IcMatchValue.unknown);
      expect(r.point, isNull);
      expect(r.candidates, isEmpty);
    });

    test('prefers a registered mapping to every other rule', () {
      final lookup = _lookup(
        ['東京IC', '東京JCT', '別名'],
        mappings: const [IcMappingEntity(icName: '東京', pointId: 'id-別名')],
      );

      final r = lookup.resolve('東京');

      expect(r.state, IcMatchValue.registered);
      expect(r.point!.name, '別名');
    });

    test('ignores a mapping whose point is not in the master', () {
      final lookup = _lookup(
        ['東京'],
        mappings: const [IcMappingEntity(icName: '東京', pointId: 'gone')],
      );

      expect(lookup.resolve('東京').state, IcMatchValue.matched);
    });
  });

  test('pointOf finds a point by its id', () {
    final lookup = _lookup(['東京']);

    expect(lookup.pointOf('id-東京')!.name, '東京');
    expect(lookup.pointOf('none'), isNull);
  });

  group('routeNamesOf', () {
    IcLookup newLookup() => IcLookup(
      points: [
        fakeIcPoint(name: 'A', routeNames: const ['R1', 'R2']),
        fakeIcPoint(name: 'B', routeNames: const ['R2', 'R3']),
        fakeIcPoint(name: 'C', routeNames: const ['R4']),
      ],
      mappings: const [],
    );

    test('gives the routes both ICs share', () {
      expect(newLookup().routeNamesOf('A', 'B'), ['R2']);
    });

    test('gives the routes of both when they share none', () {
      expect(newLookup().routeNamesOf('A', 'C'), ['R1', 'R2', 'R4']);
    });

    test('gives the routes of the only known point', () {
      expect(newLookup().routeNamesOf('A', '不明'), ['R1', 'R2']);
      expect(newLookup().routeNamesOf('不明', 'C'), ['R4']);
      expect(newLookup().routeNamesOf(null, 'B'), ['R2', 'R3']);
    });

    test('is empty when no point is known', () {
      expect(newLookup().routeNamesOf('不明', '不明2'), isEmpty);
      expect(newLookup().routeNamesOf(null, '不明'), isEmpty);
    });

    test('knows a route the master lacks from the start of the IC name', () {
      final lookup = newLookup();
      expect(lookup.routeNamesOf(null, '木更津金田第一'), ['東京湾アクアライン']);
      expect(lookup.routeNamesOf(null, 'アクア湾西接続'), ['東京湾アクアライン']);
      expect(lookup.routeNamesOf(null, '海ほたる'), ['東京湾アクアライン']);
      expect(lookup.routeNamesOf(null, '木更津金田ＩＣ'), ['東京湾アクアライン']);
      expect(lookup.routeNamesOf('木更津金田第一', '木更津金田第一'), ['東京湾アクアライン']);
    });

    test('joins a supplement with the route of a known point', () {
      final lookup = newLookup();

      expect(lookup.routeNamesOf('A', '木更津金田第一'), ['R1', 'R2', '東京湾アクアライン']);
      expect(lookup.routeNamesOf('木更津金田第一', '不明'), ['東京湾アクアライン']);
    });

    test('uses a supplement for a point that has no route', () {
      final lookup = IcLookup(
        points: [fakeIcPoint(name: '木更津金田', routeNames: const [])],
        mappings: const [],
      );

      expect(lookup.routeNamesOf(null, '木更津金田第一'), ['東京湾アクアライン']);
      // A point without a route and without a supplement is not known.
      expect(
        IcLookup(
          points: [fakeIcPoint(name: '袖ヶ浦', routeNames: const [])],
          mappings: const [],
        ).routeNamesOf(null, '袖ヶ浦'),
        isEmpty,
      );
    });

    test('prefers the point when the master has one', () {
      final lookup = IcLookup(
        points: [
          fakeIcPoint(name: '海ほたる', routeNames: const ['R9']),
        ],
        mappings: const [],
      );

      expect(lookup.routeNamesOf(null, '海ほたる'), ['R9']);
    });

    test('gives no route for a name without a supplement', () {
      expect(newLookup().routeNamesOf(null, '木更津北'), isEmpty);
    });

    test('uses a registered mapping', () {
      final lookup = IcLookup(
        points: [
          fakeIcPoint(name: 'A', routeNames: const ['R1']),
          fakeIcPoint(name: 'X', routeNames: const ['R9']),
        ],
        mappings: const [IcMappingEntity(icName: '不明', pointId: 'id-X')],
      );

      expect(lookup.routeNamesOf('A', '不明'), ['R1', 'R9']);
    });
  });

  group('placeOf', () {
    IcLookup lookup({List<IcPositionEntity> positions = const []}) => IcLookup(
      points: [
        fakeIcPoint(name: '高井戸', latitude: 35.5, longitude: 139.5),
        fakeIcPoint(name: '東', latitude: 36.0, longitude: 140.0),
      ],
      mappings: const [],
      positions: positions,
    );

    test('gives the position of the matched point', () {
      final place = lookup().placeOf('東')!;

      expect(place.latitude, 36.0);
      expect(place.longitude, 140.0);
      expect(place.source, IcPlaceSourceValue.master);
      expect(place.approximate, isFalse);
      expect(place.point!.name, '東');
    });

    test('marks a toll gate as approximate', () {
      final place = lookup().placeOf('高井戸本線')!;

      expect(place.approximate, isTrue);
      expect(place.latitude, 35.5);
    });

    test('marks a name matched without its direction as approximate', () {
      final place = IcLookup(
        points: [fakeIcPoint(name: '永福', latitude: 35.6, longitude: 139.6)],
        mappings: const [],
      ).placeOf('永福上')!;

      expect(place.approximate, isTrue);
      expect(place.latitude, 35.6);
    });

    test('prefers the position the user chose', () {
      final place = lookup(
        positions: const [
          IcPositionEntity(icName: '高井戸本線', latitude: 35.7, longitude: 139.7),
        ],
      ).placeOf('高井戸本線')!;

      expect(place.latitude, 35.7);
      expect(place.longitude, 139.7);
      expect(place.source, IcPlaceSourceValue.specified);
      expect(place.approximate, isFalse);
      expect(place.point, isNull);
    });

    test('is null when no position is known', () {
      expect(lookup().placeOf('不明'), isNull);
    });
  });
}
