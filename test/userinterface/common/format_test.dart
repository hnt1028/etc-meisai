import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatYen', () {
    test('adds a thousands separator', () {
      expect(formatYen(0), '0円');
      expect(formatYen(960), '960円');
      expect(formatYen(1234), '1,234円');
      expect(formatYen(1234567), '1,234,567円');
    });

    test('keeps the sign of a negative amount', () {
      expect(formatYen(-240), '-240円');
      expect(formatYen(-1240), '-1,240円');
    });
  });

  group('formatKm', () {
    test('shows kilometers with one decimal place', () {
      expect(formatKm(0), '0.0km');
      expect(formatKm(3000), '3.0km');
      expect(formatKm(12345), '12.3km');
    });

    test('rounds to the nearest tenth, half up', () {
      expect(formatKm(49), '0.0km');
      expect(formatKm(50), '0.1km');
      expect(formatKm(149), '0.1km');
      expect(formatKm(9950), '10.0km');
    });

    test('adds a thousands separator', () {
      expect(formatKm(999900), '999.9km');
      expect(formatKm(1234500), '1,234.5km');
    });
  });

  test('formatDate pads the month and the day', () {
    expect(formatDate(DateTime(2026, 1, 5)), '2026/01/05');
  });

  test('formatDateTime pads the hour and the minute', () {
    expect(formatDateTime(DateTime(2026, 1, 10, 8, 5)), '2026/01/10 08:05');
  });
}
