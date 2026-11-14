import 'dart:typed_data';

import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/infrastructure/repository/settings/statement_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jis0208/jis0208.dart';

const _header = [
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

/// A fictional row. Override columns by index.
List<String> _row({Map<int, String> set = const {}}) {
  final row = [
    '26/01/10',
    '08:30',
    '26/01/10',
    '09:15',
    'テスト北ＩＣ',
    'テスト南ＩＣ',
    '1,200',
    '-240',
    '960',
    '0',
    '960',
    '1',
    'TEST 0000',
    '0000-****-0001',
    '確定;深夜割引',
  ];
  set.forEach((index, value) => row[index] = value);
  return row;
}

/// Encodes the rows as a CP932 CSV, like the real service output.
Uint8List _csv(List<List<String>> rows, {String eol = '\r\n'}) {
  String field(String v) => v.contains(',') ? '"$v"' : v;
  final text = rows.map((r) => r.map(field).join(',')).join(eol);
  return Uint8List.fromList(Windows31JEncoder().convert('$text$eol'));
}

void main() {
  const repo = StatementRepo();

  group('parse: normal rows', () {
    test('reads every column of a row', () {
      final trips = repo.parse(_csv([_header, _row()]));

      expect(trips, hasLength(1));
      final trip = trips.single;
      expect(trip.entranceAt, DateTime(2026, 1, 10, 8, 30));
      expect(trip.exitAt, DateTime(2026, 1, 10, 9, 15));
      expect(trip.entranceIc, 'テスト北ＩＣ');
      expect(trip.exitIc, 'テスト南ＩＣ');
      expect(trip.grossFare, 1200);
      expect(trip.etcDiscount, -240);
      expect(trip.fare, 960);
      expect(trip.fareAfterRebate, 0);
      expect(trip.postpaidFare, 960);
      expect(trip.vehicleType, '1');
      expect(trip.vehicleNumber, 'TEST 0000');
      expect(trip.cardNumber, '0000-****-0001');
      expect(trip.status, ConfirmationStatusValue.confirmed);
      expect(trip.discountTypes, ['深夜割引']);
    });

    test('reads rows of a CSV that ends with LF', () {
      final trips = repo.parse(_csv([_header, _row(), _row()], eol: '\n'));
      expect(trips, hasLength(2));
    });

    test('reads characters that only CP932 has', () {
      final trips = repo.parse(
        _csv([
          _header,
          _row(set: {4: '①㈱髙ＩＣ'}),
        ]),
      );
      expect(trips.single.entranceIc, '①㈱髙ＩＣ');
    });
  });

  group('parse: amounts', () {
    test('blank gross fare and discount become null, not 0', () {
      final trips = repo.parse(
        _csv([
          _header,
          _row(set: {6: '', 7: ''}),
        ]),
      );
      expect(trips.single.grossFare, isNull);
      expect(trips.single.etcDiscount, isNull);
    });

    for (final index in [8, 9, 10]) {
      test('blank ${_header[index]} is an error that names the column', () {
        expect(
          () => repo.parse(
            _csv([
              _header,
              _row(set: {index: ''}),
            ]),
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              allOf(contains('2行目'), contains(_header[index])),
            ),
          ),
        );
      });
    }

    test('an amount that is not a number is an error', () {
      expect(
        () => repo.parse(
          _csv([
            _header,
            _row(set: {8: 'abc'}),
          ]),
        ),
        throwsFormatException,
      );
    });
  });

  group('parse: entrance and exit', () {
    test('a blank entrance becomes null', () {
      final trips = repo.parse(
        _csv([
          _header,
          _row(set: {0: '', 1: '', 4: ''}),
        ]),
      );
      expect(trips.single.entranceAt, isNull);
      expect(trips.single.entranceIc, isNull);
    });

    test('an entrance date without a time is an error', () {
      expect(
        () => repo.parse(
          _csv([
            _header,
            _row(set: {1: ''}),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('an impossible date is an error', () {
      expect(
        () => repo.parse(
          _csv([
            _header,
            _row(set: {2: '26/02/30'}),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('a blank exit IC is an error', () {
      expect(
        () => repo.parse(
          _csv([
            _header,
            _row(set: {5: ''}),
          ]),
        ),
        throwsFormatException,
      );
    });
  });

  group('parse: note', () {
    test('reads 確定 with no discount type', () {
      final trip = repo
          .parse(
            _csv([
              _header,
              _row(set: {14: '確定'}),
            ]),
          )
          .single;
      expect(trip.status, ConfirmationStatusValue.confirmed);
      expect(trip.discountTypes, isEmpty);
    });

    test('reads 確認中 and several discount types', () {
      final trip = repo
          .parse(
            _csv([
              _header,
              _row(set: {14: '確認中;深夜割引;休日割引'}),
            ]),
          )
          .single;
      expect(trip.status, ConfirmationStatusValue.pending);
      expect(trip.discountTypes, ['深夜割引', '休日割引']);
    });

    test('a discount type is not a status', () {
      expect(
        () => repo.parse(
          _csv([
            _header,
            _row(set: {14: '深夜割引'}),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('both 確定 and 確認中 is an error', () {
      expect(
        () => repo.parse(
          _csv([
            _header,
            _row(set: {14: '確定;確認中'}),
          ]),
        ),
        throwsFormatException,
      );
    });
  });

  group('parse: invalid CSV', () {
    test('a row with too few columns says which row and how many', () {
      final short = _row().sublist(0, 14);
      expect(
        () => repo.parse(_csv([_header, _row(), short])),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('3行目'), contains('14')),
          ),
        ),
      );
    });

    test('a half-width header is an error that names the column', () {
      final header = [..._header]..[4] = '利用IC（自）';
      expect(
        () => repo.parse(_csv([header, _row()])),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('5列目'),
          ),
        ),
      );
    });

    test('a header with the wrong column count is an error', () {
      expect(
        () => repo.parse(_csv([_header.sublist(0, 14), _row()])),
        throwsFormatException,
      );
    });

    test('bytes that are not CP932 are an error', () {
      // A lead byte with nothing after it.
      expect(
        () => repo.parse(Uint8List.fromList([0x81])),
        throwsFormatException,
      );
    });

    test('an empty CSV is an error', () {
      expect(() => repo.parse(Uint8List(0)), throwsFormatException);
    });

    test('a CSV with only a header gives no trips', () {
      expect(repo.parse(_csv([_header])), isEmpty);
    });

    test('the error message does not include personal information', () {
      try {
        repo.parse(
          _csv([
            _header,
            _row(set: {8: ''}),
          ]),
        );
        fail('should throw');
      } on FormatException catch (e) {
        expect(e.message, isNot(contains('TEST 0000')));
        expect(e.message, isNot(contains('0000-****-0001')));
      }
    });
  });
}
