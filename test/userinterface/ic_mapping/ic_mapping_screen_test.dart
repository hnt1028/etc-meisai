import 'dart:async';

import 'package:etc_meisai/application/usecase/ic_mapping/delete_ic_mapping_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/list_ic_matches_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/save_ic_mapping_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/search_ic_points_uc.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_providers.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_strings.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

/// Everything the screen reads, kept in memory so that a test can change it.
class _World {
  _World() {
    lines.stored.addAll([
      fakeStatementLine(exitIc: '東', entranceIc: '北'),
      fakeStatementLine(exitIc: '東', entranceIc: '北'),
      fakeStatementLine(exitIc: '本線', entranceIc: '北'),
    ]);
  }

  final lines = FakeStatementLineIF();
  final mappings = FakeIcMappingIF();
  final master = FakeIcMasterIF([
    fakeIcPoint(
      id: 'n1',
      name: '北',
      routeNames: const ['北線'],
      latitude: 35.1234,
      longitude: 139.5678,
    ),
    fakeIcPoint(id: 'n2', name: '北', routeNames: const ['別の北線']),
    fakeIcPoint(id: 'e', name: '東'),
    fakeIcPoint(
      id: 'h',
      name: '幹線IC',
      kind: IcKindValue.smartInterchange,
      routeNames: const ['本線道', '支線'],
    ),
  ]);

  Widget app() => ProviderScope(
    overrides: [
      listStatementLinesUCProvider.overrideWithValue(
        fakeListUC(lines, mappings: mappings),
      ),
      listIcMatchesUCProvider.overrideWithValue(
        ListIcMatchesUC(
          statementLines: lines,
          icMaster: master,
          icMappings: mappings,
        ),
      ),
      searchIcPointsUCProvider.overrideWithValue(
        SearchIcPointsUC(icMaster: master),
      ),
      saveIcMappingUCProvider.overrideWithValue(
        SaveIcMappingUC(icMaster: master, icMappings: mappings),
      ),
      deleteIcMappingUCProvider.overrideWithValue(
        DeleteIcMappingUC(icMappings: mappings),
      ),
    ],
    // ignore: prefer_const_constructors
    child: EtcMeisaiApp(),
  );
}

Future<void> _open(WidgetTester tester, _World world) async {
  await tester.pumpWidget(world.app());
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppStrings.settingsTab));
  await tester.pumpAndSettle();
  // The button is far down the settings, which are a long list.
  await tester.scrollUntilVisible(
    find.text(SettingsStrings.icMappingButton),
    100,
  );
  await tester.tap(find.text(SettingsStrings.icMappingButton));
  await tester.pumpAndSettle();
}

Finder _text(String text) => find.text(text);

void main() {
  testWidgets('lists the IC names that need a choice, the most used first', (
    tester,
  ) async {
    await _open(tester, _World());

    expect(_text(IcMappingStrings.title), findsOneWidget);
    expect(_text(IcMappingStrings.ambiguous(3)), findsOneWidget);
    expect(_text(IcMappingStrings.unknown(1)), findsOneWidget);
    expect(
      tester.getTopLeft(_text('北')).dy,
      lessThan(tester.getTopLeft(_text('本線')).dy),
    );
    // 東 is matched, so it is not listed.
    expect(_text('東'), findsNothing);
    expect(_text(IcMappingStrings.noRegistered), findsOneWidget);
    expect(_text(IcMappingStrings.noUnresolved), findsNothing);
  });

  testWidgets('says so when nothing needs a choice', (tester) async {
    final world = _World()..lines.stored.clear();

    await _open(tester, world);

    expect(_text(IcMappingStrings.noUnresolved), findsOneWidget);
    expect(_text(IcMappingStrings.noRegistered), findsOneWidget);
  });

  testWidgets(
    'lets the user choose among the candidates of an ambiguous name',
    (tester) async {
      final world = _World();
      await _open(tester, world);

      await tester.tap(_text('北'));
      await tester.pumpAndSettle();

      expect(_text(IcMappingStrings.pickerTitle('北')), findsOneWidget);
      expect(
        _text(
          IcMappingStrings.pointDetail(
            kind: IcKindValue.generalInterchange,
            routeNames: const ['北線'],
            latitude: 35.1234,
            longitude: 139.5678,
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('北緯35.123 東経139.568'), findsOneWidget);

      await tester.tap(find.textContaining('別の北線'));
      await tester.pumpAndSettle();

      // The sheet is closed, the name is registered and no longer unresolved.
      expect(_text(IcMappingStrings.pickerTitle('北')), findsNothing);
      expect(world.mappings.stored.single.pointId, 'n2');
      expect(_text(IcMappingStrings.registeredLine('北', '北')), findsOneWidget);
      expect(_text('別の北線'), findsOneWidget);
      expect(_text(IcMappingStrings.ambiguous(3)), findsNothing);
      expect(_text(IcMappingStrings.noRegistered), findsNothing);
    },
  );

  testWidgets('lets the user search for the point of an unknown name', (
    tester,
  ) async {
    final world = _World();
    await _open(tester, world);

    await tester.tap(_text('本線'));
    await tester.pumpAndSettle();
    // No candidates, and nothing typed yet.
    expect(_text(IcMappingStrings.noResult), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ＩＣ');
    await tester.pumpAndSettle();
    expect(find.textContaining('スマートIC・本線道・支線'), findsOneWidget);

    await tester.tap(find.textContaining('スマートIC'));
    await tester.pumpAndSettle();

    expect(world.mappings.stored.single.icName, '本線');
    expect(world.mappings.stored.single.pointId, 'h');
    expect(
      _text(IcMappingStrings.registeredLine('本線', '幹線IC')),
      findsOneWidget,
    );
  });

  testWidgets('says so when the search finds nothing', (tester) async {
    await _open(tester, _World());
    await tester.tap(_text('本線'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '存在しない');
    await tester.pumpAndSettle();

    expect(_text(IcMappingStrings.noResult), findsOneWidget);
  });

  testWidgets('unlinks a registered mapping', (tester) async {
    final world = _World();
    world.mappings.stored.add(
      const IcMappingEntity(icName: '北', pointId: 'n1'),
    );
    await _open(tester, world);
    expect(_text(IcMappingStrings.registeredLine('北', '北')), findsOneWidget);
    expect(_text('北線'), findsOneWidget);

    await tester.tap(find.byTooltip(IcMappingStrings.unlink));
    await tester.pumpAndSettle();

    expect(world.mappings.stored, isEmpty);
    expect(_text(IcMappingStrings.noRegistered), findsOneWidget);
    expect(_text(IcMappingStrings.ambiguous(3)), findsOneWidget);
  });

  testWidgets('shows a registered mapping whose point is gone', (tester) async {
    final world = _World();
    world.mappings.stored.add(
      const IcMappingEntity(icName: '古い', pointId: 'gone'),
    );

    await _open(tester, world);

    expect(_text('古い'), findsOneWidget);
    expect(_text(IcMappingStrings.pointMissing), findsOneWidget);
  });

  testWidgets('shows a progress indicator while reading', (tester) async {
    final world = _World();
    await tester.pumpWidget(world.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.settingsTab));
    await tester.pumpAndSettle();
    // The button is far down the settings, which are a long list.
    await tester.scrollUntilVisible(
      find.text(SettingsStrings.icMappingButton),
      100,
    );

    final gate = Completer<void>();
    world.lines.readGate = gate.future;
    await tester.tap(find.text(SettingsStrings.icMappingButton));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(_text(IcMappingStrings.ambiguous(3)), findsOneWidget);
  });

  testWidgets('shows a failure without details, and reads again on request', (
    tester,
  ) async {
    final world = _World()..mappings.error = StateError('secret');
    await _open(tester, world);

    expect(_text(IcMappingStrings.loadFailed), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);

    world.mappings.error = null;
    await tester.tap(_text(IcMappingStrings.retry));
    await tester.pumpAndSettle();

    expect(_text(IcMappingStrings.loadFailed), findsNothing);
    expect(_text(IcMappingStrings.ambiguous(3)), findsOneWidget);
  });

  testWidgets('shows a failure of the search', (tester) async {
    final world = _World();
    await _open(tester, world);
    await tester.tap(_text('本線'));
    await tester.pumpAndSettle();

    world.master.error = StateError('secret');
    await tester.enterText(find.byType(TextField), '東');
    await tester.pumpAndSettle();

    expect(_text(IcMappingStrings.searchFailed), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('shows a failure to register, and keeps the sheet open', (
    tester,
  ) async {
    final world = _World();
    await _open(tester, world);
    await tester.tap(_text('北'));
    await tester.pumpAndSettle();

    world.mappings.error = StateError('secret');
    await tester.tap(find.textContaining('別の北線'));
    await tester.pumpAndSettle();

    expect(_text(IcMappingStrings.saveFailed), findsOneWidget);
    expect(_text(IcMappingStrings.pickerTitle('北')), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('shows a failure to unlink', (tester) async {
    final world = _World();
    world.mappings.stored.add(
      const IcMappingEntity(icName: '北', pointId: 'n1'),
    );
    await _open(tester, world);

    world.mappings.error = StateError('secret');
    await tester.tap(find.byTooltip(IcMappingStrings.unlink));
    await tester.pumpAndSettle();

    expect(_text(IcMappingStrings.deleteFailed), findsOneWidget);
  });

  testWidgets('goes back to the settings screen', (tester) async {
    await _open(tester, _World());

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(_text(SettingsStrings.icMappingButton), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: _text(IcMappingStrings.title),
      ),
      findsNothing,
    );
  });

  test('the use cases must be overridden', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    expect(() => c.read(listIcMatchesUCProvider), throwsA(anything));
    expect(() => c.read(searchIcPointsUCProvider), throwsA(anything));
    expect(() => c.read(saveIcMappingUCProvider), throwsA(anything));
    expect(() => c.read(deleteIcMappingUCProvider), throwsA(anything));
  });
}
