import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_coverage.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

IcLinkEntity _link(String a, String b, [int meters = 1000]) =>
    IcLinkEntity(fromId: 'id-$a', toId: 'id-$b', meters: meters);

RouteCoverage _coverage(
  List<IcPointEntity> points,
  List<IcLinkEntity> links,
  List<({String? entranceIc, String exitIc})> trips,
) => routeCoverageOf(
  points: points,
  distance: IcDistance(links),
  lookup: IcLookup(points: points, mappings: const [], positions: const []),
  trips: trips,
);

Map<String, (int, int)> _counts(RouteCoverage c) => {
  for (final r in c.rows) r.routeName: (r.drivenCount, r.totalCount),
};

void main() {
  // R1: 甲 - 乙 - 丙 - 丁 - 戊. R2: 己 - 庚.
  final points = [
    for (final n in ['甲', '乙', '丙', '丁', '戊'])
      fakeIcPoint(name: n, routeNames: const ['R1']),
    for (final n in ['己', '庚']) fakeIcPoint(name: n, routeNames: const ['R2']),
  ];
  final links = [
    _link('甲', '乙'),
    _link('乙', '丙'),
    _link('丙', '丁'),
    _link('丁', '戊'),
    _link('己', '庚'),
  ];

  test('counts the entrance, the exit and the ICs between them', () {
    final result = _coverage(points, links, [(entranceIc: '乙', exitIc: '丁')]);

    expect(result.routeCount, 2);
    // 乙, 丙 and 丁 of the five ICs of R1.
    expect(_counts(result), {'R1': (3, 5)});
  });

  test('counts an IC once, however often it is passed', () {
    final result = _coverage(points, links, [
      (entranceIc: '甲', exitIc: '乙'),
      (entranceIc: '乙', exitIc: '甲'),
      (entranceIc: '乙', exitIc: '丙'),
    ]);

    expect(_counts(result), {'R1': (3, 5)});
  });

  test('gives nothing when no line is driven', () {
    final result = _coverage(points, links, const []);

    expect(result.rows, isEmpty);
    expect(result.routeCount, 2);
  });

  test('lists the most covered road first, then the one with more ICs', () {
    final result = _coverage(points, links, [
      (entranceIc: '甲', exitIc: '戊'), // all 5 of R1
      (entranceIc: '己', exitIc: '庚'), // all 2 of R2
    ]);

    // Both are all covered: the one with more ICs first.
    expect(result.rows.map((r) => r.routeName), ['R1', 'R2']);

    final partial = _coverage(points, links, [
      (entranceIc: '甲', exitIc: '乙'), // 2 of 5
      (entranceIc: '己', exitIc: '庚'), // 2 of 2
    ]);
    expect(partial.rows.map((r) => r.routeName), ['R2', 'R1']);
  });

  test('breaks a tie of the share and the count by the name', () {
    final two = [
      fakeIcPoint(name: 'a1', routeNames: const ['B路線']),
      fakeIcPoint(name: 'a2', routeNames: const ['B路線']),
      fakeIcPoint(name: 'b1', routeNames: const ['A路線']),
      fakeIcPoint(name: 'b2', routeNames: const ['A路線']),
    ];

    final result = _coverage(
      two,
      [_link('a1', 'a2'), _link('b1', 'b2')],
      [(entranceIc: 'a1', exitIc: 'a2'), (entranceIc: 'b1', exitIc: 'b2')],
    );

    expect(result.rows.map((r) => r.routeName), ['A路線', 'B路線']);
  });

  test('does not count a service area or a toll gate', () {
    final withPa = [
      fakeIcPoint(name: '甲', routeNames: const ['R1']),
      fakeIcPoint(
        name: '甲PA',
        kind: IcKindValue.other,
        routeNames: const ['R1'],
      ),
      fakeIcPoint(name: '乙', routeNames: const ['R1']),
    ];

    final result = _coverage(
      withPa,
      [_link('甲', '甲PA'), _link('甲PA', '乙')],
      [(entranceIc: '甲', exitIc: '乙')],
    );

    // The PA is on the way, but it is not an IC.
    expect(_counts(result), {'R1': (2, 2)});
  });

  test('counts a smart IC and a junction', () {
    final kinds = [
      fakeIcPoint(name: '甲', routeNames: const ['R1']),
      fakeIcPoint(
        name: '乙SIC',
        kind: IcKindValue.smartInterchange,
        routeNames: const ['R1'],
      ),
      fakeIcPoint(
        name: '丙JCT',
        kind: IcKindValue.junction,
        routeNames: const ['R1'],
      ),
    ];

    final result = _coverage(
      kinds,
      [_link('甲', '乙SIC'), _link('乙SIC', '丙JCT')],
      [(entranceIc: '甲', exitIc: '丙JCT')],
    );

    expect(_counts(result), {'R1': (3, 3)});
  });

  test('counts the points of one name as one IC', () {
    // 甲 has two points (the two directions), with the same name.
    final twin = [
      fakeIcPoint(id: 'a-up', name: '甲', routeNames: const ['R1']),
      fakeIcPoint(id: 'a-down', name: '甲', routeNames: const ['R1']),
      fakeIcPoint(name: '乙', routeNames: const ['R1']),
    ];

    final result = _coverage(
      twin,
      [
        const IcLinkEntity(fromId: 'a-up', toId: 'id-乙', meters: 10),
        const IcLinkEntity(fromId: 'a-down', toId: 'id-乙', meters: 10),
      ],
      [(entranceIc: '乙', exitIc: '乙')],
    );

    // 甲 and 乙: two ICs, although there are three points.
    expect(_counts(result), {'R1': (1, 2)});
  });

  test('takes the entrance of a short road when the entrance is blank', () {
    final road = [
      fakeIcPoint(name: '中ノ湯', routeNames: const ['安房峠道路']),
      fakeIcPoint(name: '平湯', routeNames: const ['安房峠道路']),
    ];

    final result = _coverage(
      road,
      [_link('中ノ湯', '平湯')],
      [(entranceIc: null, exitIc: '平湯')],
    );

    expect(_counts(result), {'安房峠道路': (2, 2)});
  });

  test('skips a line without an entrance that is not known', () {
    final result = _coverage(points, links, [(entranceIc: null, exitIc: '丙')]);

    expect(result.rows, isEmpty);
  });

  test('skips a line whose IC is not in the master, or has no way', () {
    final result = _coverage(points, links, [
      (entranceIc: '無い', exitIc: '丙'),
      (entranceIc: '甲', exitIc: '無い'),
      // 甲 and 己 are on roads that do not meet.
      (entranceIc: '甲', exitIc: '己'),
    ]);

    expect(result.rows, isEmpty);
  });

  test('an IC where two roads meet counts for both', () {
    // 乙 is a junction of R1 and R2.
    final cross = [
      fakeIcPoint(name: '甲', routeNames: const ['R1']),
      fakeIcPoint(name: '乙', routeNames: const ['R1', 'R2']),
      fakeIcPoint(name: '己', routeNames: const ['R2']),
    ];

    final result = _coverage(
      cross,
      [_link('甲', '乙'), _link('乙', '己')],
      [(entranceIc: '甲', exitIc: '己')],
    );

    expect(_counts(result), {'R1': (2, 2), 'R2': (2, 2)});
  });

  test('ignores a point that is not on the way, even one of the same road', () {
    final result = _coverage(points, links, [(entranceIc: '丙', exitIc: '丙')]);

    expect(_counts(result), {'R1': (1, 5)});
  });
}
