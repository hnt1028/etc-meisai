import 'package:etc_meisai/application/dto/route_coverage_row_dto.dart';
import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/application/usecase/route_map/implied_entrance.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';

/// What [routeCoverageOf] found.
class RouteCoverage {
  const RouteCoverage({required this.rows, required this.routeCount});

  /// The roads that were driven at least a little: the most covered first.
  final List<RouteCoverageRowDTO> rows;

  /// How many roads the IC master has (with an IC on them).
  final int routeCount;
}

/// How many of the ICs of each road the lines cover (docs/aggregation.md,
/// "路線の走破率").
///
/// The ICs of a road are the points of the IC master that have the road in
/// their route names, except the other kind (service areas, toll gates):
/// general ICs, smart ICs and junctions, counted by name. A line covers the
/// ICs on the shortest way over the links from its entrance to its exit
/// ([distance]), the entrance and the exit included; a blank entrance is the
/// one of the table of the short roads. A line whose entrance or exit is not a
/// point of the master (a position the user chose) or has no way covers
/// nothing.
RouteCoverage routeCoverageOf({
  required List<IcPointEntity> points,
  required IcDistance distance,
  required IcLookup lookup,
  required Iterable<({String? entranceIc, String exitIc})> trips,
}) {
  final byId = {for (final p in points) p.id: p};

  final totals = <String, Set<String>>{};
  for (final p in points) {
    if (p.kind == IcKindValue.other) continue;
    for (final route in p.routeNames) {
      (totals[route] ??= {}).add(p.name);
    }
  }

  final driven = <String, Set<String>>{};
  for (final trip in trips) {
    final entranceName =
        trip.entranceIc ?? impliedEntranceNameOf(trip.exitIc, lookup);
    if (entranceName == null) continue;
    final from = lookup.placeOf(entranceName)?.point;
    final to = lookup.placeOf(trip.exitIc)?.point;
    if (from == null || to == null) continue;
    final ids = distance.roadRouteBetween(from, to)?.pointIds;
    if (ids == null) continue;
    for (final id in ids) {
      final p = byId[id];
      if (p == null || p.kind == IcKindValue.other) continue;
      for (final route in p.routeNames) {
        (driven[route] ??= {}).add(p.name);
      }
    }
  }

  final rows = [
    for (final entry in driven.entries)
      if (entry.value.isNotEmpty)
        RouteCoverageRowDTO(
          routeName: entry.key,
          totalCount: totals[entry.key]!.length,
          drivenCount: entry.value.length,
        ),
  ];
  rows.sort((a, b) {
    // The share, compared without division: a/b against c/d.
    final byShare = (b.drivenCount * a.totalCount).compareTo(
      a.drivenCount * b.totalCount,
    );
    if (byShare != 0) return byShare;
    final byCount = b.drivenCount.compareTo(a.drivenCount);
    return byCount != 0 ? byCount : a.routeName.compareTo(b.routeName);
  });
  return RouteCoverage(rows: rows, routeCount: totals.length);
}
