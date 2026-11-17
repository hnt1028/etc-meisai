import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/entity/operator_color_entity.dart';
import 'package:etc_meisai/domain/entity/statement_line_record_entity.dart';

/// Everything the app stores on the device: the data of the backup
/// (docs/backup-format.md).
class AppDataEntity {
  const AppDataEntity({
    required this.statementLines,
    required this.icMappings,
    required this.icPositions,
    required this.operatorColors,
  });

  final List<StatementLineRecordEntity> statementLines;
  final List<IcMappingEntity> icMappings;
  final List<IcPositionEntity> icPositions;
  final List<OperatorColorEntity> operatorColors;
}
