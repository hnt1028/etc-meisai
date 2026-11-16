import 'package:etc_meisai/infrastructure/repository/settings/statement_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/statement_fixture.dart';

/// The vehicle number is column 13 (index 12) of the CSV.
List<String> _row(String vehicleNumber) =>
    [...StatementFixture.row()]..[12] = vehicleNumber;

void main() {
  const repo = StatementRepo();

  test('reads a blank vehicle number as no vehicle number', () {
    final lines = repo.parse(
      StatementFixture.csv([StatementFixture.header, _row('')]),
    );

    expect(lines.single.vehicleNumber, isNull);
    // The other columns are read as usual.
    expect(lines.single.fare, 960);
    expect(lines.single.exitIc, 'テスト南ＩＣ');
  });

  test('reads a vehicle number, and a blank one in the same file', () {
    final lines = repo.parse(
      StatementFixture.csv([
        StatementFixture.header,
        _row('1234'),
        [...StatementFixture.row(exitIc: 'テスト東ＩＣ')]..[12] = '',
      ]),
    );

    expect(lines.map((l) => l.vehicleNumber), [1234, null]);
  });

  test('still rejects a vehicle number that is not a number', () {
    expect(
      () => repo.parse(
        StatementFixture.csv([StatementFixture.header, _row('ABCD')]),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('2行目'), isNot(contains('ABCD'))),
        ),
      ),
    );
  });
}
