import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/infrastructure/repository/settings/statement_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/statement_fixture.dart';

void main() {
  // Not const, like the other tests of the repository.
  // ignore: prefer_const_constructors
  final repo = StatementRepo();

  List<String> discountTypesOf(String note) => repo
      .parse(
        StatementFixture.csv([
          StatementFixture.header,
          StatementFixture.row(note: note),
        ]),
      )
      .single
      .discountTypes;

  test('does not take the date of the note for a discount', () {
    // docs/csv-format.md: the date the line really belongs to.
    expect(discountTypesOf('確定;26/11/01;深夜割引'), ['深夜割引']);
  });

  test('does not take the notices after the proof of use for a discount', () {
    expect(discountTypesOf('確定;更新あり'), isEmpty);
    expect(discountTypesOf('確定;削除あり;休日割引'), ['休日割引']);
  });

  test('keeps the status, and the adjustments and discounts', () {
    final line = repo
        .parse(
          StatementFixture.csv([
            StatementFixture.header,
            StatementFixture.row(note: '確認中;乗継調整;ＥＴＣ通常＊１'),
          ]),
        )
        .single;

    expect(line.status, ConfirmationStatusValue.pending);
    expect(line.discountTypes, ['乗継調整', 'ＥＴＣ通常＊１']);
  });
}
