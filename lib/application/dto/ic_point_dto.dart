import 'package:etc_meisai/domain/value/ic_kind_value.dart';

/// An IC point shown to the user. Design: PRC-005, PRC-006.
class IcPointDTO {
  const IcPointDTO({
    required this.id,
    required this.name,
    required this.kind,
    required this.latitude,
    required this.longitude,
    required this.routeNames,
  });

  final String id;
  final String name;
  final IcKindValue kind;
  final double latitude;
  final double longitude;
  final List<String> routeNames;
}
