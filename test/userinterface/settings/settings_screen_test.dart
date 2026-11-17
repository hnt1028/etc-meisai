import 'dart:async';
import 'dart:typed_data';

import 'package:etc_meisai/application/usecase/route_map/list_operator_colors_uc.dart';
import 'package:etc_meisai/userinterface/route_map/operator_color_providers.dart';
import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

Widget _app({
  required FakeStatementIF statement,
  required FakeStatementLineIF lines,
  Future<Uint8List?> Function()? picker,
}) {
  return ProviderScope(
    overrides: [
      importStatementUCProvider.overrideWithValue(
        ImportStatementUC(statement: statement, statementLines: lines),
      ),
      deleteAllStatementLinesUCProvider.overrideWithValue(
        DeleteAllStatementLinesUC(statementLines: lines),
      ),
      listStatementLinesUCProvider.overrideWithValue(fakeListUC(lines)),
      listOperatorColorsUCProvider.overrideWithValue(
        ListOperatorColorsUC(operatorColors: FakeOperatorColorIF()),
      ),
      csvPickerProvider.overrideWithValue(
        picker ?? () async => Uint8List.fromList([1]),
      ),
    ],
    // Not const, so that the constructor runs (and is counted by coverage).
    // ignore: prefer_const_constructors
    child: EtcMeisaiApp(),
  );
}

Finder _text(String text) => find.text(text);

/// Starts the app and opens the settings screen from the navigation bar.
Future<void> _pump(WidgetTester tester, Widget app) async {
  // The settings are a long list: a tall screen shows all of it.
  tester.view.physicalSize = const Size(800, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppStrings.settingsTab));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on the settings screen with nothing reported', (
    tester,
  ) async {
    await _pump(
      tester,
      _app(statement: FakeStatementIF([]), lines: FakeStatementLineIF()),
    );

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: _text(SettingsStrings.title),
      ),
      findsOneWidget,
    );
    expect(_text(SettingsStrings.importButton), findsOneWidget);
    expect(_text(SettingsStrings.deleteButton), findsOneWidget);
    expect(find.textContaining('追加'), findsNothing);
    expect(find.textContaining('取り込めませんでした'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('shows the counts after an import', (tester) async {
    await _pump(
      tester,
      _app(
        statement: FakeStatementIF([
          fakeStatementLine(),
          fakeStatementLine(exitIc: 'C-IC'),
        ]),
        lines: FakeStatementLineIF(),
      ),
    );

    await tester.tap(_text(SettingsStrings.importButton));
    await tester.pumpAndSettle();

    expect(_text(SettingsStrings.importResult(2, 0, 0)), findsOneWidget);
  });

  testWidgets('shows nothing when no file is chosen', (tester) async {
    await _pump(
      tester,
      _app(
        statement: FakeStatementIF([fakeStatementLine()]),
        lines: FakeStatementLineIF(),
        picker: () async => null,
      ),
    );

    await tester.tap(_text(SettingsStrings.importButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('追加'), findsNothing);
  });

  testWidgets('shows what is invalid in the CSV', (tester) async {
    await _pump(
      tester,
      _app(
        statement: FakeStatementIF([], error: const FormatException('2行目: 不正')),
        lines: FakeStatementLineIF(),
      ),
    );

    await tester.tap(_text(SettingsStrings.importButton));
    await tester.pumpAndSettle();

    expect(_text(SettingsStrings.importFailed('2行目: 不正')), findsOneWidget);
  });

  testWidgets('shows a progress bar and locks the buttons while importing', (
    tester,
  ) async {
    final gate = Completer<void>();
    final lines = FakeStatementLineIF()..gate = gate.future;
    await _pump(
      tester,
      _app(statement: FakeStatementIF([fakeStatementLine()]), lines: lines),
    );

    await tester.tap(_text(SettingsStrings.importButton));
    await tester.pump();
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, SettingsStrings.importButton),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, SettingsStrings.deleteButton),
          )
          .onPressed,
      isNull,
    );

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  group('delete', () {
    testWidgets('asks first, and keeps the data when cancelled', (
      tester,
    ) async {
      final lines = FakeStatementLineIF();
      await lines.save(fakeStatementLine());
      await _pump(tester, _app(statement: FakeStatementIF([]), lines: lines));

      await tester.tap(_text(SettingsStrings.deleteButton));
      await tester.pumpAndSettle();
      expect(_text(SettingsStrings.deleteConfirmMessage), findsOneWidget);

      await tester.tap(_text(SettingsStrings.deleteConfirmCancel));
      await tester.pumpAndSettle();

      expect(_text(SettingsStrings.deleteConfirmMessage), findsNothing);
      expect(_text(SettingsStrings.deleted), findsNothing);
      expect(lines.stored, hasLength(1));
    });

    testWidgets('deletes everything once confirmed', (tester) async {
      final lines = FakeStatementLineIF();
      await lines.save(fakeStatementLine());
      await _pump(tester, _app(statement: FakeStatementIF([]), lines: lines));

      await tester.tap(_text(SettingsStrings.deleteButton));
      await tester.pumpAndSettle();
      await tester.tap(_text(SettingsStrings.deleteConfirmOk));
      await tester.pumpAndSettle();

      expect(_text(SettingsStrings.deleted), findsOneWidget);
      expect(lines.stored, isEmpty);
    });

    testWidgets('closing the dialog without a choice keeps the data', (
      tester,
    ) async {
      final lines = FakeStatementLineIF();
      await lines.save(fakeStatementLine());
      await _pump(tester, _app(statement: FakeStatementIF([]), lines: lines));

      await tester.tap(_text(SettingsStrings.deleteButton));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();

      expect(lines.stored, hasLength(1));
      expect(_text(SettingsStrings.deleted), findsNothing);
    });

    testWidgets('shows a failure', (tester) async {
      final lines = FakeStatementLineIF()..error = StateError('disk');
      await _pump(tester, _app(statement: FakeStatementIF([]), lines: lines));

      await tester.tap(_text(SettingsStrings.deleteButton));
      await tester.pumpAndSettle();
      await tester.tap(_text(SettingsStrings.deleteConfirmOk));
      await tester.pumpAndSettle();

      expect(_text(SettingsStrings.deleteFailed), findsOneWidget);
    });
  });

  testWidgets('shows the credit of the IC master', (tester) async {
    await _pump(
      tester,
      _app(statement: FakeStatementIF([]), lines: FakeStatementLineIF()),
    );

    await tester.scrollUntilVisible(_text(SettingsStrings.credit), 100);
    expect(_text(SettingsStrings.credit), findsOneWidget);
    expect(SettingsStrings.credit, contains('国土数値情報'));
    expect(SettingsStrings.credit, contains('加工して作成'));
    expect(SettingsStrings.credit, contains('OpenStreetMap contributors'));
  });
}
