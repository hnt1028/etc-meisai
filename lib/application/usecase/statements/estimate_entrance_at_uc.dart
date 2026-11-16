import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/application/interface/ic_position_if.dart';
import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';

/// Estimates the entrance date and time of a line whose CSV row left it blank,
/// from the exit time and the distance. Design: PRC-016.
class EstimateEntranceAtUC {
  const EstimateEntranceAtUC({
    required this.icMaster,
    required this.icMappings,
    required this.icPositions,
  });

  /// The average speed on a toll road, and on an urban expressway, in km/h.
  static const highwayKmh = 80;
  static const urbanKmh = 60;

  /// The estimate is rounded to this many minutes.
  static const roundMinutes = 5;

  final IcMasterIF icMaster;
  final IcMappingIF icMappings;
  final IcPositionIF icPositions;

  /// The estimated entrance of [line], or null when it cannot be estimated:
  /// the entrance IC is blank, or the distance is not known.
  Future<DateTime?> execute(StatementLineDTO line) async {
    final entranceIc = line.entranceIc;
    if (entranceIc == null) return null;
    final lookup = IcLookup(
      points: await icMaster.findAll(),
      mappings: await icMappings.findAll(),
      positions: await icPositions.findAll(),
    );
    final meters = lineMeters(
      entranceIc: entranceIc,
      exitIc: line.exitIc,
      lookup: lookup,
      distance: IcDistance(await icMaster.findLinks()),
    );
    if (meters == null) return null;

    final operator = operatorOfRoutes(
      lookup.routeNamesOf(entranceIc, line.exitIc),
    );
    final kmh = isUrbanOperator(operator) ? urbanKmh : highwayKmh;
    // meters / (kmh * 1000 / 3600) seconds, as whole seconds.
    final seconds = (meters * 3.6 / kmh).round();
    final exact = line.exitAt.subtract(Duration(seconds: seconds));

    // To whole minutes (30 seconds and more count as a minute), then to the
    // nearest multiple of five minutes (3 and 4 go up, 1 and 2 go down).
    final minutes =
        exact.hour * 60 + exact.minute + (exact.second >= 30 ? 1 : 0);
    final rounded =
        ((minutes + roundMinutes ~/ 2) ~/ roundMinutes) * roundMinutes;
    final estimate = DateTime(
      exact.year,
      exact.month,
      exact.day,
    ).add(Duration(minutes: rounded));
    // Rounding must not put the entrance after the exit.
    return estimate.isAfter(line.exitAt) ? line.exitAt : estimate;
  }
}
