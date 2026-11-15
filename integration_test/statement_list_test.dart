import 'package:drift/native.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fixtures/statement_fixture.dart';
import '../test/support/app_harness.dart';

/// SCR-002 from the screen down to the database, wired like lib/main.dart.
/// The statement lines are imported through SCR-001, as a user would.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));

  tearDown(() => database.close());

  testWidgets('shows what was imported, filters it, and follows a deletion', (
    tester,
  ) async {
    await pumpApp(
      tester,
      database: database,
      picker: () async => StatementFixture.threeRows(),
    );

    // Nothing is imported yet.
    expect(find.text(StatementListStrings.emptyNoData), findsOneWidget);

    await openSettings(tester);
    await tester.tap(find.text(SettingsStrings.importButton));
    await tester.pumpAndSettle();
    await openStatements(tester);

    // Three lines of 960 yen each, one of them pending.
    expect(find.text('テスト北ＩＣ → テスト東ＩＣ'), findsOneWidget);
    expect(find.text('テスト北ＩＣ → テスト西ＩＣ'), findsOneWidget);
    expect(find.text('テスト北ＩＣ → テスト南ＩＣ'), findsOneWidget);
    expect(find.text('2026/01/10 08:30 → 2026/01/10 09:15'), findsNWidgets(3));
    expect(find.text(StatementListStrings.pending), findsOneWidget);
    expect(find.text(StatementListStrings.totalFare(2880)), findsOneWidget);
    expect(
      find.text(StatementListStrings.totalBreakdown(0, 2880)),
      findsOneWidget,
    );

    // The card is offered by its last 4 only.
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    expect(find.textContaining('0000-'), findsNothing);
    await tester.tap(
      find.text(StatementListStrings.cardNumberChoice('0001')).last,
    );
    await tester.pumpAndSettle();
    expect(find.text(StatementListStrings.totalFare(2880)), findsOneWidget);

    // The imported vehicle number keeps all three lines.
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1234').last);
    await tester.pumpAndSettle();
    expect(find.text(StatementListStrings.totalFare(2880)), findsOneWidget);
    await tester.tap(find.text(StatementListStrings.clearFilter));
    await tester.pumpAndSettle();
    expect(find.text(StatementListStrings.clearFilter), findsNothing);

    // The timeline shows the same three lines on 10 January.
    await tester.tap(find.text(StatementListStrings.modeTimeline));
    await tester.pumpAndSettle();
    expect(find.text('2026/01/10'), findsOneWidget);
    expect(find.byKey(const ValueKey('timeline-bar-2')), findsOneWidget);

    // A tap opens the detail, and back returns to the timeline.
    await tester.tap(find.byKey(const ValueKey('timeline-row-0')));
    await tester.pumpAndSettle();
    expect(find.text(StatementDetailStrings.title), findsOneWidget);
    // The detail is a long list, so scroll to the fields near the bottom.
    await tester.scrollUntilVisible(find.text('1234'), 100);
    expect(find.text('1234'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(StatementDetailStrings.cardNumberValue('0001')),
      100,
    );
    expect(
      find.text(StatementDetailStrings.cardNumberValue('0001')),
      findsOneWidget,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('2026/01/10'), findsOneWidget);
    await tester.tap(find.text(StatementListStrings.modeList));
    await tester.pumpAndSettle();

    // Deleting on the settings screen empties the list.
    await openSettings(tester);
    await tester.tap(find.text(SettingsStrings.deleteButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SettingsStrings.deleteConfirmOk));
    await tester.pumpAndSettle();
    await openStatements(tester);

    expect(find.text(StatementListStrings.emptyNoData), findsOneWidget);
    expect(find.text(StatementListStrings.totalFare(0)), findsOneWidget);
  });
}
