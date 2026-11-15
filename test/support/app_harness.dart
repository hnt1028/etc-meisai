import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/application/usecase/statements/list_statement_lines_uc.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/settings/statement_repo.dart';
import 'package:etc_meisai/infrastructure/repository/statements/statement_line_repo.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/settings/csv_picker.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Starts the whole app on [database], wired like lib/main.dart. Only the file
/// picker is replaced, because it opens a system screen.
Future<void> pumpApp(
  WidgetTester tester, {
  required AppDatabase database,
  required CsvPicker picker,
}) async {
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
        listStatementLinesUCProvider.overrideWithValue(
          ListStatementLinesUC(statementLines: statementLines),
        ),
        csvPickerProvider.overrideWithValue(picker),
      ],
      // ignore: prefer_const_constructors
      child: EtcMeisaiApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens a screen from the navigation bar.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> openStatements(WidgetTester tester) =>
    openTab(tester, AppStrings.statementsTab);

Future<void> openSettings(WidgetTester tester) =>
    openTab(tester, AppStrings.settingsTab);
