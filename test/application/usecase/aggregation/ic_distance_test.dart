import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/domain/entity/geo_point_entity.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

IcLinkEntity _link(String a, String b, int meters) =>
    IcLinkEntity(fromId: 'id-$a', toId: 'id-$b', meters: meters);

void main() {
  // A - B - C in a row, and D hangs off B. E and F are linked to each other
  // only.
  //   A --1000-- B --2000-- C
  //              |
  //             500
  //              D
  final links = [
    _link('A', 'B', 1000),
    _link('B', 'C', 2000),
    _link('D', 'B', 500),
    _link('E', 'F', 700),
  ];
  final distance = IcDistance(links);

  test('adds the links between two points that are not next to each other', () {
    final a = fakeIcPoint(name: 'A');
    final c = fakeIcPoint(name: 'C');

    expect(distance.metersBetween(a, c), 3000);
    // The way is the same in the other direction.
    expect(distance.metersBetween(c, a), 3000);
  });

  test(
    'is the length of the link for two points that are next to each other',
    () {
      expect(
        distance.metersBetween(fakeIcPoint(name: 'A'), fakeIcPoint(name: 'B')),
        1000,
      );
      // The ends of a link are in either order.
      expect(
        distance.metersBetween(fakeIcPoint(name: 'B'), fakeIcPoint(name: 'D')),
        500,
      );
    },
  );

  test('goes round a junction, by the shortest way', () {
    // A to D passes B: 1,000 + 500. D to C: 500 + 2,000.
    final a = fakeIcPoint(name: 'A');
    final c = fakeIcPoint(name: 'C');
    final d = fakeIcPoint(name: 'D');

    expect(distance.metersBetween(a, d), 1500);
    expect(distance.metersBetween(d, c), 2500);
  });

  test('takes the shortest of two ways', () {
    final loop = IcDistance([
      _link('A', 'B', 1000),
      _link('B', 'C', 1000),
      _link('A', 'C', 5000),
      _link('A', 'D', 100),
      _link('D', 'C', 100),
    ]);

    expect(
      loop.metersBetween(fakeIcPoint(name: 'A'), fakeIcPoint(name: 'C')),
      200,
    );
  });

  test('is 0 for the same point', () {
    final a = fakeIcPoint(name: 'A');

    expect(distance.metersBetween(a, a), 0);
    // Even a point that is not on the network.
    final x = fakeIcPoint(name: 'X');
    expect(distance.metersBetween(x, x), 0);
  });

  test('is the straight distance when the two are not connected', () {
    // 0.1 degrees of latitude is about 11.1 km.
    final e = fakeIcPoint(name: 'E', latitude: 35.0, longitude: 139.0);
    final a = fakeIcPoint(name: 'A', latitude: 35.1, longitude: 139.0);

    expect(distance.metersBetween(e, a), closeTo(11120, 30));
  });

  test('is the straight distance when a point is not on the network', () {
    final a = fakeIcPoint(name: 'A', latitude: 35.0, longitude: 139.0);
    final x = fakeIcPoint(name: 'X', latitude: 35.0, longitude: 139.1);

    // 0.1 degrees of longitude at latitude 35 is about 9.1 km.
    expect(distance.metersBetween(a, x), closeTo(9110, 30));
    expect(distance.metersBetween(x, a), closeTo(9110, 30));
  });

  test('is the straight distance when there is no link at all', () {
    final empty = IcDistance(const []);
    final a = fakeIcPoint(name: 'A', latitude: 35.0, longitude: 139.0);
    final b = fakeIcPoint(name: 'B', latitude: 35.0, longitude: 139.0);

    expect(empty.metersBetween(a, b), 0);
  });

  test('gives the same answer again', () {
    final a = fakeIcPoint(name: 'A');
    final c = fakeIcPoint(name: 'C');

    expect(distance.metersBetween(a, c), distance.metersBetween(a, c));
  });

  test('measures the straight distance on the sphere', () {
    // One degree of latitude is about 111.2 km everywhere.
    expect(IcDistance.straightMeters(35, 139, 36, 139), closeTo(111195, 50));
    expect(IcDistance.straightMeters(0, 0, 0, 0), 0);
  });

  group('roadRouteBetween', () {
    test('lists the points of the way, the ends included, in order', () {
      final route = distance.roadRouteBetween(
        fakeIcPoint(name: 'A'),
        fakeIcPoint(name: 'C'),
      )!;

      expect(route.meters, 3000);
      expect(route.pointIds, ['id-A', 'id-B', 'id-C']);
    });

    test('gives the same way backwards', () {
      final route = distance.roadRouteBetween(
        fakeIcPoint(name: 'C'),
        fakeIcPoint(name: 'A'),
      )!;

      expect(route.meters, 3000);
      expect(route.pointIds, ['id-C', 'id-B', 'id-A']);
      // Asking again (the other way first) gives the same answers.
      final forward = distance.roadRouteBetween(
        fakeIcPoint(name: 'A'),
        fakeIcPoint(name: 'C'),
      )!;
      expect(forward.pointIds, ['id-A', 'id-B', 'id-C']);
    });

    test('goes through a junction', () {
      final route = distance.roadRouteBetween(
        fakeIcPoint(name: 'A'),
        fakeIcPoint(name: 'D'),
      )!;

      expect(route.pointIds, ['id-A', 'id-B', 'id-D']);
    });

    test('is the point alone for the same point', () {
      final route = distance.roadRouteBetween(
        fakeIcPoint(name: 'X'),
        fakeIcPoint(name: 'X'),
      )!;

      expect(route.meters, 0);
      expect(route.pointIds, ['id-X']);
    });

    test('is null when there is no way', () {
      // Not connected, and a point that is not on the network.
      expect(
        distance.roadRouteBetween(
          fakeIcPoint(name: 'A'),
          fakeIcPoint(name: 'E'),
        ),
        isNull,
      );
      expect(
        distance.roadRouteBetween(
          fakeIcPoint(name: 'A'),
          fakeIcPoint(name: 'X'),
        ),
        isNull,
      );
      // Asking again gives null again (it is remembered).
      expect(
        distance.roadRouteBetween(
          fakeIcPoint(name: 'A'),
          fakeIcPoint(name: 'E'),
        ),
        isNull,
      );
    });

    test('takes the shortest of two ways, with its points', () {
      final loop = IcDistance([
        _link('A', 'B', 1000),
        _link('B', 'C', 1000),
        _link('A', 'C', 5000),
        _link('A', 'D', 100),
        _link('D', 'C', 100),
      ]);

      final route = loop.roadRouteBetween(
        fakeIcPoint(name: 'A'),
        fakeIcPoint(name: 'C'),
      )!;

      expect(route.pointIds, ['id-A', 'id-D', 'id-C']);
    });
  });

  group('the shape of the road', () {
    GeoPointEntity at(double lat, double lon) =>
        GeoPointEntity(latitude: lat, longitude: lon);

    // A - B - C, with a bend between A and B and two between B and C.
    // The link B-C is written the other way round (C first).
    final shaped = IcDistance([
      IcLinkEntity(
        fromId: 'id-A',
        toId: 'id-B',
        meters: 1000,
        shape: [at(35.01, 139.01)],
      ),
      IcLinkEntity(
        fromId: 'id-C',
        toId: 'id-B',
        meters: 2000,
        shape: [at(35.04, 139.04), at(35.03, 139.03)],
      ),
    ]);

    List<String> text(List<GeoPointEntity> shape) => [
      for (final p in shape) '${p.latitude},${p.longitude}',
    ];

    test('is given from the point asked, whichever way the link is', () {
      expect(text(shaped.shapeBetween('id-A', 'id-B')), ['35.01,139.01']);
      expect(text(shaped.shapeBetween('id-B', 'id-A')), ['35.01,139.01']);
      expect(text(shaped.shapeBetween('id-C', 'id-B')), [
        '35.04,139.04',
        '35.03,139.03',
      ]);
      expect(text(shaped.shapeBetween('id-B', 'id-C')), [
        '35.03,139.03',
        '35.04,139.04',
      ]);
    });

    test('is empty for points that are not next to each other', () {
      expect(shaped.shapeBetween('id-A', 'id-C'), isEmpty);
      expect(shaped.shapeBetween('id-A', 'id-X'), isEmpty);
    });

    test('is the one of the shorter link when a pair has two', () {
      final two = IcDistance([
        IcLinkEntity(
          fromId: 'id-A',
          toId: 'id-B',
          meters: 900,
          shape: [at(1, 1)],
        ),
        IcLinkEntity(
          fromId: 'id-A',
          toId: 'id-B',
          meters: 500,
          shape: [at(2, 2)],
        ),
      ]);

      expect(text(two.shapeBetween('id-A', 'id-B')), ['2.0,2.0']);
    });

    IcLookup lookup(List<IcPositionEntity> positions) => IcLookup(
      points: [
        fakeIcPoint(name: 'A', latitude: 35.0, longitude: 139.0),
        fakeIcPoint(name: 'B', latitude: 35.02, longitude: 139.02),
        fakeIcPoint(name: 'C', latitude: 35.05, longitude: 139.05),
      ],
      mappings: const [],
      positions: positions,
    );

    List<String> vertices(
      String from,
      String to, {
      List<IcPositionEntity> positions = const [],
      IcDistance? distance,
    }) {
      final l = lookup(positions);
      return text(
        routeVerticesOf(
          entrance: l.placeOf(from),
          exit: l.placeOf(to),
          lookup: l,
          distance: distance ?? shaped,
        ),
      );
    }

    test('are the roads and the points between, in order', () {
      // A to B: the bend. B to C: the two bends, with the point B before.
      expect(vertices('A', 'C'), [
        '35.01,139.01',
        '35.02,139.02',
        '35.03,139.03',
        '35.04,139.04',
      ]);
    });

    test('are in the order of the way backwards', () {
      expect(vertices('C', 'A'), [
        '35.04,139.04',
        '35.03,139.03',
        '35.02,139.02',
        '35.01,139.01',
      ]);
    });

    test('are the shape alone for two points next to each other', () {
      expect(vertices('A', 'B'), ['35.01,139.01']);
    });

    test('are empty when the way has no shape', () {
      final bare = IcDistance([_link('A', 'B', 1000), _link('B', 'C', 2000)]);

      // The point between them still gives a vertex.
      expect(vertices('A', 'C', distance: bare), ['35.02,139.02']);
      expect(vertices('A', 'B', distance: bare), isEmpty);
    });

    test('are empty when there is no way, or a position is the user\'s', () {
      expect(vertices('A', 'C', distance: IcDistance(const [])), isEmpty);
      expect(
        vertices(
          'A',
          'C',
          positions: const [
            IcPositionEntity(icName: 'C', latitude: 36, longitude: 140),
          ],
        ),
        isEmpty,
      );
      // An IC that is not known has no place.
      expect(vertices('A', '不明'), isEmpty);
      // One point: no road at all.
      expect(vertices('A', 'A'), isEmpty);
    });
  });
}
