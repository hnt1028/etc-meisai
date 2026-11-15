import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('codes are 1 to 5 in order', () {
    expect(VehicleTypeValue.values.map((v) => v.code), [1, 2, 3, 4, 5]);
  });

  test('fromCode finds each vehicle type', () {
    for (final type in VehicleTypeValue.values) {
      expect(VehicleTypeValue.fromCode(type.code), type);
    }
  });

  test('fromCode returns null for an unknown number', () {
    expect(VehicleTypeValue.fromCode(0), isNull);
    expect(VehicleTypeValue.fromCode(6), isNull);
  });

  test('labels are the Japanese names of the service table', () {
    expect(VehicleTypeValue.values.map((v) => v.label), [
      '普通車',
      '大型車',
      '特大車',
      '中型車',
      '軽自動車等',
    ]);
  });
}
