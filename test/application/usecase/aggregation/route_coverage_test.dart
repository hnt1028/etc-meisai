import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_coverage.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

IcLinkEntity _link(String a, String b, int meters) =>
    IcLinkEntity(fromId: 'id-$a', toId: 'id-$b', meters: meters);

RouteCoverage _coverage(
  List<IcPointEntity> points,
  List<IcLinkEntity> links,
  List<({String? entranceIc, String exitIc})> trips,
) => routeCoverageOf(
  points: points,
  links: links,
  distance: IcDistance(links),
  lookup: IcLookup(points: points, mappings: const [], positions: const []),
  trips: trips,
);

void main() {
  // R1: 甲 - 乙 - 丙 - 丁 (1000, 2000, 3000 meters). R2: 戊 - 己 (500).
  final points = [
    fakeIcPoint(name: '甲', routeNames: const ['R1']),
    fakeIcPoint(name: '乙', routeNames: const ['R1']),
    fakeIcPoint(name: '丙', routeNames: const ['R1']),
    fakeIcPoint(name: '丁', routeNames: const ['R1']),
    fakeIcPoint(name: '戊', routeNames: const ['R2']),
    fakeIcPoint(name: '己', routeNames: const ['R2']),
  ];
  final links = [
    _link('甲', '乙', 1000),
    _link('乙', '丙', 2000),
    _link('丙', '丁', 3000),
    _link('戊', '己', 500),
  ];

  test('counts the sections of the way from the entrance to the exit', () {
    final result = _coverage(points, links, [(entranceIc: '甲', exitIc: '丙')]);

    expect(result.routeCount, 2);
    expect(result.rows, hasLength(1));
    expect(result.rows.single.routeName, 'R1');
    expect(result.rows.single.totalMeters, 6000);
    // 甲 - 乙 and 乙 - 丙.
    expect(result.rows.single.drivenMeters, 3000);
  });

  test('counts a section once, however often it is driven', () {
    final result = _coverage(points, links, [
      (entranceIc: '甲', exitIc: '乙'),
      (entranceIc: '乙', exitIc: '甲'),
      (entranceIc: '甲', exitIc: '乙'),
    ]);

    expect(result.rows.single.drivenMeters, 1000);
  });

  test('gives nothing when no line is driven', () {
    final result = _coverage(points, links, const []);

    expect(result.rows, isEmpty);
    expect(result.routeCount, 2);
  });

  test('lists the most covered road first, then the longer, then by name', () {
    final result = _coverage(points, links, [
      (entranceIc: '甲', exitIc: '丁'), // all of R1
      (entranceIc: '戊', exitIc: '己'), // all of R2
    ]);

    // Both are all covered: the longer one first.
    expect(result.rows.map((r) => r.routeName), ['R1', 'R2']);

    final partial = _coverage(points, links, [
      (entranceIc: '甲', exitIc: '乙'), // 1000 of 6000
      (entranceIc: '戊', exitIc: '己'), // all of R2
    ]);
    expect(partial.rows.map((r) => r.routeName), ['R2', 'R1']);
  });

  test('breaks a tie of the share and the length by the name', () {
    final two = [
      fakeIcPoint(name: 'a1', routeNames: const ['B路線']),
      fakeIcPoint(name: 'a2', routeNames: const ['B路線']),
      fakeIcPoint(name: 'b1', routeNames: const ['A路線']),
      fakeIcPoint(name: 'b2', routeNames: const ['A路線']),
    ];
    final twoLinks = [_link('a1', 'a2', 100), _link('b1', 'b2', 100)];

    final result = _coverage(two, twoLinks, [
      (entranceIc: 'a1', exitIc: 'a2'),
      (entranceIc: 'b1', exitIc: 'b2'),
    ]);

    expect(result.rows.map((r) => r.routeName), ['A路線', 'B路線']);
  });

  test('takes the entrance of a short road when the entrance is blank', () {
    final road = [
      fakeIcPoint(name: '中ノ湯', routeNames: const ['安房峠道路']),
      fakeIcPoint(name: '平湯', routeNames: const ['安房峠道路']),
    ];
    final roadLinks = [_link('中ノ湯', '平湯', 4000)];

    final result = _coverage(road, roadLinks, [
      (entranceIc: null, exitIc: '平湯'),
    ]);

    expect(result.rows.single.routeName, '安房峠道路');
    expect(result.rows.single.drivenMeters, 4000);
  });

  test('skips a line without an entrance that is not known', () {
    final result = _coverage(points, links, [(entranceIc: null, exitIc: '丙')]);

    expect(result.rows, isEmpty);
  });

  test('skips a line whose IC is not in the master, or has no way', () {
    final result = _coverage(points, links, [
      (entranceIc: '無い', exitIc: '丙'),
      (entranceIc: '甲', exitIc: '無い'),
      // 甲 and 戊 are on different roads that do not meet.
      (entranceIc: '甲', exitIc: '戊'),
    ]);

    expect(result.rows, isEmpty);
  });

  test(
    'keeps the shorter link of a pair, and ignores links without a road',
    () {
      final result = _coverage(
        points,
        [
          _link('甲', '乙', 1000),
          _link('甲', '乙', 400), // the same pair: the shorter counts
          _link('乙', '丙', 2000),
          // 丁 and 戊 share no road, and 甲 and 無い is not a point.
          _link('丁', '戊', 700),
          const IcLinkEntity(fromId: 'id-甲', toId: 'id-無い', meters: 5),
        ],
        [(entranceIc: '甲', exitIc: '丙')],
      );

      expect(result.rows.single.totalMeters, 2400);
      expect(result.rows.single.drivenMeters, 2400);
      expect(result.routeCount, 1);
    },
  );

  test(
    'a road driven through another road counts each section by its road',
    () {
      // 乙 is a junction of R1 and R2: 甲 - 乙 (R1), 乙 - 己 (R2).
      final cross = [
        fakeIcPoint(name: '甲', routeNames: const ['R1']),
        fakeIcPoint(name: '乙', routeNames: const ['R1', 'R2']),
        fakeIcPoint(name: '己', routeNames: const ['R2']),
      ];
      final crossLinks = [_link('甲', '乙', 1000), _link('乙', '己', 600)];

      final result = _coverage(cross, crossLinks, [
        (entranceIc: '甲', exitIc: '己'),
      ]);

      expect(
        {for (final r in result.rows) r.routeName: r.drivenMeters},
        {'R1': 1000, 'R2': 600},
      );
    },
  );
}
