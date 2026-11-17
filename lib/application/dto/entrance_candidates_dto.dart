/// The choices for the entrance IC of a statement line. Design: PRC-020.
class EntranceCandidatesDTO {
  const EntranceCandidatesDTO({required this.used, required this.sameRoute});

  /// The entrance ICs the user has used, the ones used with the same exit
  /// first.
  final List<EntranceCandidateDTO> used;

  /// The ICs on the routes of the exit, the nearest to the exit first.
  final List<EntranceCandidateDTO> sameRoute;
}

/// One choice for the entrance IC.
class EntranceCandidateDTO {
  const EntranceCandidateDTO({
    required this.icName,
    required this.routeNames,
    required this.uses,
  });

  final String icName;

  /// Empty when the routes are not known.
  final List<String> routeNames;

  /// How many times it was the entrance of a line with the same exit. 0 for an
  /// IC of the same route that has not been used.
  final int uses;
}
