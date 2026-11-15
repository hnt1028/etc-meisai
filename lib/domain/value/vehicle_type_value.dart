/// The vehicle type of the "車種" column.
///
/// The CSV holds a number from 1 to 5. The names follow the table of the ETC
/// usage inquiry service for the vehicle type division 1 of NEXCO roads. Some
/// other road operators use other names for the same number, but the CSV does
/// not say which operator a line belongs to, so this one table is used.
/// Source: https://www.etc-meisai.jp/soukou_meisai_exp.html
enum VehicleTypeValue {
  standard(1, '普通車'),
  large(2, '大型車'),
  extraLarge(3, '特大車'),
  medium(4, '中型車'),
  light(5, '軽自動車等');

  const VehicleTypeValue(this.code, this.label);

  /// The number in the CSV. It is also what the database stores.
  final int code;

  /// The Japanese name shown to the user.
  final String label;

  /// Returns null when [code] is not a vehicle type number.
  static VehicleTypeValue? fromCode(int code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
