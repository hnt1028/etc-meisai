import 'dart:async';
import 'dart:typed_data';

import 'package:etc_meisai/application/usecase/route_map/list_operator_colors_uc.dart';
import 'package:etc_meisai/userinterface/route_map/operator_color_providers.dart';
import 'package:etc_meisai/application/usecase/settings/delete_all_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/export_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/domain/entity/app_data_entity.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

/// What the screen reads and writes, kept in memory so that a test can look.
class _World {
  _World({AppDataEntity? data, this.backup})
    : appData = FakeAppDataIF(data ?? _someData());

  final FakeAppDataIF appData;
  FakeBackupIF? backup;

  /// What the picker gives. Null: the user chose nothing.
  Uint8List? picked = Uint8List.fromList([9]);
  int pickCount = 0;

  /// What the saver was given.
  final saved = <(String, Uint8List)>[];

  /// What the saver says: false is the user choosing no place.
  bool saves = true;
  Object? saveError;

  static AppDataEntity _someData() => AppDataEntity(
    statementLines: [
      fakeRecord(id: 'a', duplicateKey: 'ka'),
      fakeRecord(id: 'b', duplicateKey: 'kb'),
    ],
    icMappings: const [IcMappingEntity(icName: '北', pointId: 'p')],
    icPositions: const [],
    operatorColors: const [],
  );

  Widget app() {
    final lines = FakeStatementLineIF();
    final format = backup ??= FakeBackupIF();
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
        exportDataUCProvider.overrideWithValue(
          ExportDataUC(
            appData: appData,
            backup: format,
            now: () => DateTime(2026, 11, 16, 12, 34),
          ),
        ),
        importDataUCProvider.overrideWithValue(
          ImportDataUC(appData: appData, backup: format),
        ),
        deleteAllDataUCProvider.overrideWithValue(
          DeleteAllDataUC(appData: appData),
        ),
        listStatementLinesUCProvider.overrideWithValue(fakeListUC(lines)),
        backupPickerProvider.overrideWithValue(() async {
          pickCount++;
          return picked;
        }),
        listOperatorColorsUCProvider.overrideWithValue(
          ListOperatorColorsUC(operatorColors: FakeOperatorColorIF()),
        ),
        backupSaverProvider.overrideWithValue((name, bytes) async {
          if (saveError != null) throw saveError!;
          if (saves) saved.add((name, bytes));
          return saves;
        }),
      ],
      // ignore: prefer_const_constructors
      child: EtcMeisaiApp(),
    );
  }
}

Finder _text(String text) => find.text(text);

/// The settings are a long list, so the window is made tall enough to build
/// every button.
Future<void> _open(WidgetTester tester, _World world) async {
  tester.view.physicalSize = const Size(800, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(world.app());
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppStrings.settingsTab));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(_text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the backup and the deletion sections', (tester) async {
    await _open(tester, _World());

    expect(_text(SettingsStrings.backupSection), findsOneWidget);
    expect(_text(SettingsStrings.exportButton), findsOneWidget);
    expect(_text(SettingsStrings.exportNote), findsOneWidget);
    expect(_text(SettingsStrings.restoreButton), findsOneWidget);
    expect(_text(SettingsStrings.deleteButton), findsOneWidget);
    expect(_text(SettingsStrings.deleteAllButton), findsOneWidget);
    // Nothing is reported before something is done.
    expect(find.textContaining('書き出しました'), findsNothing);
    expect(find.textContaining('読み込みました'), findsNothing);
    expect(find.textContaining('読み込めませんでした'), findsNothing);
  });

  group('export', () {
    testWidgets('saves the file under its name, and says what was saved', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);

      await _tap(tester, SettingsStrings.exportButton);

      expect(world.saved, hasLength(1));
      expect(world.saved.single.$1, 'etc-meisai-backup-20261116-1234.json');
      expect(world.saved.single.$2, Uint8List.fromList([1, 2, 3]));
      expect(_text(SettingsStrings.exported(2, 1, 0)), findsOneWidget);
    });

    testWidgets('says nothing when the user chose no place to save', (
      tester,
    ) async {
      final world = _World()..saves = false;
      await _open(tester, world);

      await _tap(tester, SettingsStrings.exportButton);

      expect(world.saved, isEmpty);
      expect(find.textContaining('書き出'), findsNWidgets(2));
      expect(find.textContaining('書き出しました'), findsNothing);
      expect(_text(SettingsStrings.exportFailed), findsNothing);
    });

    testWidgets('says so when the data cannot be read, without details', (
      tester,
    ) async {
      final world = _World();
      world.appData.readError = StateError('secret 1234');
      await _open(tester, world);

      await _tap(tester, SettingsStrings.exportButton);

      expect(_text(SettingsStrings.exportFailed), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      expect(world.saved, isEmpty);
    });

    testWidgets('says so when the file cannot be saved', (tester) async {
      final world = _World()..saveError = StateError('disk');
      await _open(tester, world);

      await _tap(tester, SettingsStrings.exportButton);

      expect(_text(SettingsStrings.exportFailed), findsOneWidget);
    });
  });

  group('restore', () {
    testWidgets('warns first, and keeps everything when cancelled', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);

      await _tap(tester, SettingsStrings.restoreButton);
      expect(_text(SettingsStrings.restoreConfirmMessage), findsOneWidget);
      await _tap(tester, SettingsStrings.deleteConfirmCancel);

      expect(world.pickCount, 0);
      expect(world.appData.replaceCount, 0);
      expect(world.appData.data.statementLines, hasLength(2));
    });

    testWidgets('replaces everything with the file once confirmed', (
      tester,
    ) async {
      final world = _World(
        backup: FakeBackupIF(
          decoded: AppDataEntity(
            statementLines: [fakeRecord(id: 'new', duplicateKey: 'kn')],
            icMappings: const [],
            icPositions: const [],
            operatorColors: const [],
          ),
        ),
      );
      await _open(tester, world);

      await _tap(tester, SettingsStrings.restoreButton);
      await _tap(tester, SettingsStrings.restoreConfirmOk);

      expect(world.pickCount, 1);
      expect(world.appData.replaceCount, 1);
      expect(world.appData.data.statementLines.single.id, 'new');
      expect(_text(SettingsStrings.restored(1, 0, 0)), findsOneWidget);
    });

    testWidgets('does nothing when no file is chosen', (tester) async {
      final world = _World()..picked = null;
      await _open(tester, world);

      await _tap(tester, SettingsStrings.restoreButton);
      await _tap(tester, SettingsStrings.restoreConfirmOk);

      expect(world.pickCount, 1);
      expect(world.appData.replaceCount, 0);
      expect(world.appData.data.statementLines, hasLength(2));
      expect(find.textContaining('読み込めませんでした'), findsNothing);
      expect(find.textContaining('読み込みました'), findsNothing);
    });

    testWidgets('says what is wrong with the file, and changes nothing', (
      tester,
    ) async {
      final world = _World(
        backup: FakeBackupIF(error: const FormatException('「fare」が正しくありません')),
      );
      await _open(tester, world);

      await _tap(tester, SettingsStrings.restoreButton);
      await _tap(tester, SettingsStrings.restoreConfirmOk);

      expect(
        _text(SettingsStrings.restoreFailed('「fare」が正しくありません')),
        findsOneWidget,
      );
      expect(world.appData.replaceCount, 0);
      expect(world.appData.data.statementLines, hasLength(2));
    });

    testWidgets('says so when the replacement fails, without details', (
      tester,
    ) async {
      final world = _World();
      world.appData.replaceError = StateError('secret 4321');
      await _open(tester, world);

      await _tap(tester, SettingsStrings.restoreButton);
      await _tap(tester, SettingsStrings.restoreConfirmOk);

      expect(_text(SettingsStrings.restoreUnexpected), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      expect(world.appData.data.statementLines, hasLength(2));
    });

    testWidgets('shows a progress bar and locks the buttons while it works', (
      tester,
    ) async {
      final world = _World();
      final gate = Completer<void>();
      world.appData.gate = gate.future;
      await _open(tester, world);

      await _tap(tester, SettingsStrings.restoreButton);
      await tester.tap(_text(SettingsStrings.restoreConfirmOk));
      await tester.pump();
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      for (final label in [
        SettingsStrings.exportButton,
        SettingsStrings.restoreButton,
        SettingsStrings.deleteButton,
        SettingsStrings.deleteAllButton,
      ]) {
        expect(
          tester
              .widget<ButtonStyleButton>(
                find.ancestor(
                  of: _text(label),
                  matching: find.bySubtype<ButtonStyleButton>(),
                ),
              )
              .onPressed,
          isNull,
          reason: label,
        );
      }

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('delete all data', () {
    testWidgets('warns first, and keeps everything when cancelled', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);

      await _tap(tester, SettingsStrings.deleteAllButton);
      expect(_text(SettingsStrings.deleteAllConfirmMessage), findsOneWidget);
      await _tap(tester, SettingsStrings.deleteConfirmCancel);

      expect(world.appData.deleteCount, 0);
      expect(world.appData.data.statementLines, hasLength(2));
    });

    testWidgets('deletes everything once confirmed', (tester) async {
      final world = _World();
      await _open(tester, world);

      await _tap(tester, SettingsStrings.deleteAllButton);
      await _tap(tester, SettingsStrings.deleteConfirmOk);

      expect(world.appData.deleteCount, 1);
      expect(world.appData.data.statementLines, isEmpty);
      expect(world.appData.data.icMappings, isEmpty);
      expect(_text(SettingsStrings.deletedAll), findsOneWidget);
    });

    testWidgets('says so when it fails, and keeps the data', (tester) async {
      final world = _World();
      world.appData.deleteError = StateError('secret');
      await _open(tester, world);

      await _tap(tester, SettingsStrings.deleteAllButton);
      await _tap(tester, SettingsStrings.deleteConfirmOk);

      expect(_text(SettingsStrings.deleteAllFailed), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      expect(world.appData.data.statementLines, hasLength(2));
    });
  });

  testWidgets('the use cases and the file hooks must be overridden', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(() => container.read(exportDataUCProvider), throwsA(anything));
    expect(() => container.read(importDataUCProvider), throwsA(anything));
    expect(() => container.read(deleteAllDataUCProvider), throwsA(anything));
    // The file hooks have a default: the system screens.
    expect(container.read(backupPickerProvider), isNotNull);
    expect(container.read(backupSaverProvider), isNotNull);
  });
}
