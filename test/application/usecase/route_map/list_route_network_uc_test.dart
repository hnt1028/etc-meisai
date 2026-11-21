import 'package:etc_meisai/application/usecase/route_map/list_route_network_uc.dart';
import 'package:etc_meisai/domain/entity/geo_point_entity.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  test('makes a line for each link, along the shape of the road', () async {
    final uc = ListRouteNetworkUC(
      icMaster: FakeIcMasterIF(
        [
          fakeIcPoint(
            name: '甲',
            routeNames: const ['R1'],
            latitude: 35.0,
            longitude: 139.0,
          ),
          fakeIcPoint(
            name: '乙',
            routeNames: const ['R1'],
            latitude: 35.2,
            longitude: 139.2,
          ),
        ],
        links: const [
          IcLinkEntity(
            fromId: 'id-甲',
            toId: 'id-乙',
            meters: 1000,
            shape: [GeoPointEntity(latitude: 35.1, longitude: 139.3)],
          ),
        ],
      ),
    );

    final network = await uc.execute();

    expect(network.lines, hasLength(1));
    final line = network.lines.single;
    expect(line.routeName, 'R1');
    expect(line.points.map((p) => (p.latitude, p.longitude)), [
      (35.0, 139.0),
      (35.1, 139.3),
      (35.2, 139.2),
    ]);
  });

  test('gives no road name to a link whose points share none', () async {
    final uc = ListRouteNetworkUC(
      icMaster: FakeIcMasterIF(
        [
          fakeIcPoint(name: '甲', routeNames: const ['R1']),
          fakeIcPoint(name: '乙', routeNames: const ['R2']),
        ],
        links: const [IcLinkEntity(fromId: 'id-甲', toId: 'id-乙', meters: 10)],
      ),
    );

    final network = await uc.execute();

    expect(network.lines.single.routeName, isNull);
    expect(network.labels, isEmpty);
  });

  test('writes the name of a road once, at its longest link', () async {
    final uc = ListRouteNetworkUC(
      icMaster: FakeIcMasterIF(
        [
          fakeIcPoint(
            name: '甲',
            routeNames: const ['R1'],
            latitude: 35.0,
            longitude: 139.0,
          ),
          fakeIcPoint(
            name: '乙',
            routeNames: const ['R1'],
            latitude: 35.0,
            longitude: 139.1,
          ),
          fakeIcPoint(
            name: '丙',
            routeNames: const ['R1'],
            latitude: 35.0,
            longitude: 139.5,
          ),
        ],
        links: const [
          IcLinkEntity(fromId: 'id-乙', toId: 'id-丙', meters: 9000),
          IcLinkEntity(fromId: 'id-甲', toId: 'id-乙', meters: 1000),
        ],
      ),
    );

    final network = await uc.execute();

    expect(network.labels, hasLength(1));
    expect(network.labels.single.routeName, 'R1');
    // The link with 9000 meters runs from 139.1 to 139.5: the label is at one
    // of its points (the middle one of the two).
    expect(network.labels.single.longitude, 139.5);
  });

  test('leaves out a link of a point the master does not have', () async {
    final uc = ListRouteNetworkUC(
      icMaster: FakeIcMasterIF(
        [
          fakeIcPoint(name: '甲', routeNames: const ['R1']),
        ],
        links: const [
          IcLinkEntity(fromId: 'id-甲', toId: 'id-無い', meters: 10),
          IcLinkEntity(fromId: 'id-無い', toId: 'id-甲', meters: 10),
        ],
      ),
    );

    final network = await uc.execute();

    expect(network.lines, isEmpty);
    expect(network.labels, isEmpty);
  });
}
