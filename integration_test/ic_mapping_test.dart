import 'package:drift/native.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_strings.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fixtures/statement_fixture.dart';
import '../test/support/app_harness.dart';

/// SCR-004 from the screen down to the database. The IC master is a fictional
/// one in which テスト北 has two points, so the user has to choose.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));

  tearDown(() => database.close());

  testWidgets('a registered mapping changes the route names, an unlink '
      'changes them back', (tester) async {
    await pumpApp(
      tester,
      database: database,
      picker: () async => StatementFixture.threeRows(),
    );
    await openSettings(tester);
    await tester.tap(find.text(SettingsStrings.importButton));
    await tester.pumpAndSettle();

    // The credit of the IC master is always shown.
    await tester.scrollUntilVisible(find.text(SettingsStrings.credit), 100);
    expect(find.text(SettingsStrings.credit), findsOneWidget);

    // 北 is ambiguous, so only the exits give a route name.
    await openStatements(tester);
    expect(find.text('テスト自動車道'), findsNWidgets(2));
    expect(find.text('テスト自動車道・テスト都市高速'), findsOneWidget);

    // The user chooses the second point of テスト北 (the other route).
    await openSettings(tester);
    await tester.scrollUntilVisible(
      find.text(SettingsStrings.icMappingButton),
      100,
    );
    await tester.tap(find.text(SettingsStrings.icMappingButton));
    await tester.pumpAndSettle();
    expect(find.text(IcMappingStrings.ambiguous(3)), findsOneWidget);
    await tester.tap(find.text('テスト北ＩＣ'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('テスト高速道路'));
    await tester.pumpAndSettle();

    expect(find.text(IcMappingStrings.ambiguous(3)), findsNothing);
    expect(
      find.text(IcMappingStrings.registeredLine('テスト北ＩＣ', 'テスト北')),
      findsOneWidget,
    );

    // The list shows both routes now: the two ICs share none.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await openStatements(tester);
    expect(find.text('テスト高速道路・テスト自動車道'), findsNWidgets(2));

    // Unlinking brings the list back.
    await openSettings(tester);
    await tester.scrollUntilVisible(
      find.text(SettingsStrings.icMappingButton),
      100,
    );
    await tester.tap(find.text(SettingsStrings.icMappingButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(IcMappingStrings.unlink));
    await tester.pumpAndSettle();
    expect(find.text(IcMappingStrings.ambiguous(3)), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await openStatements(tester);
    expect(find.text('テスト高速道路・テスト自動車道'), findsNothing);
    expect(find.text('テスト自動車道'), findsNWidgets(2));
    expect(find.text('テスト自動車道・テスト都市高速'), findsOneWidget);
  });
}
