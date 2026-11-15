import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:jis0208/jis0208.dart';

import 'package:etc_meisai/application/interface/statement_if.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';

/// Reads a usage statement CSV (CP932) into statement lines.
///
/// Rules are in docs/csv-format.md. Error messages are shown to the user,
/// so they are kept together in [_Messages].
class StatementRepo implements StatementIF {
  const StatementRepo();

  static const _headers = [
    '利用年月日（自）',
    '時分（自）',
    '利用年月日（至）',
    '時分（至）',
    '利用ＩＣ（自）',
    '利用ＩＣ（至）',
    '割引前料金',
    'ＥＴＣ割引額',
    '通行料金',
    '還元額適用料金',
    '後納料金',
    '車種',
    '車両番号',
    'ＥＴＣカード番号',
    '備考',
  ];

  static const _statusConfirmed = '確定';
  static const _statusPending = '確認中';

  @override
  List<StatementLineEntity> parse(Uint8List bytes) {
    final rows = _decode(bytes);
    if (rows.isEmpty) throw FormatException(_Messages.empty);

    _checkHeader(rows.first);

    final statementLines = <StatementLineEntity>[];
    for (var i = 1; i < rows.length; i++) {
      // Line 1 is the header, so the first data row is line 2.
      statementLines.add(_parseRow(rows[i], i + 1));
    }
    return statementLines;
  }

  List<List<String>> _decode(Uint8List bytes) {
    final String text;
    try {
      text = Windows31JDecoder().convert(bytes);
    } on FormatException {
      throw FormatException(_Messages.encoding);
    }
    final decoded = Csv(autoDetect: false).decode(text);
    return [
      for (final row in decoded) [for (final field in row) '$field'.trim()],
    ];
  }

  void _checkHeader(List<String> header) {
    if (header.length != _headers.length) {
      throw FormatException(_Messages.headerColumnCount(header.length));
    }
    for (var i = 0; i < _headers.length; i++) {
      if (header[i] != _headers[i]) {
        throw FormatException(
          _Messages.headerName(i + 1, _headers[i], header[i]),
        );
      }
    }
  }

  StatementLineEntity _parseRow(List<String> row, int line) {
    if (row.length != _headers.length) {
      throw FormatException(_Messages.rowColumnCount(line, row.length));
    }

    final entranceAt = _parseOptionalDateTime(row[0], row[1], line);
    final exitAt = _parseDateTime(row[2], row[3], _headers[2], line);

    final entranceIc = row[4].isEmpty ? null : row[4];
    final exitIc = _required(row[5], _headers[5], line);

    final (status, discountTypes) = _parseNote(row[14], line);

    return StatementLineEntity(
      entranceAt: entranceAt,
      exitAt: exitAt,
      entranceIc: entranceIc,
      exitIc: exitIc,
      grossFare: _parseOptionalAmount(row[6], _headers[6], line),
      etcDiscount: _parseOptionalAmount(row[7], _headers[7], line),
      fare: _parseAmount(row[8], _headers[8], line),
      fareAfterRebate: _parseAmount(row[9], _headers[9], line),
      postpaidFare: _parseAmount(row[10], _headers[10], line),
      vehicleType: _parseVehicleType(row[11], line),
      vehicleNumber: _parseVehicleNumber(row[12], line),
      cardNumber: _required(row[13], _headers[13], line),
      status: status,
      discountTypes: discountTypes,
    );
  }

  VehicleTypeValue _parseVehicleType(String value, int line) {
    final vehicleType = VehicleTypeValue.fromCode(int.tryParse(value) ?? -1);
    if (vehicleType == null) {
      throw FormatException(_Messages.vehicleType(line, value));
    }
    return vehicleType;
  }

  /// The error never includes the value: a vehicle number is personal data.
  int _parseVehicleNumber(String value, int line) {
    final number = int.tryParse(value);
    if (number == null) {
      throw FormatException(_Messages.vehicleNumber(line));
    }
    return number;
  }

  String _required(String value, String column, int line) {
    if (value.isEmpty) throw FormatException(_Messages.blank(line, column));
    return value;
  }

  /// Both the date and the time are blank, or both are filled.
  DateTime? _parseOptionalDateTime(String date, String time, int line) {
    if (date.isEmpty && time.isEmpty) return null;
    return _parseDateTime(date, time, _headers[0], line);
  }

  DateTime _parseDateTime(String date, String time, String column, int line) {
    final d = RegExp(r'^(\d{2})/(\d{2})/(\d{2})$').firstMatch(date);
    final t = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time);
    if (d == null || t == null) {
      throw FormatException(_Messages.dateTime(line, column, date, time));
    }
    final year = 2000 + int.parse(d.group(1)!);
    final month = int.parse(d.group(2)!);
    final day = int.parse(d.group(3)!);
    final hour = int.parse(t.group(1)!);
    final minute = int.parse(t.group(2)!);
    final result = DateTime(year, month, day, hour, minute);
    final valid =
        result.year == year &&
        result.month == month &&
        result.day == day &&
        hour < 24 &&
        minute < 60;
    if (!valid) {
      throw FormatException(_Messages.dateTime(line, column, date, time));
    }
    return result;
  }

  int? _parseOptionalAmount(String value, String column, int line) {
    if (value.isEmpty) return null;
    return _parseAmount(value, column, line);
  }

  int _parseAmount(String value, String column, int line) {
    if (value.isEmpty) throw FormatException(_Messages.blank(line, column));
    final amount = int.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      throw FormatException(_Messages.amount(line, column, value));
    }
    return amount;
  }

  (ConfirmationStatusValue, List<String>) _parseNote(String note, int line) {
    final parts = [
      for (final part in note.split(';'))
        if (part.trim().isNotEmpty) part.trim(),
    ];
    final confirmed = parts.contains(_statusConfirmed);
    final pending = parts.contains(_statusPending);
    if (confirmed == pending) {
      throw FormatException(_Messages.status(line));
    }
    final discountTypes = [
      for (final part in parts)
        if (part != _statusConfirmed && part != _statusPending) part,
    ];
    return (
      confirmed
          ? ConfirmationStatusValue.confirmed
          : ConfirmationStatusValue.pending,
      discountTypes,
    );
  }
}

/// Error messages for an invalid CSV. They never include the cell values of
/// personal information (vehicle number, card number).
class _Messages {
  static const empty = 'CSVが空です';
  static const encoding = '文字コードがCP932（Shift_JIS）として読み取れません';

  static String headerColumnCount(int actual) =>
      'ヘッダーの列数が15ではありません（実際: $actual）';

  static String headerName(int column, String expected, String actual) =>
      'ヘッダーの$column列目が「$expected」ではありません（実際: 「$actual」）';

  static String rowColumnCount(int line, int actual) =>
      '$line行目: 列数が15ではありません（実際: $actual）';

  static String blank(int line, String column) => '$line行目: 「$column」が空です';

  static String dateTime(int line, String column, String date, String time) =>
      '$line行目: 「$column」の日時が不正です（日付: $date、時刻: $time）';

  static String amount(int line, String column, String value) =>
      '$line行目: 「$column」が金額として読み取れません（$value）';

  static String vehicleType(int line, String value) =>
      '$line行目: 「車種」が1〜5の番号ではありません（$value）';

  static String vehicleNumber(int line) => '$line行目: 「車両番号」が数字ではありません';

  static String status(int line) => '$line行目: 「備考」に「確定」か「確認中」のどちらか一方が必要です';
}
