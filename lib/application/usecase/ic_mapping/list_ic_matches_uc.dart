import 'package:etc_meisai/application/dto/ic_match_dto.dart';
import 'package:etc_meisai/application/dto/ic_match_list_dto.dart';
import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/search_ic_points_uc.dart';
import 'package:etc_meisai/domain/value/ic_match_value.dart';

/// Lists the IC names that need the user's choice, and the registered
/// mappings. Design: PRC-005.
class ListIcMatchesUC {
  const ListIcMatchesUC({
    required this.statementLines,
    required this.icMaster,
    required this.icMappings,
  });

  final StatementLineIF statementLines;
  final IcMasterIF icMaster;
  final IcMappingIF icMappings;

  Future<IcMatchListDTO> execute() async {
    final lines = await statementLines.findAll();
    final points = await icMaster.findAll();
    final mappings = await icMappings.findAll();
    final lookup = IcLookup(points: points, mappings: mappings);

    // How many statement lines have each IC name. A line counts once.
    final counts = <String, int>{};
    for (final line in lines) {
      final names = {
        if (line.entranceIc != null) line.entranceIc!,
        line.exitIc,
      };
      for (final name in names) {
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }

    final unresolved = <IcMatchDTO>[];
    counts.forEach((name, count) {
      final resolution = lookup.resolve(name);
      if (resolution.state == IcMatchValue.ambiguous ||
          resolution.state == IcMatchValue.unknown) {
        unresolved.add(
          IcMatchDTO(
            icName: name,
            state: resolution.state,
            lineCount: count,
            candidates: [
              for (final p in resolution.candidates) toIcPointDTO(p),
            ],
          ),
        );
      }
    });
    unresolved.sort((a, b) {
      final byCount = b.lineCount.compareTo(a.lineCount);
      return byCount != 0 ? byCount : a.icName.compareTo(b.icName);
    });

    final registered = [
      for (final m in mappings)
        IcMatchDTO(
          icName: m.icName,
          state: IcMatchValue.registered,
          lineCount: counts[m.icName] ?? 0,
          point: lookup.pointOf(m.pointId) == null
              ? null
              : toIcPointDTO(lookup.pointOf(m.pointId)!),
        ),
    ]..sort((a, b) => a.icName.compareTo(b.icName));

    return IcMatchListDTO(unresolved: unresolved, registered: registered);
  }
}
