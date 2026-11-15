import 'package:drift/native.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_strings.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fixtures/statement_fixture.dart';
import '../test/support/app_harness.dart';

/// SCR-005 from the screen down to the database. The IC master is a fictional
/// one in which テスト北 has two points, so the IC has no position until the
/// user chooses one on the map.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));

  tearDown(() => database.close());

  /// The map waits for a possible double tap before it reports a tap.
  Future<void> tapMap(WidgetTester tester) async {
    // Away from the middle, where the marker of another IC is.
    await tester.tapAt(
      tester.getCenter(find.byType(FlutterMap)) + const Offset(120, 90),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  testWidgets('a position chosen on the map draws the lines, and can be '
      'removed again', (tester) async {
    await pumpApp(
      tester,
      database: database,
      picker: () async => StatementFixture.threeRows(),
    );
    await openSettings(tester);
    await tester.tap(find.text(SettingsStrings.importButton));
    await tester.pumpAndSettle();

    // テスト北ＩＣ has two points in the master, so no line can be drawn.
    await openTab(tester, AppStrings.routeMapTab);
    expect(find.text(RouteMapStrings.unlocatedBanner(1, 3)), findsOneWidget);
    expect(find.text('テスト東ＩＣ'), findsOneWidget);

    // The user chooses the position of テスト北ＩＣ on the map.
    await tester.tap(find.text(RouteMapStrings.specifyPosition));
    await tester.pumpAndSettle();
    await tester.tap(find.text('テスト北ＩＣ'));
    await tester.pumpAndSettle();
    expect(find.text(RouteMapStrings.picking('テスト北ＩＣ')), findsOneWidget);
    await tapMap(tester);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
    await tester.tap(find.text(RouteMapStrings.register));
    await tester.pumpAndSettle();

    // Now every line is drawn, and テスト北ＩＣ has a marker.
    expect(find.textContaining('位置不明'), findsNothing);
    expect(find.text('テスト北ＩＣ'), findsOneWidget);

    // The marker says that the position is the user's, and can be removed.
    await tester.tap(find.byKey(const ValueKey('marker-テスト北ＩＣ')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '${RouteMapStrings.positionLabel}: ${RouteMapStrings.positionSpecified}',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(RouteMapStrings.unspecify));
    await tester.pumpAndSettle();

    expect(find.text(RouteMapStrings.unlocatedBanner(1, 3)), findsOneWidget);
  });
}
