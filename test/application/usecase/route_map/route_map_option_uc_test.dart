import 'package:etc_meisai/application/usecase/route_map/list_route_map_options_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_route_map_option_uc.dart';
import 'package:etc_meisai/domain/entity/route_map_option_entity.dart';
import 'package:etc_meisai/domain/value/route_map_option_value.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  test('finds an option by its code', () {
    for (final option in RouteMapOptionValue.values) {
      expect(RouteMapOptionValue.fromCode(option.code), option);
    }
    expect(RouteMapOptionValue.fromCode('none'), isNull);
  });

  group('ListRouteMapOptionsUC', () {
    test('gives the default when the user has not set a number', () async {
      final options = await ListRouteMapOptionsUC(
        routeMapOptions: FakeRouteMapOptionIF(),
      ).execute();

      expect(options.map((o) => o.option), RouteMapOptionValue.values);
      expect(options.single.value, 4);
    });

    test('gives what the user set', () async {
      final store = FakeRouteMapOptionIF()
        ..stored.addAll(const [
          RouteMapOptionEntity(optionCode: 'lineWidth', value: 7),
          // An option this version does not know is left out.
          RouteMapOptionEntity(optionCode: 'future', value: 1),
        ]);

      final options = await ListRouteMapOptionsUC(
        routeMapOptions: store,
      ).execute();

      expect(options.single.value, 7);
    });

    test('brings a value out of the range into it', () async {
      for (final (stored, expected) in [(0, 2), (99, 10), (-5, 2)]) {
        final store = FakeRouteMapOptionIF()
          ..stored.add(
            RouteMapOptionEntity(optionCode: 'lineWidth', value: stored),
          );

        final options = await ListRouteMapOptionsUC(
          routeMapOptions: store,
        ).execute();

        expect(options.single.value, expected);
      }
    });

    test('passes on a failure to read', () async {
      final store = FakeRouteMapOptionIF()..error = StateError('x');

      expect(
        ListRouteMapOptionsUC(routeMapOptions: store).execute(),
        throwsStateError,
      );
    });
  });

  group('SaveRouteMapOptionUC', () {
    test(
      'stores the number, and replaces the one of the same option',
      () async {
        final store = FakeRouteMapOptionIF();
        final uc = SaveRouteMapOptionUC(routeMapOptions: store);

        await uc.execute(option: RouteMapOptionValue.lineWidth, value: 6);
        await uc.execute(option: RouteMapOptionValue.lineWidth, value: 8);

        expect(store.stored, hasLength(1));
        expect(store.stored.single.optionCode, 'lineWidth');
        expect(store.stored.single.value, 8);
      },
    );

    test('brings a value out of the range into it', () async {
      final store = FakeRouteMapOptionIF();
      final uc = SaveRouteMapOptionUC(routeMapOptions: store);

      await uc.execute(option: RouteMapOptionValue.lineWidth, value: 100);
      expect(store.stored.single.value, 10);
      await uc.execute(option: RouteMapOptionValue.lineWidth, value: 0);
      expect(store.stored.single.value, 2);
    });

    test('passes on a failure to store', () async {
      final store = FakeRouteMapOptionIF()..error = StateError('x');

      expect(
        SaveRouteMapOptionUC(
          routeMapOptions: store,
        ).execute(option: RouteMapOptionValue.lineWidth, value: 5),
        throwsStateError,
      );
    });
  });
}
