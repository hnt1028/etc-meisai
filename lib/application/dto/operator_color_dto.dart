/// The color of the lines of one road operator. Design: PRC-021.
class OperatorColorDTO {
  const OperatorColorDTO({
    required this.operatorName,
    required this.color,
    required this.isDefault,
  });

  final String operatorName;

  /// The color in use: an opaque ARGB number, `0xFFRRGGBB`.
  final int color;

  /// True when the user has not chosen a color: [color] is the default.
  final bool isDefault;
}
