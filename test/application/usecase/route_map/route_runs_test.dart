import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/domain/entity/geo_point_entity.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

/// 東名の入口 → 東名と首都高のジャンクション → 首都高の出口.
FakeIcMasterIF _master({List<String> exitRoutes = const ['首都高速3号渋谷線']}) =>
    FakeIcMasterIF(
      [
        fakeIcPoint(
          name: '入口',
          routeNames: const ['東名高速道路'],
          latitude: 35.0,
          longitude: 139.0,
        ),
        fakeIcPoint(
          name: '分岐',
          routeNames: const ['東名高速道路', '首都高速3号渋谷線'],
          latitude: 35.1,
          longitude: 139.0,
        ),
        fakeIcPoint(
          name: '出口',
          routeNames: exitRoutes,
          latitude: 35.2,
          longitude: 139.0,
        ),
      ],
      links: const [
        IcLinkEntity(
          fromId: 'id-入口',
          toId: 'id-分岐',
          meters: 1000,
          shape: [GeoPointEntity(latitude: 35.05, longitude: 139.01)],
        ),
        IcLinkEntity(fromId: 'id-分岐', toId: 'id-出口', meters: 1000),
      ],
    );

Future<RouteSegmentDTO> _draw(
  FakeIcMasterIF master, {
  String entrance = '入口',
  String exit = '出口',
}) async {
  final lines = FakeStatementLineIF()
    ..stored.add(fakeStatementLine(entranceIc: entrance, exitIc: exit));
  final result = await fakeRouteMapUC(lines, master: master).execute();
  return result.segments.single;
}

void main() {
  group('the parts of a line by operator', () {
    test('changes at the point where the operator changes', () async {
      final segment = await _draw(_master());

      expect(segment.runs.map((r) => r.operator), ['NEXCO中日本', '首都高速道路']);
      // The first part: the entrance, the shape of the road, the junction.
      expect(segment.runs[0].points.map((p) => p.latitude), [
        35.0,
        35.05,
        35.1,
      ]);
      // The next part starts where the first ended, and ends at the exit.
      expect(segment.runs[1].points.map((p) => p.latitude), [35.1, 35.2]);
    });

    test('is one part when one operator has the whole way', () async {
      final segment = await _draw(_master(exitRoutes: const ['東名高速道路']));

      expect(segment.runs.map((r) => r.operator), ['NEXCO中日本']);
      expect(segment.runs.single.points.map((p) => p.latitude), [
        35.0,
        35.05,
        35.1,
        35.2,
      ]);
    });

    test('takes the first point when two points share no operator', () async {
      final master = FakeIcMasterIF(
        [
          fakeIcPoint(name: '入口', routeNames: const ['東名高速道路'], latitude: 35.0),
          fakeIcPoint(
            name: '出口',
            routeNames: const ['首都高速3号渋谷線'],
            latitude: 35.2,
          ),
        ],
        links: const [
          IcLinkEntity(fromId: 'id-入口', toId: 'id-出口', meters: 1000),
        ],
      );
      final segment = await _draw(master);

      expect(segment.runs.map((r) => r.operator), ['NEXCO中日本']);
    });

    test('uses what the other point knows, and unknown for none', () async {
      final known = FakeIcMasterIF(
        [
          fakeIcPoint(name: '入口', routeNames: const ['東名高速道路']),
          fakeIcPoint(name: '出口', routeNames: const ['?']),
        ],
        links: const [
          IcLinkEntity(fromId: 'id-入口', toId: 'id-出口', meters: 1000),
        ],
      );
      expect((await _draw(known)).runs.single.operator, 'NEXCO中日本');

      final reverse = FakeIcMasterIF(
        [
          fakeIcPoint(name: '入口', routeNames: const ['?']),
          fakeIcPoint(name: '出口', routeNames: const ['東名高速道路']),
        ],
        links: const [
          IcLinkEntity(fromId: 'id-入口', toId: 'id-出口', meters: 1000),
        ],
      );
      expect((await _draw(reverse)).runs.single.operator, 'NEXCO中日本');

      final none = FakeIcMasterIF(
        [
          fakeIcPoint(name: '入口', routeNames: const ['?']),
          fakeIcPoint(name: '出口', routeNames: const ['?']),
        ],
        links: const [
          IcLinkEntity(fromId: 'id-入口', toId: 'id-出口', meters: 1000),
        ],
      );
      expect((await _draw(none)).runs.single.operator, unknownOperator);
    });

    test('is one straight part when there is no way over the links', () async {
      final master = FakeIcMasterIF([
        fakeIcPoint(name: '入口', routeNames: const ['東名高速道路'], latitude: 35.0),
        fakeIcPoint(name: '出口', routeNames: const ['東名高速道路'], latitude: 35.2),
      ]);
      final segment = await _draw(master);

      expect(segment.runs, hasLength(1));
      expect(segment.runs.single.operator, 'NEXCO中日本');
      expect(segment.runs.single.points.map((p) => p.latitude), [35.0, 35.2]);
    });

    test('is unknown for a straight line on two operators', () async {
      final master = FakeIcMasterIF([
        fakeIcPoint(name: '入口', routeNames: const ['東名高速道路']),
        fakeIcPoint(name: '出口', routeNames: const ['首都高速3号渋谷線']),
      ]);
      final segment = await _draw(master);

      expect(segment.runs.single.operator, unknownOperator);
    });

    test('is one part when the entrance and the exit are one point', () async {
      final segment = await _draw(_master(), entrance: '入口', exit: '入口');

      expect(segment.runs, hasLength(1));
      expect(segment.runs.single.points, hasLength(2));
    });

    test(
      'knows an IC that the master has no route for, by the table',
      () async {
        final master = FakeIcMasterIF(
          [
            fakeIcPoint(name: '木更津金田', routeNames: const []),
            fakeIcPoint(name: '海ほたる', routeNames: const []),
          ],
          links: const [
            IcLinkEntity(fromId: 'id-木更津金田', toId: 'id-海ほたる', meters: 1000),
          ],
        );
        final segment = await _draw(master, entrance: '木更津金田', exit: '海ほたる');

        expect(segment.runs.single.operator, 'NEXCO東日本');
      },
    );
  });
}
