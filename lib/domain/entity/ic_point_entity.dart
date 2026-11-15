import 'package:etc_meisai/domain/value/ic_kind_value.dart';

/// One point of the IC master: an interchange, a junction, a parking area...
class IcPointEntity {
  const IcPointEntity({
    required this.id,
    required this.name,
    required this.kind,
    required this.latitude,
    required this.longitude,
    required this.routeNames,
  });

  /// The id of the IC master (the relation id of N06). It stays the same for
  /// the same point when the master is made again.
  final String id;

  final String name;
  final IcKindValue kind;
  final double latitude;
  final double longitude;

  /// The routes that run through this point.
  final List<String> routeNames;
}
