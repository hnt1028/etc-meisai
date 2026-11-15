/// The result of importing a usage statement CSV, shown on the settings screen.
class ImportResultDTO {
  const ImportResultDTO({
    required this.addedCount,
    required this.overwrittenCount,
    required this.ignoredCount,
  });

  /// Statement lines that were not stored yet and are now stored.
  final int addedCount;

  /// Pending statement lines that were replaced by the incoming rows.
  final int overwrittenCount;

  /// Rows left out because a confirmed statement line is already stored.
  final int ignoredCount;
}
