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

  test('formatDate pads the month and the day', () {
    expect(formatDate(DateTime(2026, 1, 5)), '2026/01/05');
  });

  test('formatDateTime pads the hour and the minute', () {
    expect(formatDateTime(DateTime(2026, 1, 10, 8, 5)), '2026/01/10 08:05');
  });
}
