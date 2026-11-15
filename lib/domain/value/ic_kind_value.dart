/// The kind of an IC point of the IC master (N06 "接合部種別").
enum IcKindValue {
  generalInterchange(1, '一般IC'),
  smartInterchange(2, 'スマートIC'),
  junction(3, 'JCT'),
  other(4, 'その他');

  const IcKindValue(this.code, this.label);

  /// The number in the IC master.
  final int code;

  /// The Japanese name shown to the user.
  final String label;

  /// Returns [other] when [code] is not a known number.
  static IcKindValue fromCode(int code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return other;
  }
}
