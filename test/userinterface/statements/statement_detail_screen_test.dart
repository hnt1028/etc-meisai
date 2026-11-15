import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_screen.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StatementLineDTO _line({
  DateTime? entranceAt,
  String? entranceIc = 'A-IC',
  int? grossFare = 1200,
  int? etcDiscount = -240,
  ConfirmationStatusValue status = ConfirmationStatusValue.confirmed,
  List<String> discountTypes = const ['深夜割引', '休日割引'],
}) {
  return StatementLineDTO(
    entranceAt: entranceAt ?? DateTime(2026, 1, 10, 8, 30),
    exitAt: DateTime(2026, 1, 10, 9, 15),
    entranceIc: entranceIc,
    exitIc: 'B-IC',
    grossFare: grossFare,
    etcDiscount: etcDiscount,
    fare: 960,
    fareAfterRebate: 100,
    postpaidFare: 860,
    vehicleType: VehicleTypeValue.standard,
    vehicleNumber: 1234,
    cardNumberSuffix: '0001',
    status: status,
    discountTypes: discountTypes,
  );
}

/// The screen is a long list, so the test window is made tall enough to build
/// every field.
Future<void> _show(WidgetTester tester, StatementLineDTO? line) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: StatementDetailScreen(line: line)));
}

void main() {
  testWidgets('shows every field', (tester) async {
    await _show(tester, _line());

    for (final text in [
      StatementDetailStrings.title,
      '2026/01/10 08:30',
      '2026/01/10 09:15',
      'A-IC',
      'B-IC',
      '1,200円',
      '-240円',
      '960円',
      '100円',
      '860円',
      '普通車',
      '1234',
      '**** 0001',
      StatementDetailStrings.confirmed,
      '深夜割引・休日割引',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text(StatementDetailStrings.notFound), findsNothing);
  });

  testWidgets('shows - for a blank entrance and for no discount', (
    tester,
  ) async {
    final line = StatementLineDTO(
      entranceAt: null,
      exitAt: DateTime(2026, 1, 10, 9, 15),
      entranceIc: null,
      exitIc: 'B-IC',
      grossFare: null,
      etcDiscount: null,
      fare: 960,
      fareAfterRebate: 0,
      postpaidFare: 960,
      vehicleType: VehicleTypeValue.standard,
      vehicleNumber: 1234,
      cardNumberSuffix: '0001',
      status: ConfirmationStatusValue.confirmed,
      discountTypes: const [],
    );
    await _show(tester, line);

    // Entrance date and time, entrance IC, gross fare and ETC discount.
    expect(find.text(StatementDetailStrings.blank), findsNWidgets(4));
    expect(find.text(StatementDetailStrings.none), findsOneWidget);
  });

  testWidgets('shows a pending statement line as pending', (tester) async {
    await _show(tester, _line(status: ConfirmationStatusValue.pending));

    expect(find.text(StatementDetailStrings.pending), findsOneWidget);
    expect(find.text(StatementDetailStrings.confirmed), findsNothing);
  });

  testWidgets('says so when opened without a statement line', (tester) async {
    await _show(tester, null);

    expect(find.text(StatementDetailStrings.notFound), findsOneWidget);
    expect(find.text('B-IC'), findsNothing);
  });
}
