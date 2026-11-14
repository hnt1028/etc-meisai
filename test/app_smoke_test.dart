import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etc_meisai/userinterface/app.dart';

void main() {
  testWidgets('app starts with a MaterialApp', (tester) async {
    await tester.pumpWidget(const EtcMeisaiApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
