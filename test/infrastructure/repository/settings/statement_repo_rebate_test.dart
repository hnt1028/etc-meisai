import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/infrastructure/repository/settings/statement_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/statement_fixture.dart';

/// The rebate fare is column 10 (index 9) of the CSV.
List<String> _row({String rebate = '', String note = '確認中;深夜割引'}) =>
    [...StatementFixture.row(note: note)]..[9] = rebate;

void main() {
  // Not const, like the other tests of the repository.
  // ignore: prefer_const_constructors
  final repo = StatementRepo();

  test('reads a blank rebate fare as 0', () {
    final lines = repo.parse(
      StatementFixture.csv([StatementFixture.header, _row()]),
    );

    final line = lines.single;
    expect(line.fareAfterRebate, 0);
    // The other amounts are read as usual: the postpaid fare is the fare.
    expect(line.fare, 960);
    expect(line.postpaidFare, 960);
    expect(line.status, ConfirmationStatusValue.pending);
    expect(line.discountTypes, ['深夜割引']);
  });

  test('reads a blank rebate fare of a confirmed line as 0, too', () {
    final lines = repo.parse(
      StatementFixture.csv([StatementFixture.header, _row(note: '確定')]),
    );

    expect(lines.single.fareAfterRebate, 0);
    expect(lines.single.status, ConfirmationStatusValue.confirmed);
  });

  test('reads a rebate fare, and a blank one in the same file', () {
    final lines = repo.parse(
      StatementFixture.csv([
        StatementFixture.header,
        _row(rebate: '100'),
        _row(),
      ]),
    );

    expect(lines.map((l) => l.fareAfterRebate), [100, 0]);
  });

  test('still rejects a rebate fare that is not a number', () {
    expect(
      () => repo.parse(
        StatementFixture.csv([StatementFixture.header, _row(rebate: 'abc')]),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('還元額適用料金'),
        ),
      ),
    );
  });
}
