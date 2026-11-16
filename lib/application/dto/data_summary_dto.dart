/// How many of each kind of data there are. Design: PRC-017, PRC-018.
class DataSummaryDTO {
  const DataSummaryDTO({
    required this.lineCount,
    required this.mappingCount,
    required this.positionCount,
  });

  /// The statement lines.
  final int lineCount;

  /// The IC mappings.
  final int mappingCount;

  /// The IC positions.
  final int positionCount;
}
