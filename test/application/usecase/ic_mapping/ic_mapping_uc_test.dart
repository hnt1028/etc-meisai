import 'package:etc_meisai/application/usecase/ic_mapping/delete_ic_mapping_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/list_ic_matches_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/save_ic_mapping_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/search_ic_points_uc.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';
import 'package:etc_meisai/domain/value/ic_match_value.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

/// Statement lines: 北 -> 東 (three times), 北 -> 西 (once), and a line
/// without an entrance to 本線 (twice).
FakeStatementLineIF _lines() {
  final lines = FakeStatementLineIF();
  for (var i = 0; i < 3; i++) {
    lines.stored.add(
      fakeStatementLine(
        exitIc: '東',
        entranceIc: '北',
        entranceAt: DateTime(2026, 1, 1 + i),
        exitAt: DateTime(2026, 1, 1 + i, 1),
      ),
    );
  }
  lines.stored.add(fakeStatementLine(exitIc: '西', entranceIc: '北'));
  lines.stored.addAll([
    fakeStatementLine(exitIc: '本線', withoutEntrance: true),
    fakeStatementLine(exitIc: '本線', withoutEntrance: true),
  ]);
  return lines;
}

void main() {
  group('ListIcMatchesUC', () {
    ListIcMatchesUC uc({
      FakeStatementLineIF? lines,
      FakeIcMasterIF? master,
      FakeIcMappingIF? mappings,
    }) => ListIcMatchesUC(
      statementLines: lines ?? _lines(),
      icMaster:
          master ??
          FakeIcMasterIF([
            fakeIcPoint(id: 'n1', name: '北'),
            fakeIcPoint(id: 'n2', name: '北'),
            fakeIcPoint(id: 'e', name: '東'),
          ]),
      icMappings: mappings ?? FakeIcMappingIF(),
    );

    test('lists ambiguous and unknown names, the most used first', () async {
      final result = await uc().execute();

      // 東 matches, 西 and 本線 have no point, 北 has two.
      expect(result.unresolved.map((m) => m.icName), ['北', '本線', '西']);
      expect(result.unresolved.map((m) => m.lineCount), [4, 2, 1]);
      expect(result.unresolved.map((m) => m.state), [
        IcMatchValue.ambiguous,
        IcMatchValue.unknown,
        IcMatchValue.unknown,
      ]);
      expect(result.unresolved.first.candidates.map((p) => p.id), ['n1', 'n2']);
      expect(result.unresolved.last.candidates, isEmpty);
      expect(result.registered, isEmpty);
    });

    test('does not list a name that is matched or registered', () async {
      final mappings = FakeIcMappingIF()
        ..stored.add(const IcMappingEntity(icName: '北', pointId: 'n1'));

      final result = await uc(mappings: mappings).execute();

      expect(result.unresolved.map((m) => m.icName), ['本線', '西']);
    });

    test('lists registered mappings with their point and line count', () async {
      final mappings = FakeIcMappingIF()
        ..stored.addAll(const [
          IcMappingEntity(icName: '西', pointId: 'e'),
          IcMappingEntity(icName: '北', pointId: 'n2'),
          IcMappingEntity(icName: '古い', pointId: 'gone'),
        ]);

      final result = await uc(mappings: mappings).execute();

      expect(result.registered.map((m) => m.icName), ['北', '古い', '西']);
      expect(result.registered.map((m) => m.state).toSet(), {
        IcMatchValue.registered,
      });
      expect(result.registered.map((m) => m.lineCount), [4, 0, 1]);
      expect(result.registered.map((m) => m.point?.id), ['n2', null, 'e']);
    });

    test('counts a line once even when both ICs have the same name', () async {
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(exitIc: '同じ', entranceIc: '同じ'));

      final result = await uc(
        lines: lines,
        master: FakeIcMasterIF([]),
      ).execute();

      expect(result.unresolved.single.lineCount, 1);
    });

    test('is empty with no statement lines', () async {
      final result = await uc(lines: FakeStatementLineIF()).execute();

      expect(result.unresolved, isEmpty);
    });

    test('passes on a failure to read', () {
      expect(
        uc(master: FakeIcMasterIF([], error: StateError('x'))).execute(),
        throwsStateError,
      );
    });
  });

  group('SearchIcPointsUC', () {
    SearchIcPointsUC uc(FakeIcMasterIF master) =>
        SearchIcPointsUC(icMaster: master);

    final master = FakeIcMasterIF([
      fakeIcPoint(name: '東京SIC'),
      fakeIcPoint(name: '西東京'),
      fakeIcPoint(name: '東京', kind: IcKindValue.junction),
      fakeIcPoint(name: '大阪'),
    ]);

    test('returns nothing for a blank query', () async {
      expect(await uc(master).execute(''), isEmpty);
      expect(await uc(master).execute('  　'), isEmpty);
    });

    test('puts the names that start with the query first', () async {
      final result = await uc(master).execute('東京');

      expect(result.map((p) => p.name), ['東京', '東京SIC', '西東京']);
      expect(result.first.kind, IcKindValue.junction);
      expect(result.first.routeNames, ['テスト自動車道']);
    });

    test('ignores width and case', () async {
      final m = FakeIcMasterIF([fakeIcPoint(name: 'TOKYO')]);

      expect((await uc(m).execute('ｔｏｋｙｏ')).map((p) => p.name), ['TOKYO']);
    });

    test('returns nothing when no name has the query', () async {
      expect(await uc(master).execute('札幌'), isEmpty);
    });

    test('returns at most 50 points', () async {
      final many = FakeIcMasterIF([
        for (var i = 0; i < 80; i++) fakeIcPoint(id: 'p$i', name: 'あ$i'),
      ]);

      expect(await uc(many).execute('あ'), hasLength(SearchIcPointsUC.maxCount));
    });

    test('passes on a failure to read', () {
      expect(
        uc(FakeIcMasterIF([], error: StateError('x'))).execute('東'),
        throwsStateError,
      );
    });
  });

  group('SaveIcMappingUC', () {
    test('stores the mapping and replaces one of the same IC name', () async {
      final mappings = FakeIcMappingIF();
      final uc = SaveIcMappingUC(
        icMaster: FakeIcMasterIF([
          fakeIcPoint(id: 'a', name: 'A'),
          fakeIcPoint(id: 'b', name: 'B'),
        ]),
        icMappings: mappings,
      );

      await uc.execute(icName: '北', pointId: 'a');
      await uc.execute(icName: '北', pointId: 'b');

      expect(mappings.stored, hasLength(1));
      expect(mappings.stored.single.pointId, 'b');
    });

    test(
      'rejects a point that is not in the master, storing nothing',
      () async {
        final mappings = FakeIcMappingIF();
        final uc = SaveIcMappingUC(
          icMaster: FakeIcMasterIF([fakeIcPoint(id: 'a', name: 'A')]),
          icMappings: mappings,
        );

        await expectLater(
          uc.execute(icName: '北', pointId: 'zzz'),
          throwsArgumentError,
        );
        expect(mappings.stored, isEmpty);
      },
    );

    test('passes on a failure to store', () {
      final mappings = FakeIcMappingIF()..error = StateError('disk');
      final uc = SaveIcMappingUC(
        icMaster: FakeIcMasterIF([fakeIcPoint(id: 'a', name: 'A')]),
        icMappings: mappings,
      );

      expect(uc.execute(icName: '北', pointId: 'a'), throwsStateError);
    });
  });

  group('DeleteIcMappingUC', () {
    test('removes the mapping, and does nothing when there is none', () async {
      final mappings = FakeIcMappingIF()
        ..stored.add(const IcMappingEntity(icName: '北', pointId: 'a'));
      final uc = DeleteIcMappingUC(icMappings: mappings);

      await uc.execute('北');
      await uc.execute('北');

      expect(mappings.stored, isEmpty);
    });

    test('passes on a failure', () {
      final mappings = FakeIcMappingIF()..error = StateError('disk');

      expect(
        DeleteIcMappingUC(icMappings: mappings).execute('北'),
        throwsStateError,
      );
    });
  });
}
