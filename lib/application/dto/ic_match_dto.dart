import 'package:etc_meisai/application/dto/ic_point_dto.dart';
import 'package:etc_meisai/domain/value/ic_match_value.dart';

/// One IC name of the CSV and how it matches the IC master. Design: PRC-005.
class IcMatchDTO {
  const IcMatchDTO({
    required this.icName,
    required this.state,
    required this.lineCount,
    this.candidates = const [],
    this.point,
  });

  final String icName;

  /// [IcMatchValue.ambiguous] or [IcMatchValue.unknown] for an IC name that
  /// needs a choice, [IcMatchValue.registered] for a registered mapping.
  final IcMatchValue state;

  /// How many statement lines have this IC name.
  final int lineCount;

  /// The points that fit the name, when [state] is ambiguous.
  final List<IcPointDTO> candidates;

  /// The registered point. Null when the point is not in the IC master any more.
  final IcPointDTO? point;
}
