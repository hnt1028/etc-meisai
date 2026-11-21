import 'package:drift/native.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fixtures/statement_fixture.dart';
import '../test/support/app_harness.dart';

/// A use whose vehicle number is blank in the CSV (docs/csv-format.md), from
/// the CSV down to the database: it is imported, the user enters the number
/// once, and importing the CSV again does not blank it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));

  tearDown(() => database.close());

  testWidgets('imports a blank vehicle number, which the user enters once', (
    tester,
  ) async {
    // Pending, so that importing it again overwrites it.
    final blank = [...StatementFixture.row(note: '確認中')]..[12] = '';
    await pumpApp(
      tester,
      database: database,
      picker: () async =>
          StatementFixture.csv([StatementFixture.header, blank]),
    );

    // The CSV is imported although the vehicle number is blank.
    await openSettings(tester);
    await tester.tap(find.text(SettingsStrings.importButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('追加 1 件'), findsOneWidget);
    await openStatements(tester);

    // The detail has no number, and a button to enter one.
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    final enter = find.byKey(const ValueKey('enter-vehicle-number'));
    // The detail is a long list: scroll to the vehicle number.
    await tester.drag(find.byType(ListTile).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(enter, findsOneWidget);

    // The number is entered once.
    await tester.tap(enter);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4321');
    await tester.pumpAndSettle();
    await tester.tap(find.text(StatementDetailStrings.save));
    await tester.pumpAndSettle();
    expect(find.text('4321'), findsOneWidget);
    expect(enter, findsNothing);
    final stored = await database.select(database.statementLines).get();
    expect(stored.single.vehicleNumber, 4321);

    // Importing the same CSV again (it overwrites the pending line) keeps it.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await openSettings(tester);
    await tester.tap(find.text(SettingsStrings.importButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('上書き 1 件'), findsOneWidget);
    final again = await database.select(database.statementLines).get();
    expect(again.single.vehicleNumber, 4321);

    // A new screen for the line shows the number, and no button.
    await openStatements(tester);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListTile).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('4321'), findsOneWidget);
    expect(enter, findsNothing);
  });

  testWidgets('imports a line without an entrance, which the user fills in '
      'without changing the duplicate key', (tester) async {
    // Pending, so that importing it again overwrites it. The date, the time and
    // the entrance IC are blank, and so is the vehicle number.
    final blank = [...StatementFixture.row(note: '確認中')];
    for (final index in [0, 1, 4, 12]) {
      blank[index] = '';
    }
    await pumpApp(
      tester,
      database: database,
      picker: () async =>
          StatementFixture.csv([StatementFixture.header, blank]),
    );
    Future<void> importCsv() async {
      await openSettings(tester);
      await tester.tap(find.text(SettingsStrings.importButton));
      await tester.pumpAndSettle();
    }

    await importCsv();
    expect(find.textContaining('追加 1 件'), findsOneWidget);
    await openStatements(tester);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // The entrance IC.
    await tester.tap(find.byKey(const ValueKey('enter-entrance-ic')));
    await tester.pumpAndSettle();
    // The dialog lists the ICs first: the name is typed as the last choice.
    await tester.tap(find.byKey(const ValueKey('entrance-ic-free')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('entrance-ic-typed')),
      'テスト北ＩＣ',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(StatementDetailStrings.save));
    await tester.pumpAndSettle();
    expect(find.text('テスト北ＩＣ'), findsWidgets);

    // The entrance date and time: the pickers, then the confirmation.
    await tester.tap(find.byKey(const ValueKey('enter-entrance-at')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(StatementDetailStrings.save));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('enter-entrance-at')), findsNothing);
    expect(find.byKey(const ValueKey('enter-entrance-ic')), findsNothing);

    // The CSV's columns are not changed, and the entered ones are kept apart.
    var rows = await database.select(database.statementLines).get();
    expect(rows.single.entranceAt, isNull);
    expect(rows.single.entranceIc, isNull);
    expect(rows.single.enteredEntranceIc, 'テスト北ＩＣ');
    expect(rows.single.enteredEntranceAt, isNotNull);
    final key = rows.single.duplicateKey;

    // The same CSV again overwrites the line: it is not added a second time,
    // and what the user entered stays.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await importCsv();
    expect(find.textContaining('上書き 1 件'), findsOneWidget);
    expect(find.textContaining('追加 0 件'), findsOneWidget);
    rows = await database.select(database.statementLines).get();
    expect(rows, hasLength(1));
    expect(rows.single.duplicateKey, key);
    expect(rows.single.enteredEntranceIc, 'テスト北ＩＣ');
    expect(rows.single.enteredEntranceAt, isNotNull);

    // The line shows what was entered, and offers nothing to enter.
    await openStatements(tester);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('テスト北ＩＣ'), findsWidgets);
    expect(find.byKey(const ValueKey('enter-entrance-at')), findsNothing);
    expect(find.byKey(const ValueKey('enter-entrance-ic')), findsNothing);
  });
}
