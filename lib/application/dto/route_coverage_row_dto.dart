/// How much of one road the user has driven. Design: PRC-013.
class RouteCoverageRowDTO {
  const RouteCoverageRowDTO({
    required this.routeName,
    required this.totalMeters,
    required this.drivenMeters,
  });

  final String routeName;

  /// The length of every section of the road in the IC master, in meters.
  final int totalMeters;

  /// The length of the sections the user has driven, in meters. Each section
  /// counts once, however often it was driven.
  final int drivenMeters;
}
