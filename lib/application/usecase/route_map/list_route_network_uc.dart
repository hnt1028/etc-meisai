import 'package:etc_meisai/application/dto/route_network_dto.dart';
import 'package:etc_meisai/application/dto/route_vertex_dto.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';

/// Makes the lines of every road of the IC master, and the place of the name
/// of each road. Design: PRC-026.
class ListRouteNetworkUC {
  const ListRouteNetworkUC({required this.icMaster});

  final IcMasterIF icMaster;

  Future<RouteNetworkDTO> execute() async {
    final points = {for (final p in await icMaster.findAll()) p.id: p};
    final lines = <RouteNetworkLineDTO>[];
    // The longest link of each road holds its name, at the middle of its
    // shape.
    final longest = <String, int>{};
    final labels = <String, RouteNetworkLabelDTO>{};

    for (final link in await icMaster.findLinks()) {
      final from = points[link.fromId];
      final to = points[link.toId];
      if (from == null || to == null) continue;
      final vertices = [
        RouteVertexDTO(latitude: from.latitude, longitude: from.longitude),
        for (final g in link.shape)
          RouteVertexDTO(latitude: g.latitude, longitude: g.longitude),
        RouteVertexDTO(latitude: to.latitude, longitude: to.longitude),
      ];
      final routeName = from.routeNames
          .where(to.routeNames.contains)
          .firstOrNull;
      lines.add(RouteNetworkLineDTO(routeName: routeName, points: vertices));

      if (routeName == null) continue;
      final known = longest[routeName];
      if (known == null || link.meters > known) {
        longest[routeName] = link.meters;
        final middle = vertices[vertices.length ~/ 2];
        labels[routeName] = RouteNetworkLabelDTO(
          routeName: routeName,
          latitude: middle.latitude,
          longitude: middle.longitude,
        );
      }
    }
    return RouteNetworkDTO(lines: lines, labels: labels.values.toList());
  }
}
