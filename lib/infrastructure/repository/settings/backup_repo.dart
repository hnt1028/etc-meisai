import 'dart:convert';
import 'dart:typed_data';

import 'package:etc_meisai/application/interface/backup_if.dart';
import 'package:etc_meisai/domain/entity/app_data_entity.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/entity/statement_line_record_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';

/// The file format of the backup: JSON, as in docs/backup-format.md. The error
/// messages are shown to the user, so they are kept together in [_Messages];
/// they never include a value of the file (it can be personal data).
class BackupRepo implements BackupIF {
  const BackupRepo();

  static const _format = 'etc-meisai-backup';

  /// The version this app writes, and the newest one it reads.
  static const version = 1;

  @override
  Uint8List encode(AppDataEntity data, DateTime exportedAt) {
    final json = <String, Object?>{
      'format': _format,
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'statementLines': [
        for (final l in data.statementLines)
          <String, Object?>{
            'id': l.id,
            'duplicateKey': l.duplicateKey,
            'entranceAt': l.entranceAt?.toIso8601String(),
            'exitAt': l.exitAt.toIso8601String(),
            'entranceIc': l.entranceIc,
            'exitIc': l.exitIc,
            'grossFare': l.grossFare,
            'etcDiscount': l.etcDiscount,
            'fare': l.fare,
            'fareAfterRebate': l.fareAfterRebate,
            'postpaidFare': l.postpaidFare,
            'vehicleType': l.vehicleType.code,
            'vehicleNumber': l.vehicleNumber,
            'enteredEntranceAt': l.enteredEntranceAt?.toIso8601String(),
            'enteredEntranceIc': l.enteredEntranceIc,
            'cardNumber': l.cardNumber,
            'status': l.status.name,
            'discountTypes': l.discountTypes,
          },
      ],
      'icMappings': [
        for (final m in data.icMappings)
          <String, Object?>{'icName': m.icName, 'pointId': m.pointId},
      ],
      'icPositions': [
        for (final p in data.icPositions)
          <String, Object?>{
            'icName': p.icName,
            'latitude': p.latitude,
            'longitude': p.longitude,
          },
      ],
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(json)));
  }

  @override
  AppDataEntity decode(Uint8List bytes) {
    final Object? root;
    try {
      root = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      // The error of the parser would quote the file, so it is not passed on.
      throw FormatException(_Messages.notBackup);
    }
    if (root is! Map<String, Object?> || root['format'] != _format) {
      throw FormatException(_Messages.notBackup);
    }
    final fileVersion = root['version'];
    if (fileVersion is! int || fileVersion < 1) {
      throw FormatException(_Messages.notBackup);
    }
    if (fileVersion > version) throw FormatException(_Messages.tooNew);

    final lines = [
      for (final (i, item) in _list(root, 'statementLines').indexed)
        _line(_Row(item, _Messages.line, i + 1)),
    ];
    final mappings = [
      for (final (i, item) in _list(root, 'icMappings').indexed)
        _mapping(_Row(item, _Messages.mapping, i + 1)),
    ];
    final positions = [
      for (final (i, item) in _list(root, 'icPositions').indexed)
        _position(_Row(item, _Messages.position, i + 1)),
    ];

    _checkUnique(lines.map((l) => l.id), _Messages.line, 'id');
    _checkUnique(
      lines.map((l) => l.duplicateKey),
      _Messages.line,
      'duplicateKey',
    );
    _checkUnique(mappings.map((m) => m.icName), _Messages.mapping, 'icName');
    _checkUnique(positions.map((p) => p.icName), _Messages.position, 'icName');

    return AppDataEntity(
      statementLines: lines,
      icMappings: mappings,
      icPositions: positions,
    );
  }

  List<Object?> _list(Map<String, Object?> root, String key) {
    final value = root[key];
    if (value is! List) throw FormatException(_Messages.missing(key));
    return value;
  }

  StatementLineRecordEntity _line(_Row row) {
    final vehicleType = VehicleTypeValue.fromCode(row.integer('vehicleType'));
    if (vehicleType == null) throw row.wrong('vehicleType');
    final status = ConfirmationStatusValue.values
        .where((s) => s.name == row.text('status'))
        .firstOrNull;
    if (status == null) throw row.wrong('status');
    return StatementLineRecordEntity(
      id: row.text('id'),
      duplicateKey: row.text('duplicateKey'),
      entranceAt: row.optionalTime('entranceAt'),
      exitAt: row.time('exitAt'),
      entranceIc: row.optionalText('entranceIc'),
      exitIc: row.text('exitIc'),
      grossFare: row.optionalInteger('grossFare'),
      etcDiscount: row.optionalInteger('etcDiscount'),
      fare: row.integer('fare'),
      fareAfterRebate: row.integer('fareAfterRebate'),
      postpaidFare: row.integer('postpaidFare'),
      vehicleType: vehicleType,
      vehicleNumber: row.optionalInteger('vehicleNumber'),
      enteredEntranceAt: row.optionalTime('enteredEntranceAt'),
      enteredEntranceIc: row.optionalText('enteredEntranceIc'),
      cardNumber: row.text('cardNumber'),
      status: status,
      discountTypes: row.textList('discountTypes'),
    );
  }

  IcMappingEntity _mapping(_Row row) =>
      IcMappingEntity(icName: row.text('icName'), pointId: row.text('pointId'));

  IcPositionEntity _position(_Row row) {
    final latitude = row.real('latitude');
    final longitude = row.real('longitude');
    if (latitude < -90 || latitude > 90) throw row.wrong('latitude');
    if (longitude < -180 || longitude > 180) throw row.wrong('longitude');
    return IcPositionEntity(
      icName: row.text('icName'),
      latitude: latitude,
      longitude: longitude,
    );
  }

  void _checkUnique(Iterable<String> values, String what, String key) {
    final seen = <String>{};
    for (final value in values) {
      if (!seen.add(value)) {
        throw FormatException(_Messages.duplicated(what, key));
      }
    }
  }
}

/// One item of the file, read by column. A wrong column throws a
/// [FormatException] that names the item and the column, not the value.
class _Row {
  _Row(Object? item, this.what, this.number)
    : _map = item is Map<String, Object?> ? item : null {
    if (_map == null) throw FormatException(_Messages.notAnItem(what, number));
  }

  final Map<String, Object?>? _map;
  final String what;
  final int number;

  FormatException wrong(String key) =>
      FormatException(_Messages.wrong(what, number, key));

  Object? _value(String key) => _map![key];

  String text(String key) {
    final value = _value(key);
    if (value is! String) throw wrong(key);
    return value;
  }

  String? optionalText(String key) => _value(key) == null ? null : text(key);

  int integer(String key) {
    final value = _value(key);
    if (value is! int) throw wrong(key);
    return value;
  }

  int? optionalInteger(String key) => _value(key) == null ? null : integer(key);

  double real(String key) {
    final value = _value(key);
    if (value is! num) throw wrong(key);
    return value.toDouble();
  }

  DateTime time(String key) {
    final value = DateTime.tryParse(text(key));
    if (value == null) throw wrong(key);
    return value;
  }

  DateTime? optionalTime(String key) => _value(key) == null ? null : time(key);

  List<String> textList(String key) {
    final value = _value(key);
    if (value is! List || value.any((e) => e is! String)) throw wrong(key);
    return List<String>.unmodifiable(value.cast<String>());
  }
}

class _Messages {
  static const line = '明細行';
  static const mapping = 'ICの対応づけ';
  static const position = 'ICの位置の指定';

  static const notBackup = 'このアプリのバックアップのファイルではありません';
  static const tooNew = '新しい版のアプリで書き出したファイルです。このアプリでは読み込めません';

  static String missing(String key) => '「$key」がありません';
  static String notAnItem(String what, int number) =>
      '$what の$number件目が、正しい形ではありません';
  static String wrong(String what, int number, String key) =>
      '$what の$number件目: 「$key」が正しくありません';
  static String duplicated(String what, String key) => '$what の「$key」が重複しています';
}
