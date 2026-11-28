import 'package:etc_meisai/application/dto/ic_match_dto.dart';

/// What the IC mapping screen shows. Design: PRC-005.
class IcMatchListDTO {
  const IcMatchListDTO({required this.unresolved, required this.registered});

  /// IC names that need a choice, the most used first.
  final List<IcMatchDTO> unresolved;

  /// The mappings the user registered, in the order of the IC name.
  final List<IcMatchDTO> registered;
}
