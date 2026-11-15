import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/application/usecase/statements/list_statement_lines_uc.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

Widget _app() {
  final lines = FakeStatementLineIF();
  return ProviderScope(
    overrides: [
      importStatementUCProvider.overrideWithValue(
        ImportStatementUC(
          statement: FakeStatementIF([]),
          statementLines: lines,
        ),
      ),
      deleteAllStatementLinesUCProvider.overrideWithValue(
        DeleteAllStatementLinesUC(statementLines: lines),
      ),
      listStatementLinesUCProvider.overrideWithValue(
        ListStatementLinesUC(statementLines: lines),
      ),
    ],
    // ignore: prefer_const_constructors
    child: EtcMeisaiApp(),
  );
}

void main() {
  testWidgets('starts on the statement list', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text(StatementListStrings.title), findsOneWidget);
    expect(find.text(SettingsStrings.importButton), findsNothing);
    expect(find.text(AppStrings.statementsTab), findsOneWidget);
    expect(find.text(AppStrings.settingsTab), findsOneWidget);
  });

  testWidgets('switches between the two screens with the navigation bar', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.settingsTab));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.importButton), findsOneWidget);

    await tester.tap(find.text(AppStrings.statementsTab));
    await tester.pumpAndSettle();
    expect(find.text(StatementListStrings.title), findsOneWidget);

    // Tapping the tab that is already shown does nothing harmful.
    await tester.tap(find.text(AppStrings.statementsTab));
    await tester.pumpAndSettle();
    expect(find.text(StatementListStrings.title), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
