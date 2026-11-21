/// A number the user sets for the route map, with a slider
/// (docs/route-map.md, "ルートマップの表示").
enum RouteMapOptionValue {
  /// The width of the lines of the roads the user drove. The lines of the
  /// network are three quarters of it.
  lineWidth('lineWidth', 4, 2, 10);

  const RouteMapOptionValue(
    this.code,
    this.defaultValue,
    this.minimum,
    this.maximum,
  );

  /// What the database and the backup file store.
  final String code;

  /// The value while the user has not chosen.
  final int defaultValue;

  /// The smallest and the largest value the user can set.
  final int minimum;
  final int maximum;

  /// Returns null when [code] is not an option.
  static RouteMapOptionValue? fromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
