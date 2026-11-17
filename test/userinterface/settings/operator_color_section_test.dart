import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/application/usecase/route_map/list_operator_colors_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/operator_default_colors.dart';
import 'package:etc_meisai/application/usecase/route_map/reset_operator_colors_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_operator_color_uc.dart';
import 'package:etc_meisai/domain/entity/operator_color_entity.dart';
import 'package:etc_meisai/userinterface/route_map/operator_color_providers.dart';
import 'package:etc_meisai/userinterface/settings/operator_color_section.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

/// The section alone, with the colors on memory.
Future<void> _show(WidgetTester tester, FakeOperatorColorIF store) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Not const, so that the constructors count as run.
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        listOperatorColorsUCProvider.overrideWithValue(
          ListOperatorColorsUC(operatorColors: store),
        ),
        saveOperatorColorUCProvider.overrideWithValue(
          SaveOperatorColorUC(operatorColors: store),
        ),
        resetOperatorColorsUCProvider.overrideWithValue(
          ResetOperatorColorsUC(operatorColors: store),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: OperatorColorSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _tile(String operator) =>
    find.byKey(ValueKey('operator-color-$operator'));

Color _swatchOf(WidgetTester tester, String operator) => tester
    .widget<CircleAvatar>(
      find.descendant(of: _tile(operator), matching: find.byType(CircleAvatar)),
    )
    .backgroundColor!;

/// Taps a color of the palette.
Future<void> _pick(WidgetTester tester, int color) async {
  await tester.tap(find.byKey(ValueKey('palette-${color.toRadixString(16)}')));
  await tester.pump();
}

Color _preview(WidgetTester tester) =>
    ((tester
                .widget<Container>(
                  find.byKey(const ValueKey('operator-color-preview')),
                )
                .decoration!
            as BoxDecoration)
        .color)!;

void main() {
  testWidgets('lists every operator with its default color', (tester) async {
    await _show(tester, FakeOperatorColorIF());

    expect(find.text(SettingsStrings.operatorColorSection), findsOneWidget);
    for (final name in knownOperators) {
      expect(_tile(name), findsOneWidget);
      expect(_swatchOf(tester, name), Color(defaultOperatorColors[name]!));
    }
    expect(
      find.text(SettingsStrings.operatorColorDefault),
      findsNWidgets(knownOperators.length),
    );
    expect(find.text(SettingsStrings.operatorColorChanged), findsNothing);
    // There is nothing to take back.
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              SettingsStrings.operatorColorResetAll,
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('chooses a color from the palette, and stores it', (
    tester,
  ) async {
    final store = FakeOperatorColorIF();
    await _show(tester, store);

    await tester.tap(_tile('阪神高速道路'));
    await tester.pumpAndSettle();
    // The dialog starts with the color in use.
    expect(_preview(tester), const Color(0xFFD32F2F));
    // Nothing is chosen yet, so there is nothing to save.
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(
              FilledButton,
              SettingsStrings.operatorColorSave,
            ),
          )
          .onPressed,
      isNull,
    );
    await _pick(tester, 0xFF1976D2);
    expect(_preview(tester), const Color(0xFF1976D2));
    expect(find.byIcon(Icons.check), findsOneWidget);
    // A dark color gets a white mark, a light one a black mark.
    await _pick(tester, 0xFFFBC02D);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await _pick(tester, 0xFF1976D2);
    await tester.tap(find.text(SettingsStrings.operatorColorSave));
    await tester.pumpAndSettle();

    expect(store.stored.single.operatorName, '阪神高速道路');
    expect(store.stored.single.color, 0xFF1976D2);
    expect(_swatchOf(tester, '阪神高速道路'), const Color(0xFF1976D2));
    expect(find.text(SettingsStrings.operatorColorChanged), findsOneWidget);
  });

  testWidgets('stores nothing when the dialog is cancelled', (tester) async {
    final store = FakeOperatorColorIF();
    await _show(tester, store);

    await tester.tap(_tile('NEXCO東日本'));
    await tester.pumpAndSettle();
    await _pick(tester, 0xFF1976D2);
    await tester.tap(find.text(SettingsStrings.operatorColorCancel));
    await tester.pumpAndSettle();

    expect(store.stored, isEmpty);
    expect(
      _swatchOf(tester, 'NEXCO東日本'),
      Color(defaultOperatorColors['NEXCO東日本']!),
    );
  });

  testWidgets('can take back only the color of one operator', (tester) async {
    final store = FakeOperatorColorIF()
      ..stored.addAll(const [
        OperatorColorEntity(operatorName: 'NEXCO東日本', color: 0xFF000001),
        OperatorColorEntity(operatorName: '首都高速道路', color: 0xFF000002),
      ]);
    await _show(tester, store);
    expect(find.text(SettingsStrings.operatorColorChanged), findsNWidgets(2));

    await tester.tap(_tile('NEXCO東日本'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SettingsStrings.operatorColorReset));
    await tester.pumpAndSettle();

    expect(store.stored.map((c) => c.operatorName), ['首都高速道路']);
    expect(
      _swatchOf(tester, 'NEXCO東日本'),
      Color(defaultOperatorColors['NEXCO東日本']!),
    );
  });

  testWidgets('cannot take back a color that is the default', (tester) async {
    await _show(tester, FakeOperatorColorIF());

    await tester.tap(_tile('NEXCO東日本'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, SettingsStrings.operatorColorReset),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('takes back every color at once', (tester) async {
    final store = FakeOperatorColorIF()
      ..stored.addAll(const [
        OperatorColorEntity(operatorName: 'NEXCO東日本', color: 0xFF000001),
        OperatorColorEntity(operatorName: '首都高速道路', color: 0xFF000002),
      ]);
    await _show(tester, store);

    await tester.tap(find.text(SettingsStrings.operatorColorResetAll));
    await tester.pumpAndSettle();

    expect(store.stored, isEmpty);
    expect(find.text(SettingsStrings.operatorColorChanged), findsNothing);
  });

  testWidgets('says so when a color could not be stored', (tester) async {
    final store = FakeOperatorColorIF();
    await _show(tester, store);
    store.error = StateError('x');

    await tester.tap(_tile('NEXCO東日本'));
    await tester.pumpAndSettle();
    await _pick(tester, 0xFF1976D2);
    await tester.tap(find.text(SettingsStrings.operatorColorSave));
    await tester.pump();

    expect(find.text(SettingsStrings.operatorColorSaveFailed), findsOneWidget);
  });

  testWidgets('says so when the colors cannot be read', (tester) async {
    final store = FakeOperatorColorIF()..error = StateError('x');

    await _show(tester, store);

    expect(find.text(SettingsStrings.operatorColorLoadFailed), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
}
