import 'dart:collection';
import 'dart:math' as math;

import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/domain/entity/geo_point_entity.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';

/// The shortest way over the links of the IC master: its length in meters, and
/// the points on it. A data holder of [IcDistance].
class IcRoute {
  const IcRoute(this.meters, this.pointIds);

  final int meters;

  /// The ids of the points from the start to the end, both included.
  final List<String> pointIds;
}

/// The distance between two IC points along the roads: the shortest way over
/// the links of the IC master. Design: docs/route-map.md ("地点の間の距離").
class IcDistance {
  IcDistance(Iterable<IcLinkEntity> links) {
    for (final link in links) {
      (_neighbors[link.fromId] ??= []).add((link.toId, link.meters));
      (_neighbors[link.toId] ??= []).add((link.fromId, link.meters));
      // The shortest link of a pair is the one that counts.
      final key = _pairKey(link.fromId, link.toId);
      final known = _links[key];
      if (known == null || link.meters < known.meters) _links[key] = link;
    }
  }

  final _neighbors = <String, List<(String, int)>>{};
  final _links = <String, IcLinkEntity>{};

  static String _pairKey(String a, String b) =>
      a.compareTo(b) <= 0 ? '$a\u0000$b' : '$b\u0000$a';

  /// The shape of the road from the point [from] to the point [to], which are
  /// next to each other: the points between them. Empty when it is not known.
  List<GeoPointEntity> shapeBetween(String from, String to) {
    final link = _links[_pairKey(from, to)];
    if (link == null) return const [];
    return link.fromId == from ? link.shape : link.shape.reversed.toList();
  }

  final _routes = <String, IcRoute?>{};

  /// The distance in meters from [a] to [b]: the shortest way over the links,
  /// or, when there is none (a point is not on the network, or the two are not
  /// connected), the straight distance between the positions.
  int metersBetween(IcPointEntity a, IcPointEntity b) {
    return roadRouteBetween(a, b)?.meters ??
        straightMeters(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  /// The shortest way over the links from [a] to [b]: its length, and the ids
  /// of the points on it, [a] and [b] included. Null when there is none (a
  /// point is not on the network, or the two are not connected).
  IcRoute? roadRouteBetween(IcPointEntity a, IcPointEntity b) {
    if (a.id == b.id) return IcRoute(0, [a.id]);
    // The way back is the same way, backwards.
    final forward = a.id.compareTo(b.id) <= 0;
    final key = forward ? '${a.id}\u0000${b.id}' : '${b.id}\u0000${a.id}';
    if (!_routes.containsKey(key)) {
      _routes[key] = forward ? _shortest(a.id, b.id) : _shortest(b.id, a.id);
    }
    final route = _routes[key];
    if (route == null) return null;
    return forward
        ? route
        : IcRoute(route.meters, route.pointIds.reversed.toList());
  }

  /// Dijkstra's method from [from] until [to] is reached. Null when [to]
  /// cannot be reached.
  IcRoute? _shortest(String from, String to) {
    if (!_neighbors.containsKey(from) || !_neighbors.containsKey(to)) {
      return null;
    }
    final best = <String, int>{from: 0};
    final before = <String, String>{};
    final queue = SplayTreeSet<(int, String)>(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    )..add((0, from));
    while (queue.isNotEmpty) {
      final (distance, id) = queue.first;
      queue.remove(queue.first);
      if (id == to) {
        final ids = [to];
        while (ids.last != from) {
          ids.add(before[ids.last]!);
        }
        return IcRoute(distance, ids.reversed.toList());
      }
      if (distance > (best[id] ?? distance)) continue;
      for (final (next, meters) in _neighbors[id] ?? const <(String, int)>[]) {
        final candidate = distance + meters;
        final known = best[next];
        if (known == null || candidate < known) {
          if (known != null) queue.remove((known, next));
          best[next] = candidate;
          before[next] = id;
          queue.add((candidate, next));
        }
      }
    }
    return null;
  }

  /// The straight distance between two positions, in meters (a sphere).
  static int straightMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const radius = 6371000.0;
    double rad(double degrees) => degrees * math.pi / 180;
    final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return (2 * radius * math.asin(math.sqrt(h))).round();
  }
}

/// The distance of a statement line in meters, or null when it is not known
/// (docs/aggregation.md, "距離の求め方"). The aggregation and the estimate of
/// the entrance time use it.
int? lineMeters({
  required String? entranceIc,
  required String exitIc,
  required IcLookup lookup,
  required IcDistance distance,
}) {
  if (entranceIc == null) return null;
  final entrance = lookup.placeOf(entranceIc);
  final exit = lookup.placeOf(exitIc);
  if (entrance == null || exit == null) return null;
  // Two master points: the way over the roads. A position the user chose has
  // no point, and is measured straight.
  final entrancePoint = entrance.point, exitPoint = exit.point;
  if (entrancePoint != null && exitPoint != null) {
    return distance.metersBetween(entrancePoint, exitPoint);
  }
  return IcDistance.straightMeters(
    entrance.latitude,
    entrance.longitude,
    exit.latitude,
    exit.longitude,
  );
}

/// The points between the entrance and the exit of a line, in order, for the
/// line to be drawn along the road (docs/route-map.md, "地図に描く経路"): the
/// points of the shape of each road between two points of the way, and the
/// points of the way between them. Empty when the line is drawn straight: a
/// position is the user's own (it is not a point of the master), or there is
/// no way over the links.
List<GeoPointEntity> routeVerticesOf({
  required IcPlace? entrance,
  required IcPlace? exit,
  required IcLookup lookup,
  required IcDistance distance,
}) {
  final from = entrance?.point, to = exit?.point;
  if (from == null || to == null) return const [];
  final route = distance.roadRouteBetween(from, to);
  if (route == null) return const [];
  final ids = route.pointIds;
  final vertices = <GeoPointEntity>[];
  for (var i = 0; i + 1 < ids.length; i++) {
    vertices.addAll(distance.shapeBetween(ids[i], ids[i + 1]));
    // The point where one road ends and the next begins: not the exit.
    if (i + 2 < ids.length) {
      final point = lookup.pointOf(ids[i + 1]);
      if (point != null) {
        vertices.add(
          GeoPointEntity(latitude: point.latitude, longitude: point.longitude),
        );
      }
    }
  }
  return vertices;
}
