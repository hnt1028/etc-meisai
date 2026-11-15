/// Shows [yen] with a thousands separator, such as 1,234円.
String formatYen(int yen) {
  final digits = yen.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${yen < 0 ? '-' : ''}$buffer円';
}

String _two(int value) => value.toString().padLeft(2, '0');

/// Shows a date as 2026/01/10.
String formatDate(DateTime value) =>
    '${value.year}/${_two(value.month)}/${_two(value.day)}';

/// Shows a date and time as 2026/01/10 08:30.
String formatDateTime(DateTime value) =>
    '${formatDate(value)} ${_two(value.hour)}:${_two(value.minute)}';
