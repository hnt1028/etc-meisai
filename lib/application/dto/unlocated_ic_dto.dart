/// An IC name whose position is not known. Design: PRC-009.
class UnlocatedIcDTO {
  const UnlocatedIcDTO({required this.icName, required this.lineCount});

  final String icName;

  /// How many statement lines have this IC name.
  final int lineCount;
}
