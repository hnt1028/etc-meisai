import 'package:etc_meisai/application/dto/aggregation_dto.dart';
import 'package:etc_meisai/application/dto/aggregation_row_dto.dart';
import 'package:etc_meisai/application/dto/aggregation_summary_dto.dart';
import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/application/interface/ic_position_if.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/application/usecase/aggregation/ic_distance.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/application/usecase/statements/statement_filter.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';

/// Aggregates the statement lines. Design: PRC-013, definitions in
/// docs/aggregation.md.
class AggregateStatementsUC {
  const AggregateStatementsUC({
    required this.statementLines,
    required this.icMaster,
    required this.icMappings,
    required this.icPositions,
  });

  /// The label of the lines without a tag, in the rows of the tags.
  static const untaggedLabel = 'タグなし';

  /// How many routes and ICs are listed.
  static const topCount = 10;

  final StatementLineIF statementLines;
  final IcMasterIF icMaster;
  final IcMappingIF icMappings;
  final IcPositionIF icPositions;

  /// The conditions are the ones of the statement list ([from] and [to] are
  /// dates, and are included in the period).
  Future<AggregationDTO> execute({
    DateTime? from,
    DateTime? to,
    int? vehicleNumber,
    String? cardNumberSuffix,
    String? tag,
  }) async {
    final all = await statementLines.findAll();
    final lookup = IcLookup(
      points: await icMaster.findAll(),
      mappings: await icMappings.findAll(),
      positions: await icPositions.findAll(),
    );
    final distance = IcDistance(await icMaster.findLinks());
    final lines = filterStatementLines(
      all,
      from: from,
      to: to,
      vehicleNumber: vehicleNumber,
      cardNumberSuffix: cardNumberSuffix,
      tag: tag,
    );

    final weeks = _Tally(), months = _Tally(), years = _Tally();
    final operators = _Tally(), hours = _Tally();
    final routes = _Tally(), ics = _Tally(), discountTypes = _Tally();
    final tags = _Tally();
    var fareTotal = 0, discountTotal = 0, distanceTotal = 0, unknown = 0;

    for (final line in lines) {
      final discount = _discountOf(line);
      final meters = lineMeters(
        entranceIc: line.entranceIc,
        exitIc: line.exitIc,
        lookup: lookup,
        distance: distance,
      );
      fareTotal += line.fare;
      discountTotal += discount;
      distanceTotal += meters ?? 0;
      if (meters == null) unknown++;
      // A line without a distance adds 0 to the rows that have a distance.
      final m = meters ?? 0;

      final exit = line.exitAt;
      final monday = DateTime(
        exit.year,
        exit.month,
        exit.day,
      ).subtract(Duration(days: exit.weekday - 1));
      weeks.add(_date(monday), line.fare, discount, m);
      months.add('${exit.year}/${_two(exit.month)}', line.fare, discount, m);
      years.add('${exit.year}', line.fare, discount, m);
      hours.add('${exit.hour}', line.fare, discount, m);

      final routeNames = lookup.routeNamesOf(line.entranceIc, line.exitIc);
      operators.add(operatorOfRoutes(routeNames), line.fare, discount, m);
      for (final name in routeNames) {
        routes.add(name);
      }
      // A line counts once for an IC name, even when both ICs have it.
      for (final name in {?line.entranceIc, line.exitIc}) {
        ics.add(name);
      }
      // A line counts for each of its tags, or for "no tag".
      for (final name in line.tags.isEmpty ? [untaggedLabel] : line.tags) {
        tags.add(name, line.fare, discount, m);
      }
      for (final type in line.discountTypes.toSet()) {
        discountTypes.add(type, null, discount);
      }
    }

    return AggregationDTO(
      summary: AggregationSummaryDTO(
        lineCount: lines.length,
        fareTotal: fareTotal,
        discountTotal: discountTotal,
        distanceTotal: distanceTotal,
        distanceUnknownCount: unknown,
      ),
      weeks: weeks.rows(byLabelDescending: true),
      months: months.rows(byLabelDescending: true),
      years: years.rows(byLabelDescending: true),
      operators: operators.rows(byFare: true),
      routes: routes.rows(limit: topCount),
      ics: ics.rows(limit: topCount),
      routesOtherCount: routes.countBeyond(topCount),
      icsOtherCount: ics.countBeyond(topCount),
      hours: [
        for (var hour = 0; hour < 24; hour++)
          hours.rowOf('$hour') ??
              AggregationRowDTO(
                label: '$hour',
                count: 0,
                fare: 0,
                discount: 0,
                distance: 0,
              ),
      ],
      discountTypes: discountTypes.rows(),
      vehicleNumberChoices: vehicleNumberChoicesOf(all),
      cardNumberChoices: cardNumberChoicesOf(all),
      tags: tags.rows(byFare: true),
      tagChoices: tagChoicesOf(all),
    );
  }

  /// The ETC discount as a positive amount. Blank (no discount) is 0.
  static int _discountOf(StatementLineEntity line) =>
      line.etcDiscount?.abs() ?? 0;

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _date(DateTime day) =>
      '${day.year}/${_two(day.month)}/${_two(day.day)}';
}

/// Counts lines by label. A row has a fare (or a discount) only when [add]
/// was given one for its label.
class _Tally {
  final _counts = <String, int>{};
  final _fares = <String, int>{};
  final _discounts = <String, int>{};
  final _distances = <String, int>{};

  void add(String label, [int? fare, int? discount, int? distance]) {
    _counts[label] = (_counts[label] ?? 0) + 1;
    if (fare != null) _fares[label] = (_fares[label] ?? 0) + fare;
    if (discount != null) {
      _discounts[label] = (_discounts[label] ?? 0) + discount;
    }
    if (distance != null) {
      _distances[label] = (_distances[label] ?? 0) + distance;
    }
  }

  AggregationRowDTO? rowOf(String label) {
    final count = _counts[label];
    if (count == null) return null;
    return AggregationRowDTO(
      label: label,
      count: count,
      fare: _fares[label],
      discount: _discounts[label],
      distance: _distances[label],
    );
  }

  /// The total count of the rows after the first [limit] ones, in the order
  /// of [rows] by count.
  int countBeyond(int limit) {
    final all = rows();
    if (all.length <= limit) return 0;
    return all.skip(limit).fold(0, (sum, r) => sum + r.count);
  }

  /// The rows, the one with the most lines first (the default), the one with
  /// the largest label first ([byLabelDescending]), or the one with the
  /// largest fare first ([byFare]). Ties are in the order of the label.
  List<AggregationRowDTO> rows({
    bool byLabelDescending = false,
    bool byFare = false,
    int? limit,
  }) {
    final rows = [for (final label in _counts.keys) rowOf(label)!];
    rows.sort((a, b) {
      if (byLabelDescending) return b.label.compareTo(a.label);
      final c = byFare
          ? (b.fare ?? 0).compareTo(a.fare ?? 0)
          : b.count.compareTo(a.count);
      return c != 0 ? c : a.label.compareTo(b.label);
    });
    return limit == null || rows.length <= limit
        ? rows
        : rows.sublist(0, limit);
  }
}
