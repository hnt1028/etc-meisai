/// What the route map can show. The user turns each on or off
/// (docs/route-map.md, "ルートマップの表示").
enum RouteMapLayerValue {
  /// Every road, as thin light gray lines.
  network('network', true),

  /// The names of the roads of [network].
  networkNames('networkNames', false),

  /// The roads the user drove (the lines of the statement lines).
  traveled('traveled', true),

  /// The marks and names of the ICs and toll gates.
  markers('markers', true),

  /// The lines of statement lines that are still pending.
  pending('pending', true),

  /// Draws a road that was driven often with a thicker line.
  scaleByCount('scaleByCount', false);

  const RouteMapLayerValue(this.code, this.defaultVisible);

  /// What the database and the backup file store.
  final String code;

  /// Whether it is shown while the user has not chosen.
  final bool defaultVisible;

  /// Returns null when [code] is not a layer.
  static RouteMapLayerValue? fromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
