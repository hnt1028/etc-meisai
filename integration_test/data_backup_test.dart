import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fixtures/statement_fixture.dart';
import '../test/support/app_harness.dart';

/// The backup (docs/backup-format.md) from the settings screen down to the
/// database, wired like lib/main.dart: export, delete everything, and read the
/// file again.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));

  tearDown(() => database.close());

  /// Every table as plain values, to compare before and after.
  Future<Map<String, Object?>> snapshot() async {
    String two(DateTime? t) => t?.toIso8601String() ?? '-';
    final lines = await database.select(database.statementLines).get();
    final mappings = await database.select(database.icMappings).get();
    final positions = await database.select(database.icPositions).get();
    return {
      'lines': [
        for (final l in lines)
          [
            l.id,
            l.duplicateKey,
            two(l.entranceAt),
            two(l.exitAt),
            l.entranceIc,
            l.exitIc,
            l.fare,
            l.vehicleNumber,
            two(l.enteredEntranceAt),
            l.enteredEntranceIc,
            l.status.name,
            l.discountTypes,
          ].join('|'),
      ]..sort(),
      'mappings': [for (final m in mappings) '${m.icName}|${m.pointId}'],
      'positions': [
        for (final p in positions) '${p.icName}|${p.latitude}|${p.longitude}',
      ],
    };
  }

  Future<void> scrollTo(WidgetTester tester, String text) async {
    // From the top of the list, whichever way the target is.
    await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(text), 100);
    final navTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
    final finder = find.text(text);
    for (var i = 0; i < 10 && tester.getCenter(finder).dy > navTop - 24; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -150));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapSetting(WidgetTester tester, String text) async {
    await scrollTo(tester, text);
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('a backup gives back everything, as it was', (tester) async {
    final saved = <String, Uint8List>{};
    Uint8List? toRead;
    // The first line has no vehicle number and no entrance, as in the CSV.
    final blank = [...StatementFixture.row(note: '確認中')];
    for (final index in [0, 1, 4, 12]) {
      blank[index] = '';
    }
    await pumpApp(
      tester,
      database: database,
      picker: () async => StatementFixture.csv([
        StatementFixture.header,
        StatementFixture.row(exitIc: 'テスト東ＩＣ'),
        blank,
      ]),
      backupSaver: (name, bytes) async {
        saved[name] = bytes;
        return true;
      },
      backupPicker: () async => toRead,
    );

    // Data of every kind: lines, one the user filled in, a mapping, a position.
    await openSettings(tester);
    await tester.tap(find.text(SettingsStrings.importButton));
    await tester.pumpAndSettle();
    await database.customStatement(
      "UPDATE statement_lines SET entered_entrance_ic = 'テスト北', "
      'vehicle_number = 4321 WHERE entrance_ic IS NULL',
    );
    await database.customStatement(
      "INSERT INTO ic_mappings (ic_name, point_id) VALUES ('テスト北ＩＣ', 'T-N1')",
    );
    await database.customStatement(
      "INSERT INTO ic_positions (ic_name, latitude, longitude) VALUES ('テスト南ＩＣ', 35.4, 139.4)",
    );
    final before = await snapshot();
    expect((before['lines'] as List), hasLength(2));

    // Export: the file is saved under a name of the time.
    await tapSetting(tester, SettingsStrings.exportButton);
    expect(saved, hasLength(1));
    expect(
      saved.keys.single,
      matches(r'^etc-meisai-backup-\d{8}-\d{4}\.json$'),
    );
    expect(find.text(SettingsStrings.exported(2, 1, 1)), findsOneWidget);
    final file = jsonDecode(utf8.decode(saved.values.single)) as Map;
    expect(file['format'], 'etc-meisai-backup');
    expect((file['statementLines'] as List), hasLength(2));

    // Delete everything: the three tables are empty, and so is the list.
    await tapSetting(tester, SettingsStrings.deleteAllButton);
    await tester.tap(find.text(SettingsStrings.deleteConfirmOk));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.deletedAll), findsOneWidget);
    final empty = await snapshot();
    expect(empty['lines'], isEmpty);
    expect(empty['mappings'], isEmpty);
    expect(empty['positions'], isEmpty);
    await openTab(tester, AppStrings.statementsTab);
    expect(find.text(StatementListStrings.emptyNoData), findsOneWidget);

    // Read the file: a warning first, then everything is back, as it was.
    toRead = saved.values.single;
    await openSettings(tester);
    await tapSetting(tester, SettingsStrings.restoreButton);
    expect(find.text(SettingsStrings.restoreConfirmMessage), findsOneWidget);
    await tester.tap(find.text(SettingsStrings.restoreConfirmOk));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.restored(2, 1, 1)), findsOneWidget);
    expect(await snapshot(), before);

    // The same CSV again is not added a second time, even for the line whose
    // entrance the user filled in (the duplicate key came back as it was).
    await scrollTo(tester, SettingsStrings.importButton);
    await tester.tap(find.text(SettingsStrings.importButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('追加 0 件'), findsOneWidget);
    expect(((await snapshot())['lines'] as List), hasLength(2));
    await openTab(tester, AppStrings.statementsTab);
    expect(find.text(StatementListStrings.emptyNoData), findsNothing);
  });

  testWidgets('reading replaces the data, and a wrong file changes nothing', (
    tester,
  ) async {
    Uint8List? toRead;
    await pumpApp(
      tester,
      database: database,
      picker: () async => StatementFixture.threeRows(),
      backupPicker: () async => toRead,
    );
    await openSettings(tester);
    await tester.tap(find.text(SettingsStrings.importButton));
    await tester.pumpAndSettle();
    final before = await snapshot();
    expect((before['lines'] as List), hasLength(3));

    // A file that is not a backup: the message says so, and the three lines
    // stay.
    toRead = Uint8List.fromList(utf8.encode('{"hello": 1}'));
    await tapSetting(tester, SettingsStrings.restoreButton);
    await tester.tap(find.text(SettingsStrings.restoreConfirmOk));
    await tester.pumpAndSettle();
    expect(find.textContaining('読み込めませんでした'), findsOneWidget);
    expect(find.textContaining('データは変わっていません'), findsOneWidget);
    expect(await snapshot(), before);

    // A backup of one line replaces the three, and does not add to them.
    toRead = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': 'etc-meisai-backup',
          'version': 1,
          'exportedAt': '2026-11-16T12:00:00.000',
          'statementLines': [
            {
              'id': 'only',
              'duplicateKey': 'only-key',
              'entranceAt': null,
              'exitAt': '2026-02-01T10:00:00.000',
              'entranceIc': null,
              'exitIc': 'テスト西ＩＣ',
              'grossFare': null,
              'etcDiscount': null,
              'fare': 500,
              'fareAfterRebate': 0,
              'postpaidFare': 500,
              'vehicleType': 1,
              'vehicleNumber': null,
              'enteredEntranceAt': null,
              'enteredEntranceIc': null,
              'cardNumber': '0000-****-0009',
              'status': 'confirmed',
              'discountTypes': <String>[],
            },
          ],
          'icMappings': <Object>[],
          'icPositions': <Object>[],
        }),
      ),
    );
    await tapSetting(tester, SettingsStrings.restoreButton);
    await tester.tap(find.text(SettingsStrings.restoreConfirmOk));
    await tester.pumpAndSettle();

    expect(find.text(SettingsStrings.restored(1, 0, 0)), findsOneWidget);
    final after = await snapshot();
    expect((after['lines'] as List), hasLength(1));
    expect((after['lines'] as List).single, contains('only-key'));
    await openTab(tester, AppStrings.statementsTab);
    expect(find.text('- → テスト西ＩＣ'), findsOneWidget);
  });
}
