import 'package:etc_meisai/application/dto/operator_color_dto.dart';
import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/get_line_route_uc.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/userinterface/route_map/operator_color_providers.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_providers.dart';
import 'package:etc_meisai/userinterface/statements/line_route_map.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

StatementLineDTO _line() => StatementLineDTO(
  entranceAt: DateTime(2026, 1, 10, 8),
  exitAt: DateTime(2026, 1, 10, 9),
  entranceIc: '入口',
  exitIc: '出口',
  grossFare: null,
  etcDiscount: null,
  fare: 100,
  fareAfterRebate: 100,
  postpaidFare: 100,
  vehicleType: VehicleTypeValue.standard,
  vehicleTypeName: '普通車',
  vehicleNumber: 1,
  cardNumberSuffix: '0001',
  status: ConfirmationStatusValue.confirmed,
  discountTypes: const [],
);

/// The map of a line on the roads of NEXCO東日本, with [colors] in use.
Future<List<Color>> _lineColors(
  WidgetTester tester,
  Future<List<OperatorColorDTO>> Function() colors,
) async {
  final master = FakeIcMasterIF(
    [
      fakeIcPoint(name: '入口', routeNames: const ['東北自動車道']),
      fakeIcPoint(name: '出口', routeNames: const ['東北自動車道']),
    ],
    links: const [IcLinkEntity(fromId: 'id-入口', toId: 'id-出口', meters: 1000)],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        getLineRouteUCProvider.overrideWithValue(
          GetLineRouteUC(
            icMaster: master,
            icMappings: FakeIcMappingIF(),
            icPositions: FakeIcPositionIF(),
          ),
        ),
        operatorColorsProvider.overrideWith((ref) => colors()),
        tileLayerProvider.overrideWithValue(const SizedBox.shrink()),
      ],
      child: MaterialApp(
        home: Scaffold(body: LineRouteMap(line: _line())),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return [
    for (final p
        in tester.widget<PolylineLayer>(find.byType(PolylineLayer)).polylines)
      p.color,
  ];
}

void main() {
  testWidgets('draws the line in the color the user chose', (tester) async {
    final colors = await _lineColors(
      tester,
      () async => const [
        OperatorColorDTO(
          operatorName: 'NEXCO東日本',
          color: 0xFF102030,
          isDefault: false,
        ),
      ],
    );

    expect(colors, [const Color(0xFF102030).withValues(alpha: 0.85)]);
  });

  testWidgets('draws the default color when the colors cannot be read', (
    tester,
  ) async {
    final colors = await _lineColors(tester, () async => throw StateError('x'));

    // The default color of NEXCO東日本, with its alpha.
    expect(colors, [const Color(0xFF2E9E4F).withValues(alpha: 0.85)]);
  });

  test('the use cases of the colors are given by the app', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(listOperatorColorsUCProvider),
      throwsA(anything),
    );
    expect(
      () => container.read(saveOperatorColorUCProvider),
      throwsA(anything),
    );
    expect(
      () => container.read(resetOperatorColorsUCProvider),
      throwsA(anything),
    );
  });
}
