import 'dart:collection';
import 'dart:math' as math;

import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';

/// The distance between two IC points along the roads: the shortest way over
/// the links of the IC master. Design: docs/route-map.md ("地点の間の距離").
class IcDistance {
  IcDistance(Iterable<IcLinkEntity> links) {
    for (final link in links) {
      (_neighbors[link.fromId] ??= []).add((link.toId, link.meters));
      (_neighbors[link.toId] ??= []).add((link.fromId, link.meters));
    }
  }

  final _neighbors = <String, List<(String, int)>>{};
  final _cache = <String, int>{};

  /// The distance in meters from [a] to [b]: the shortest way over the links,
  /// or, when there is none (a point is not on the network, or the two are not
  /// connected), the straight distance between the positions.
  int metersBetween(IcPointEntity a, IcPointEntity b) {
    if (a.id == b.id) return 0;
    final key = a.id.compareTo(b.id) <= 0
        ? '${a.id}\u0000${b.id}'
        : '${b.id}\u0000${a.id}';
    return _cache[key] ??=
        _shortest(a.id, b.id) ??
        straightMeters(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  /// Dijkstra's method from [from] until [to] is reached. Null when [to]
  /// cannot be reached.
  int? _shortest(String from, String to) {
    if (!_neighbors.containsKey(from) || !_neighbors.containsKey(to)) {
      return null;
    }
    final best = <String, int>{from: 0};
    final queue = SplayTreeSet<(int, String)>(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    )..add((0, from));
    while (queue.isNotEmpty) {
      final (distance, id) = queue.first;
      queue.remove(queue.first);
      if (id == to) return distance;
      if (distance > (best[id] ?? distance)) continue;
      for (final (next, meters) in _neighbors[id] ?? const <(String, int)>[]) {
        final candidate = distance + meters;
        final known = best[next];
        if (known == null || candidate < known) {
          if (known != null) queue.remove((known, next));
          best[next] = candidate;
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
