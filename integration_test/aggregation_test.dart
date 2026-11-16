import 'package:drift/native.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_controller.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_strings.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fixtures/statement_fixture.dart';
import '../test/support/app_harness.dart';

/// SCR-006 from the screen down to the database, wired like lib/main.dart.
/// The statement lines are imported through SCR-001, as a user would.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));

  tearDown(() => database.close());

  testWidgets('aggregates what was imported, and follows a deletion', (
    tester,
  ) async {
    await pumpApp(
      tester,
      database: database,
      picker: () async => StatementFixture.threeRows(),
    );
    await openTab(tester, AppStrings.aggregationTab);
    expect(find.text(StatementListStrings.emptyNoData), findsOneWidget);

    await openSettings(tester);
    await tester.tap(find.text(SettingsStrings.importButton));
    await tester.pumpAndSettle();
    await openTab(tester, AppStrings.aggregationTab);

    // Three lines of 960 yen, each with a 240 yen discount.
    expect(find.text(AggregationStrings.summary(3, 2880, 720)), findsOneWidget);
    expect(find.text('2026/01'), findsOneWidget);
    expect(find.text('3回'), findsOneWidget);

    // The entrance is on all three lines, and each exit on one.
    await tester.tap(find.text(AggregationStrings.kind(AggregationKind.ic)));
    await tester.pumpAndSettle();
    expect(find.text('テスト北ＩＣ'), findsOneWidget);
    expect(find.text('テスト東ＩＣ'), findsOneWidget);

    // The graph has a bar for each row.
    await tester.tap(
      find.text(AggregationStrings.display(AggregationDisplay.graph)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);

    // Deleting on the settings screen empties the aggregation.
    await openSettings(tester);
    await tester.tap(find.text(SettingsStrings.deleteButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SettingsStrings.deleteConfirmOk));
    await tester.pumpAndSettle();
    await openTab(tester, AppStrings.aggregationTab);

    expect(find.text(StatementListStrings.emptyNoData), findsOneWidget);
  });
}
