/// How many of the ICs of one road the user has passed. Design: PRC-013.
class RouteCoverageRowDTO {
  const RouteCoverageRowDTO({
    required this.routeName,
    required this.totalCount,
    required this.drivenCount,
  });

  final String routeName;

  /// How many ICs the road has in the IC master (general ICs, smart ICs and
  /// junctions, counted by name).
  final int totalCount;

  /// How many of them the user has passed, the entrance and the exit of a line
  /// and the ICs between them included. Each IC counts once, however often it
  /// was passed.
  final int drivenCount;
}
