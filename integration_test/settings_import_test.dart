import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/settings/statement_repo.dart';
import 'package:etc_meisai/infrastructure/repository/statements/statement_line_repo.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fixtures/statement_fixture.dart';

/// SCR-001 from the screen down to the database, wired like lib/main.dart.
/// Only the file picker is replaced, because it opens a system screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late Uint8List chosen;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    chosen = StatementFixture.threeRows();
  });

  tearDown(() => database.close());

  Future<void> start(WidgetTester tester) async {
    final statementLines = StatementLineRepo(database);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importStatementUCProvider.overrideWithValue(
            ImportStatementUC(
              statement: const StatementRepo(),
              statementLines: statementLines,
            ),
          ),
          deleteAllStatementLinesUCProvider.overrideWithValue(
            DeleteAllStatementLinesUC(statementLines: statementLines),
          ),
          csvPickerProvider.overrideWithValue(() async => chosen),
        ],
        // ignore: prefer_const_constructors
        child: EtcMeisaiApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> importCsv(WidgetTester tester) async {
    await tester.tap(find.text(SettingsStrings.importButton));
    await tester.pumpAndSettle();
  }

  testWidgets('import, import again, delete, import again', (tester) async {
    await start(tester);

    await importCsv(tester);
    expect(find.text(SettingsStrings.importResult(3, 0, 0)), findsOneWidget);

    // The pending line is replaced; the confirmed lines are left as they are.
    await importCsv(tester);
    expect(find.text(SettingsStrings.importResult(0, 1, 2)), findsOneWidget);

    await tester.tap(find.text(SettingsStrings.deleteButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SettingsStrings.deleteConfirmOk));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.deleted), findsOneWidget);

    await importCsv(tester);
    expect(find.text(SettingsStrings.importResult(3, 0, 0)), findsOneWidget);
  });

  testWidgets('a broken CSV is reported and stores nothing', (tester) async {
    await start(tester);
    chosen = StatementFixture.brokenHeader();

    await importCsv(tester);

    expect(find.textContaining('取り込めませんでした'), findsOneWidget);
    expect(await StatementLineRepo(database).findAll(), isEmpty);
  });
}
