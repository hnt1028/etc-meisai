import 'package:etc_meisai/application/dto/entrance_candidates_dto.dart';
import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/application/interface/ic_position_if.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';

/// Lists the choices for the entrance IC of a line that has none: the
/// entrance ICs the user has used, and the ICs on the routes of the exit.
/// Design: PRC-020.
class ListEntranceCandidatesUC {
  const ListEntranceCandidatesUC({
    required this.statementLines,
    required this.icMaster,
    required this.icMappings,
    required this.icPositions,
  });

  final StatementLineIF statementLines;
  final IcMasterIF icMaster;
  final IcMappingIF icMappings;
  final IcPositionIF icPositions;

  Future<EntranceCandidatesDTO> execute(StatementLineDTO line) async {
    final all = await statementLines.findAll();
    final points = await icMaster.findAll();
    final lookup = IcLookup(
      points: points,
      mappings: await icMappings.findAll(),
      positions: await icPositions.findAll(),
    );

    // The entrance ICs in use, and how many times with this exit.
    final total = <String, int>{};
    final withExit = <String, int>{};
    for (final stored in all) {
      final name = stored.entranceIc;
      if (name == null || name.isEmpty) continue;
      total[name] = (total[name] ?? 0) + 1;
      if (stored.exitIc == line.exitIc) {
        withExit[name] = (withExit[name] ?? 0) + 1;
      }
    }
    final names = total.keys.toList()
      ..sort((a, b) {
        final byExit = (withExit[b] ?? 0).compareTo(withExit[a] ?? 0);
        if (byExit != 0) return byExit;
        final byTotal = total[b]!.compareTo(total[a]!);
        return byTotal != 0 ? byTotal : a.compareTo(b);
      });
    final used = [
      for (final name in names)
        EntranceCandidateDTO(
          icName: name,
          routeNames: lookup.routeNamesOf(name, line.exitIc),
          uses: withExit[name] ?? 0,
        ),
    ];

    final usedPointIds = {
      for (final name in names) ?lookup.resolve(name).point?.id,
    };
    return EntranceCandidatesDTO(
      used: used,
      sameRoute: _sameRoute(line, points, lookup, usedPointIds),
    );
  }

  /// The points that share a route with the exit, the nearest first.
  List<EntranceCandidateDTO> _sameRoute(
    StatementLineDTO line,
    List<IcPointEntity> points,
    IcLookup lookup,
    Set<String> usedPointIds,
  ) {
    final exit = lookup.resolve(line.exitIc).point;
    if (exit == null || exit.routeNames.isEmpty) return const [];
    final candidates = <String, IcPointEntity>{};
    for (final point in points) {
      if (point.id == exit.id || usedPointIds.contains(point.id)) continue;
      if (point.kind == IcKindValue.junction) continue;
      if (!point.routeNames.any(exit.routeNames.contains)) continue;
      candidates.putIfAbsent(IcLookup.fold(point.name), () => point);
    }
    double meters(IcPointEntity p) => IcDistance.straightMeters(
      exit.latitude,
      exit.longitude,
      p.latitude,
      p.longitude,
    ).toDouble();
    final sorted = candidates.values.toList()
      ..sort((a, b) {
        final byDistance = meters(a).compareTo(meters(b));
        return byDistance != 0 ? byDistance : a.name.compareTo(b.name);
      });
    return [
      for (final p in sorted)
        EntranceCandidateDTO(
          icName: p.name,
          routeNames: List.unmodifiable(p.routeNames),
          uses: 0,
        ),
    ];
  }
}
