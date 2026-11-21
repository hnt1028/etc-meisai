import 'dart:convert';
import 'dart:typed_data';

import 'package:etc_meisai/domain/entity/route_map_layer_entity.dart';
import 'package:etc_meisai/domain/entity/app_data_entity.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/entity/operator_color_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/infrastructure/repository/settings/backup_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

AppDataEntity _data() => AppDataEntity(
  statementLines: [
    fakeRecord(
      id: 'id-1',
      duplicateKey: 'k-1',
      entranceAt: DateTime(2026, 1, 10, 8, 30),
      discountTypes: const ['深夜割引', '休日割引'],
    ),
    // Blank in the CSV, and entered by the user.
    fakeRecord(
      id: 'id-2',
      duplicateKey: 'k-2',
      entranceAt: null,
      entranceIc: null,
      vehicleNumber: null,
      enteredEntranceAt: DateTime(2026, 1, 11, 7, 5),
      enteredEntranceIc: '入力した',
      status: ConfirmationStatusValue.pending,
    ),
  ],
  icMappings: const [IcMappingEntity(icName: '北', pointId: 'p-1')],
  icPositions: const [
    IcPositionEntity(icName: '東', latitude: 35.123456, longitude: 139.654321),
  ],
  operatorColors: const [
    OperatorColorEntity(operatorName: 'NEXCO東日本', color: 0xFF112233),
    OperatorColorEntity(operatorName: '首都高速道路', color: 0xFFFFFFFF),
  ],
  routeMapLayers: const [
    RouteMapLayerEntity(layerCode: 'network', visible: false),
    RouteMapLayerEntity(layerCode: 'markers', visible: true),
  ],
);

/// A valid file as a map, for a test to break in one place.
Map<String, Object?> _file({
  List<Object?>? lines,
  List<Object?>? mappings,
  List<Object?>? positions,
  Object? colors,
  Object? layers,
}) => {
  'format': 'etc-meisai-backup',
  'version': 1,
  'exportedAt': '2026-11-16T12:00:00.000',
  'statementLines': lines ?? [],
  'icMappings': mappings ?? [],
  'icPositions': positions ?? [],
  'operatorColors': ?colors,
  'routeMapLayers': ?layers,
};

Map<String, Object?> _line([Map<String, Object?>? changes]) => {
  'id': 'id-1',
  'duplicateKey': 'k-1',
  'entranceAt': '2026-01-10T08:30:00.000',
  'exitAt': '2026-01-10T09:15:00.000',
  'entranceIc': 'A',
  'exitIc': 'B',
  'grossFare': null,
  'etcDiscount': null,
  'fare': 100,
  'fareAfterRebate': 0,
  'postpaidFare': 100,
  'vehicleType': 1,
  'vehicleNumber': 1234,
  'enteredEntranceAt': null,
  'enteredEntranceIc': null,
  'cardNumber': 'c',
  'status': 'confirmed',
  'discountTypes': <String>[],
  ...?changes,
};

Uint8List _bytes(Object? json) =>
    Uint8List.fromList(utf8.encode(jsonEncode(json)));

FormatException _decodeError(Object? json) {
  try {
    const BackupRepo().decode(_bytes(json));
  } on FormatException catch (e) {
    return e;
  }
  fail('should have thrown');
}

void main() {
  // Not const, so that the constructor runs (and is counted by coverage).
  // ignore: prefer_const_constructors
  final repo = BackupRepo();

  group('a round trip', () {
    test('gives back what was written, field by field', () {
      final back = repo.decode(repo.encode(_data(), DateTime(2026, 11, 16)));

      expect(back.statementLines, hasLength(2));
      final a = back.statementLines[0], b = back.statementLines[1];
      expect(a.id, 'id-1');
      expect(a.duplicateKey, 'k-1');
      expect(a.entranceAt, DateTime(2026, 1, 10, 8, 30));
      expect(a.exitAt, DateTime(2026, 1, 10, 9, 15));
      expect(a.entranceIc, 'A-IC');
      expect(a.exitIc, 'B-IC');
      expect(a.grossFare, isNull);
      expect(a.etcDiscount, isNull);
      expect(a.fare, 1000);
      expect(a.fareAfterRebate, 0);
      expect(a.postpaidFare, 1000);
      expect(a.vehicleType, VehicleTypeValue.standard);
      expect(a.vehicleNumber, 1234);
      expect(a.cardNumber, '0000-****-0001');
      expect(a.status, ConfirmationStatusValue.confirmed);
      expect(a.discountTypes, ['深夜割引', '休日割引']);
      // The CSV's values and the user's stay apart.
      expect(b.entranceAt, isNull);
      expect(b.entranceIc, isNull);
      expect(b.vehicleNumber, isNull);
      expect(b.enteredEntranceAt, DateTime(2026, 1, 11, 7, 5));
      expect(b.enteredEntranceIc, '入力した');
      expect(b.status, ConfirmationStatusValue.pending);
      expect(back.icMappings.single.icName, '北');
      expect(back.icMappings.single.pointId, 'p-1');
      expect(back.icPositions.single.latitude, 35.123456);
      expect(back.icPositions.single.longitude, 139.654321);
      expect(back.operatorColors.map((c) => (c.operatorName, c.color)), [
        ('NEXCO東日本', 0xFF112233),
        ('首都高速道路', 0xFFFFFFFF),
      ]);
    });

    test('keeps amounts, with the sign of a discount', () {
      final data = AppDataEntity(
        statementLines: [fakeRecord()],
        icMappings: const [],
        icPositions: const [],
        operatorColors: const [],
        routeMapLayers: const [],
      );

      final line = repo
          .decode(repo.encode(data, DateTime.now()))
          .statementLines
          .single;

      expect(line.fare, 1000);
      final withDiscount = repo.decode(
        _bytes(
          _file(
            lines: [
              _line({'etcDiscount': -240, 'grossFare': 1240}),
            ],
          ),
        ),
      );
      expect(withDiscount.statementLines.single.etcDiscount, -240);
      expect(withDiscount.statementLines.single.grossFare, 1240);
    });

    test('gives back nothing for no data', () {
      final back = repo.decode(
        repo.encode(
          const AppDataEntity(
            statementLines: [],
            icMappings: [],
            icPositions: [],
            operatorColors: [],
            routeMapLayers: [],
          ),
          DateTime.now(),
        ),
      );

      expect(back.statementLines, isEmpty);
      expect(back.icMappings, isEmpty);
      expect(back.icPositions, isEmpty);
    });

    test('writes the format, the version and the time, in UTF-8 JSON', () {
      final text = utf8.decode(
        repo.encode(_data(), DateTime(2026, 11, 16, 12, 34, 56)),
      );
      final json = jsonDecode(text) as Map<String, Object?>;

      expect(json['format'], 'etc-meisai-backup');
      expect(json['version'], 1);
      expect(json['exportedAt'], '2026-11-16T12:34:56.000');
      // Japanese is written as it is.
      expect(text, contains('深夜割引'));
    });
  });

  group('decode: the file', () {
    test('accepts a minimal file', () {
      expect(repo.decode(_bytes(_file())).statementLines, isEmpty);
    });

    test('rejects what is not JSON, and what is not UTF-8', () {
      expect(
        () => repo.decode(Uint8List.fromList(utf8.encode('not json'))),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => repo.decode(Uint8List.fromList([0xff, 0xfe, 0xfd])),
        throwsA(isA<FormatException>()),
      );
      expect(() => repo.decode(Uint8List(0)), throwsA(isA<FormatException>()));
    });

    test('rejects JSON that is not a backup', () {
      for (final json in <Object?>[
        [1, 2],
        'text',
        {'format': 'other', 'version': 1},
        {'version': 1},
        {'format': 'etc-meisai-backup'},
        {'format': 'etc-meisai-backup', 'version': '1'},
        {'format': 'etc-meisai-backup', 'version': 0},
      ]) {
        expect(
          _decodeError(json).message,
          contains('バックアップのファイルではありません'),
          reason: '$json',
        );
      }
    });

    test('rejects a file of a newer version', () {
      expect(
        _decodeError({..._file(), 'version': 2}).message,
        contains('新しい版'),
      );
    });

    test('rejects a file without one of the lists', () {
      for (final key in ['statementLines', 'icMappings', 'icPositions']) {
        final file = _file()..remove(key);

        expect(_decodeError(file).message, contains(key), reason: key);
      }
      expect(
        _decodeError({..._file(), 'icMappings': 'x'}).message,
        contains('icMappings'),
      );
    });
  });

  group('decode: the statement lines', () {
    test('names the item and the column that is wrong', () {
      final e = _decodeError(
        _file(
          lines: [
            _line(),
            _line({'id': 'id-2', 'duplicateKey': 'k-2', 'fare': 'x'}),
          ],
        ),
      );

      expect(e.message, '明細行 の2件目: 「fare」が正しくありません');
    });

    test('rejects a value of the wrong type in every column', () {
      const wrong = <String, Object?>{
        'id': 1,
        'duplicateKey': 1,
        'entranceAt': 1,
        'exitAt': 'yesterday',
        'entranceIc': 1,
        'exitIc': null,
        'grossFare': '1',
        'etcDiscount': 1.5,
        'fare': null,
        'fareAfterRebate': 'x',
        'postpaidFare': [],
        'vehicleType': 9,
        'vehicleNumber': 'x',
        'enteredEntranceAt': 'soon',
        'enteredEntranceIc': 1,
        'cardNumber': 1,
        'status': 'done',
        'discountTypes': 'x',
      };
      for (final entry in wrong.entries) {
        final e = _decodeError(
          _file(
            lines: [
              _line({entry.key: entry.value}),
            ],
          ),
        );

        expect(e.message, contains('「${entry.key}」'), reason: entry.key);
      }
      expect(
        _decodeError(
          _file(
            lines: [
              _line({
                'discountTypes': [1],
              }),
            ],
          ),
        ).message,
        contains('discountTypes'),
      );
    });

    test('reads a file without colors as having none', () {
      // A file written before the colors were added has no such list.
      expect(repo.decode(_bytes(_file())).operatorColors, isEmpty);
    });

    test('reads the colors as opaque, and rejects a wrong one', () {
      final ok = repo.decode(
        _bytes(
          _file(
            colors: [
              {'operatorName': 'NEXCO東日本', 'color': 0},
              {'operatorName': '首都高速道路', 'color': 0xFFFFFF},
            ],
          ),
        ),
      );
      expect(ok.operatorColors.map((c) => c.color), [0xFF000000, 0xFFFFFFFF]);

      for (final bad in [
        {'operatorName': 'a', 'color': -1},
        {'operatorName': 'a', 'color': 0x1000000},
        {'operatorName': 'a', 'color': '112233'},
        {'operatorName': 'a', 'color': null},
        {'operatorName': 5, 'color': 1},
      ]) {
        final error = _decodeError(_file(colors: [bad]));
        expect(error.message, contains('線の色'));
        expect(error.message, isNot(contains('112233')));
      }
      expect(
        _decodeError(_file(colors: 'x')).message,
        contains('operatorColors'),
      );
    });

    test('keeps the layers of the route map', () {
      final back = repo.decode(repo.encode(_data(), DateTime.now()));

      expect(back.routeMapLayers.map((l) => (l.layerCode, l.visible)), [
        ('network', false),
        ('markers', true),
      ]);
    });

    test('reads a file without layers as having none', () {
      expect(repo.decode(_bytes(_file())).routeMapLayers, isEmpty);
    });

    test('rejects a wrong layer, and the same layer twice', () {
      for (final bad in [
        {'layer': 'network', 'visible': 1},
        {'layer': 'network', 'visible': null},
        {'layer': 5, 'visible': true},
      ]) {
        final error = _decodeError(_file(layers: [bad]));
        expect(error.message, contains('地図の表示'));
      }
      expect(
        _decodeError(_file(layers: 'x')).message,
        contains('routeMapLayers'),
      );
      final twice = _decodeError(
        _file(
          layers: [
            {'layer': 'network', 'visible': true},
            {'layer': 'network', 'visible': false},
          ],
        ),
      );
      expect(twice.message, contains('layer'));
    });

    test('keeps the memo and the tags of a line', () {
      final data = AppDataEntity(
        statementLines: [
          fakeRecord(memo: '出張', tags: const ['仕事', '東京']),
        ],
        icMappings: const [],
        icPositions: const [],
        operatorColors: const [],
        routeMapLayers: const [],
      );

      final line = repo
          .decode(repo.encode(data, DateTime.now()))
          .statementLines
          .single;

      expect(line.memo, '出張');
      expect(line.tags, ['仕事', '東京']);
    });

    test('reads a line without a memo and tags as having none', () {
      // A file written before the notes were added.
      final line = repo.decode(_bytes(_file(lines: [_line()]))).statementLines;

      expect(line.single.memo, '');
      expect(line.single.tags, isEmpty);
    });

    test('rejects a wrong memo or tags', () {
      for (final bad in [
        {'memo': 5},
        {'memo': null},
        {'tags': 'x'},
        {
          'tags': [1],
        },
        {
          'tags': [''],
        },
        {
          'tags': ['a;b'],
        },
        {
          'tags': ['a\nb'],
        },
      ]) {
        final error = _decodeError(_file(lines: [_line(bad)]));
        expect(error.message, contains('明細行'));
      }
    });

    test('rejects the same operator twice', () {
      final error = _decodeError(
        _file(
          colors: [
            {'operatorName': 'a', 'color': 1},
            {'operatorName': 'a', 'color': 2},
          ],
        ),
      );

      expect(error.message, contains('operatorName'));
    });

    test('rejects an item that is not an object', () {
      expect(
        _decodeError(_file(lines: ['x'])).message,
        '明細行 の1件目が、正しい形ではありません',
      );
    });

    test('rejects the same id or duplicate key twice', () {
      final sameId = _decodeError(
        _file(
          lines: [
            _line(),
            _line({'duplicateKey': 'k-2'}),
          ],
        ),
      );
      expect(sameId.message, contains('「id」が重複'));
      final sameKey = _decodeError(
        _file(
          lines: [
            _line(),
            _line({'id': 'id-2'}),
          ],
        ),
      );
      expect(sameKey.message, contains('「duplicateKey」が重複'));
    });

    test('accepts the values the app can write', () {
      final back = repo.decode(
        _bytes(
          _file(
            lines: [
              _line({
                'status': 'pending',
                'vehicleType': 5,
                'discountTypes': ['深夜割引'],
              }),
            ],
          ),
        ),
      );

      final line = back.statementLines.single;
      expect(line.status, ConfirmationStatusValue.pending);
      expect(
        line.vehicleType,
        VehicleTypeValue.values.firstWhere((t) => t.code == 5),
      );
    });
  });

  group('decode: the mappings and the positions', () {
    test('reads them', () {
      final back = repo.decode(
        _bytes(
          _file(
            mappings: [
              {'icName': '甲', 'pointId': 'p'},
            ],
            positions: [
              {'icName': '乙', 'latitude': 36, 'longitude': 140},
            ],
          ),
        ),
      );

      expect(back.icMappings.single.pointId, 'p');
      // An integer is read as a number.
      expect(back.icPositions.single.latitude, 36.0);
    });

    test('rejects a wrong type, and a name used twice', () {
      expect(
        _decodeError(
          _file(
            mappings: [
              {'icName': '甲', 'pointId': 1},
            ],
          ),
        ).message,
        'ICの対応づけ の1件目: 「pointId」が正しくありません',
      );
      expect(
        _decodeError(
          _file(
            mappings: [
              {'icName': '甲', 'pointId': 'a'},
              {'icName': '甲', 'pointId': 'b'},
            ],
          ),
        ).message,
        'ICの対応づけ の「icName」が重複しています',
      );
      expect(
        _decodeError(
          _file(
            positions: [
              {'icName': '甲', 'latitude': 1, 'longitude': 1},
              {'icName': '甲', 'latitude': 2, 'longitude': 2},
            ],
          ),
        ).message,
        'ICの位置の指定 の「icName」が重複しています',
      );
    });

    test('rejects a position out of range', () {
      for (final (lat, lon) in [(90.5, 0), (-91, 0), (0, 181), (0, -180.5)]) {
        final e = _decodeError(
          _file(
            positions: [
              {'icName': 'x', 'latitude': lat, 'longitude': lon},
            ],
          ),
        );

        expect(e.message, contains('ICの位置の指定'), reason: '$lat,$lon');
      }
      expect(
        _decodeError(
          _file(
            positions: [
              {'icName': 'x', 'latitude': 'a', 'longitude': 1},
            ],
          ),
        ).message,
        contains('latitude'),
      );
    });

    test('accepts the edges of the range', () {
      final back = repo.decode(
        _bytes(
          _file(
            positions: [
              {'icName': 'a', 'latitude': 90, 'longitude': 180},
              {'icName': 'b', 'latitude': -90, 'longitude': -180},
            ],
          ),
        ),
      );

      expect(back.icPositions, hasLength(2));
    });
  });

  group('the messages', () {
    test('never include a value of the file', () {
      // A secret in every place a wrong value can be.
      const secret = 'SECRET-4321';
      final messages = <String>[
        _decodeError(
          _file(
            lines: [
              _line({'fare': secret}),
            ],
          ),
        ).message,
        _decodeError(
          _file(
            lines: [
              _line({'status': secret}),
            ],
          ),
        ).message,
        _decodeError(
          _file(
            lines: [
              _line({'exitAt': secret}),
            ],
          ),
        ).message,
        _decodeError(
          _file(
            lines: [
              _line(),
              _line({'id': secret, 'cardNumber': 1}),
            ],
          ),
        ).message,
        _decodeError(
          _file(
            lines: [
              _line({'id': secret}),
              _line({'id': secret, 'duplicateKey': 'k-2'}),
            ],
          ),
        ).message,
        _decodeError(
          _file(
            mappings: [
              {'icName': secret, 'pointId': 1},
            ],
          ),
        ).message,
        _decodeError({'format': secret}).message,
        _decodeError(
          _file(
            positions: [
              {'icName': secret, 'latitude': 500, 'longitude': 0},
            ],
          ),
        ).message,
      ];
      for (final message in messages) {
        expect(message, isNot(contains(secret)), reason: message);
      }
      // Not even what the JSON parser quotes of a broken file.
      try {
        repo.decode(Uint8List.fromList(utf8.encode('{"a": $secret')));
        fail('should have thrown');
      } on FormatException catch (e) {
        expect(e.message, isNot(contains('SECRET')));
      }
    });
  });
}
