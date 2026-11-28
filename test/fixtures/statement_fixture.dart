import 'dart:typed_data';

import 'package:jis0208/jis0208.dart';

/// Fictional usage statement CSVs (CP932, like the real service output).
/// Never put a real CSV here (docs/privacy.md).
abstract final class StatementFixture {
  static const header = [
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

  /// A fictional row that goes to [exitIc] with the given note.
  static List<String> row({String exitIc = 'テスト南ＩＣ', String note = '確定'}) {
    return [
      '26/01/10',
      '08:30',
      '26/01/10',
      '09:15',
      'テスト北ＩＣ',
      exitIc,
      '1,200',
      '-240',
      '960',
      '0',
      '960',
      '1',
      '1234',
      '0000-****-0001',
      note,
    ];
  }

  /// Encodes [rows] as a CP932 CSV. A field with a comma is quoted.
  static Uint8List csv(List<List<String>> rows) {
    String field(String v) => v.contains(',') ? '"$v"' : v;
    final text = rows.map((r) => r.map(field).join(',')).join('\r\n');
    return Uint8List.fromList(Windows31JEncoder().convert('$text\r\n'));
  }

  /// Two confirmed rows and one pending row, each to another exit.
  static Uint8List threeRows() => csv([
    header,
    row(exitIc: 'テスト東ＩＣ'),
    row(exitIc: 'テスト西ＩＣ'),
    row(exitIc: 'テスト南ＩＣ', note: '確認中'),
  ]);

  /// The header is wrong, so the import must fail.
  static Uint8List brokenHeader() => csv([
    [...header]..[4] = '利用IC（自）',
    row(),
  ]);
}
