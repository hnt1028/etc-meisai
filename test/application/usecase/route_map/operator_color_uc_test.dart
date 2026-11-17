import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/application/usecase/route_map/list_operator_colors_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/operator_default_colors.dart';
import 'package:etc_meisai/application/usecase/route_map/reset_operator_colors_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_operator_color_uc.dart';
import 'package:etc_meisai/domain/entity/operator_color_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('defaultOperatorColors', () {
    test('has one opaque color for every operator of the table', () {
      expect(defaultOperatorColors.keys.toSet(), knownOperators.toSet());
      for (final color in defaultOperatorColors.values) {
        expect(color >> 24, 0xFF);
      }
    });
  });

  group('ListOperatorColorsUC', () {
    test('gives the defaults when the user chose nothing', () async {
      final store = FakeOperatorColorIF();

      final colors = await ListOperatorColorsUC(
        operatorColors: store,
      ).execute();

      expect(colors.map((c) => c.operatorName), knownOperators);
      expect(colors.every((c) => c.isDefault), isTrue);
      for (final c in colors) {
        expect(c.color, defaultOperatorColors[c.operatorName]);
      }
    });

    test(
      'gives the color the user chose, and the defaults of the rest',
      () async {
        final store = FakeOperatorColorIF()
          ..stored.add(
            const OperatorColorEntity(
              operatorName: '首都高速道路',
              color: 0xFF010203,
            ),
          );

        final colors = await ListOperatorColorsUC(
          operatorColors: store,
        ).execute();

        final shuto = colors.firstWhere((c) => c.operatorName == '首都高速道路');
        expect(shuto.color, 0xFF010203);
        expect(shuto.isDefault, isFalse);
        expect(colors.where((c) => c.isDefault), hasLength(colors.length - 1));
      },
    );

    test('ignores a color of an operator that is not in the table', () async {
      final store = FakeOperatorColorIF()
        ..stored.add(
          const OperatorColorEntity(operatorName: '知らない', color: 0xFF000001),
        );

      final colors = await ListOperatorColorsUC(
        operatorColors: store,
      ).execute();

      expect(colors.map((c) => c.operatorName), knownOperators);
      expect(colors.every((c) => c.isDefault), isTrue);
    });

    test('passes on a failure to read', () {
      final store = FakeOperatorColorIF()..error = StateError('x');

      expect(
        ListOperatorColorsUC(operatorColors: store).execute(),
        throwsStateError,
      );
    });
  });

  group('SaveOperatorColorUC', () {
    test(
      'stores the color, and replaces the one of the same operator',
      () async {
        final store = FakeOperatorColorIF();
        final uc = SaveOperatorColorUC(operatorColors: store);

        await uc.execute(operatorName: 'NEXCO東日本', color: 0xFF112233);
        await uc.execute(operatorName: 'NEXCO東日本', color: 0xFF445566);

        expect(store.stored.map((c) => (c.operatorName, c.color)), [
          ('NEXCO東日本', 0xFF445566),
        ]);
      },
    );

    test('makes the color opaque', () async {
      final store = FakeOperatorColorIF();

      await SaveOperatorColorUC(
        operatorColors: store,
      ).execute(operatorName: 'NEXCO東日本', color: 0x00ABCDEF);

      expect(store.stored.single.color, 0xFFABCDEF);
    });

    test('refuses an operator that is not in the table, storing nothing', () {
      final store = FakeOperatorColorIF();

      expect(
        () => SaveOperatorColorUC(
          operatorColors: store,
        ).execute(operatorName: '不明', color: 0xFF000000),
        throwsArgumentError,
      );
      expect(store.stored, isEmpty);
    });

    test('passes on a failure to store', () {
      final store = FakeOperatorColorIF()..error = StateError('x');

      expect(
        SaveOperatorColorUC(
          operatorColors: store,
        ).execute(operatorName: 'NEXCO東日本', color: 0xFF000000),
        throwsStateError,
      );
    });
  });

  group('ResetOperatorColorsUC', () {
    FakeOperatorColorIF twoColors() =>
        FakeOperatorColorIF()
          ..stored.addAll(const [
            OperatorColorEntity(operatorName: 'NEXCO東日本', color: 0xFF000001),
            OperatorColorEntity(operatorName: '首都高速道路', color: 0xFF000002),
          ]);

    test('takes back the color of one operator', () async {
      final store = twoColors();

      await ResetOperatorColorsUC(
        operatorColors: store,
      ).execute(operatorName: 'NEXCO東日本');

      expect(store.stored.map((c) => c.operatorName), ['首都高速道路']);
    });

    test('takes back every color without an operator', () async {
      final store = twoColors();

      await ResetOperatorColorsUC(operatorColors: store).execute();

      expect(store.stored, isEmpty);
    });

    test('does nothing for an operator that has no color', () async {
      final store = twoColors();

      await ResetOperatorColorsUC(
        operatorColors: store,
      ).execute(operatorName: '阪神高速道路');

      expect(store.stored, hasLength(2));
    });
  });
}
