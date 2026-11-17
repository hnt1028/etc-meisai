import 'package:etc_meisai/application/dto/statement_list_dto.dart';
import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/application/interface/ic_position_if.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/application/interface/vehicle_type_master_if.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/application/usecase/statements/statement_filter.dart';

/// Lists the stored statement lines for the statement list screen.
/// Design: PRC-004.
class ListStatementLinesUC {
  const ListStatementLinesUC({
    required this.statementLines,
    required this.icMaster,
    required this.icMappings,
    required this.icPositions,
    required this.vehicleTypes,
  });

  final StatementLineIF statementLines;
  final IcMasterIF icMaster;
  final IcMappingIF icMappings;
  final IcPositionIF icPositions;
  final VehicleTypeMasterIF vehicleTypes;

  /// [from] and [to] are dates (the time is ignored) and are included in the
  /// period. A null condition is not used.
  Future<StatementListDTO> execute({
    DateTime? from,
    DateTime? to,
    int? vehicleNumber,
    String? cardNumberSuffix,
  }) async {
    final all = await statementLines.findAll();
    final divisions = await vehicleTypes.findAll();
    final lookup = IcLookup(
      points: await icMaster.findAll(),
      mappings: await icMappings.findAll(),
      positions: await icPositions.findAll(),
    );

    final sorted = filterStatementLines(
      all,
      from: from,
      to: to,
      vehicleNumber: vehicleNumber,
      cardNumberSuffix: cardNumberSuffix,
    );

    return StatementListDTO(
      lines: [
        for (final line in sorted) toStatementLineDTO(line, lookup, divisions),
      ],
      totalFare: sorted.fold(0, (sum, l) => sum + l.fare),
      totalFareAfterRebate: sorted.fold(0, (sum, l) => sum + l.fareAfterRebate),
      totalPostpaidFare: sorted.fold(0, (sum, l) => sum + l.postpaidFare),
      vehicleNumberChoices: vehicleNumberChoicesOf(all),
      cardNumberChoices: cardNumberChoicesOf(all),
    );
  }
}
