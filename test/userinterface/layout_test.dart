import 'package:drift/native.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_controller.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_strings.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/statement_fixture.dart';
import '../support/app_harness.dart';

/// The screens must fit the sizes of docs/specification.md (3.8): a small
/// phone, a phone held sideways, a tablet, and larger text. An overflow of the
/// layout is an exception in a test, so the test fails on one.
void main() {
  const cases = <(String, Size, double)>[
    ('a small phone, 320 x 568', Size(320, 568), 1.0),
    ('a phone, 360 x 640', Size(360, 640), 1.0),
    ('a phone with larger text, 360 x 640, x1.5', Size(360, 640), 1.5),
    ('a tall phone, 412 x 915', Size(412, 915), 1.0),
    ('a phone held sideways, 800 x 360', Size(800, 360), 1.0),
    ('a tablet, 800 x 1280', Size(800, 1280), 1.0),
    ('a tablet held sideways, 1280 x 800', Size(1280, 800), 1.0),
  ];

  for (final (name, size, textScale) in cases) {
    testWidgets('every screen fits $name', (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        database: database,
        // One line has no vehicle number, so its detail has the enter button.
        picker: () async => StatementFixture.csv([
          StatementFixture.header,
          StatementFixture.row(exitIc: 'テスト東ＩＣ'),
          [...StatementFixture.row(exitIc: 'テスト西ＩＣ', note: '確認中')]..[12] = '',
        ]),
      );

      // Every step must leave the screen without an exception (an overflow).
      var step = 'the first screen';
      void expectFits() {
        final exception = tester.takeException();
        expect(exception, isNull, reason: 'at $step');
      }

      Future<void> tapText(String text) async {
        final finder = find.text(text).first;
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      expectFits();

      step = 'the settings';
      await openSettings(tester);
      expectFits();
      await tapText(SettingsStrings.importButton);

      step = 'the IC mapping';
      await tester.scrollUntilVisible(
        find.text(SettingsStrings.icMappingButton),
        100,
      );
      await tapText(SettingsStrings.icMappingButton);
      expectFits();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      step = 'the statement list';
      await openStatements(tester);
      expectFits();

      // The first and the last line: one of them has no vehicle number.
      for (final which in [0, 1]) {
        step = 'the statement detail of line $which';
        final tiles = find.byType(ListTile);
        final tile = which == 0 ? tiles.first : tiles.last;
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expectFits();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }

      step = 'the timeline';
      await tapText(StatementListStrings.modeTimeline);
      expectFits();
      await tapText(StatementListStrings.modeList);

      step = 'the route map';
      await openTab(tester, AppStrings.routeMapTab);
      expectFits();
      step = 'the route map with the filter open';
      await tapText('絞り込み');
      expectFits();

      step = 'the aggregation';
      await openTab(tester, AppStrings.aggregationTab);
      expectFits();
      for (final display in AggregationDisplay.values) {
        await tapText(AggregationStrings.display(display));
        for (final kind in AggregationKind.values) {
          step = 'the aggregation of ${kind.name} as ${display.name}';
          await tapText(AggregationStrings.kind(kind));
          expectFits();
        }
      }
    });
  }
}
