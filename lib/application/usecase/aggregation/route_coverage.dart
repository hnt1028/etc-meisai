import 'package:etc_meisai/application/dto/route_coverage_row_dto.dart';
import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/application/usecase/route_map/implied_entrance.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';

/// What [routeCoverageOf] found.
class RouteCoverage {
  const RouteCoverage({required this.rows, required this.routeCount});

  /// The roads that were driven at least a little: the most covered first.
  final List<RouteCoverageRowDTO> rows;

  /// How many roads the IC master has (with a section between two points).
  final int routeCount;
}

/// How much of each road the lines cover (docs/aggregation.md, "路線の走破
/// 率").
///
/// A section is a link of the IC master between two neighboring points that
/// share a road. A line covers the sections of the shortest way over the links
/// from its entrance to its exit ([distance]); a blank entrance is the one of
/// the table of the short roads. A line whose entrance or exit is not a point
/// of the master (a position the user chose) or has no way covers nothing.
RouteCoverage routeCoverageOf({
  required List<IcPointEntity> points,
  required List<IcLinkEntity> links,
  required IcDistance distance,
  required IcLookup lookup,
  required Iterable<({String? entranceIc, String exitIc})> trips,
}) {
  final byId = {for (final p in points) p.id: p};

  // The sections: the shortest link of a pair of points counts.
  final sections = <String, ({String route, int meters})>{};
  for (final link in links) {
    final from = byId[link.fromId], to = byId[link.toId];
    if (from == null || to == null) continue;
    final route = from.routeNames.where(to.routeNames.contains).firstOrNull;
    if (route == null) continue;
    final key = _key(link.fromId, link.toId);
    final known = sections[key];
    if (known == null || link.meters < known.meters) {
      sections[key] = (route: route, meters: link.meters);
    }
  }
  final totals = <String, int>{};
  for (final s in sections.values) {
    totals.update(s.route, (m) => m + s.meters, ifAbsent: () => s.meters);
  }

  final driven = <String>{};
  for (final trip in trips) {
    final entranceName =
        trip.entranceIc ?? impliedEntranceNameOf(trip.exitIc, lookup);
    if (entranceName == null) continue;
    final from = lookup.placeOf(entranceName)?.point;
    final to = lookup.placeOf(trip.exitIc)?.point;
    if (from == null || to == null) continue;
    final ids = distance.roadRouteBetween(from, to)?.pointIds;
    if (ids == null) continue;
    for (var i = 0; i + 1 < ids.length; i++) {
      driven.add(_key(ids[i], ids[i + 1]));
    }
  }
  final drivenTotals = <String, int>{};
  for (final key in driven) {
    final section = sections[key];
    if (section == null) continue;
    drivenTotals.update(
      section.route,
      (m) => m + section.meters,
      ifAbsent: () => section.meters,
    );
  }

  final rows = [
    for (final entry in drivenTotals.entries)
      if (entry.value > 0)
        RouteCoverageRowDTO(
          routeName: entry.key,
          totalMeters: totals[entry.key]!,
          drivenMeters: entry.value,
        ),
  ];
  rows.sort((a, b) {
    // The share, compared without division: a/b against c/d.
    final byShare = (b.drivenMeters * a.totalMeters).compareTo(
      a.drivenMeters * b.totalMeters,
    );
    if (byShare != 0) return byShare;
    final byLength = b.drivenMeters.compareTo(a.drivenMeters);
    return byLength != 0 ? byLength : a.routeName.compareTo(b.routeName);
  });
  return RouteCoverage(rows: rows, routeCount: totals.length);
}

String _key(String a, String b) =>
    a.compareTo(b) <= 0 ? '$a\u0000$b' : '$b\u0000$a';
