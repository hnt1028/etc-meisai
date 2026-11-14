/// The result of importing a usage statement CSV, shown on the settings screen.
class ImportResultDTO {
  const ImportResultDTO({
    required this.addedCount,
    required this.overwrittenCount,
    required this.ignoredCount,
  });

  /// Trips that were not stored yet and are now stored.
  final int addedCount;

  /// Pending trips that were replaced by the incoming rows.
  final int overwrittenCount;

  /// Rows left out because a confirmed trip is already stored.
  final int ignoredCount;
}
