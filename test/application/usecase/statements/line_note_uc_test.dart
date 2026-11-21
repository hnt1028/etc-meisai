import 'package:etc_meisai/application/usecase/aggregation/aggregate_statements_uc.dart';
import 'package:etc_meisai/application/usecase/statements/save_line_note_uc.dart';
import 'package:etc_meisai/application/usecase/statements/statement_filter.dart';
import 'package:etc_meisai/application/usecase/statements/statement_line_copy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('SaveLineNoteUC', () {
    late FakeStatementLineIF lines;
    late SaveLineNoteUC uc;

    setUp(() {
      lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(id: 'a'))
        ..stored.add(fakeStatementLine(id: 'b', exitIc: 'C-IC'));
      uc = SaveLineNoteUC(statementLines: lines);
    });

    test('saves the memo and the tags of one line', () async {
      await uc.execute(id: 'a', memo: '出張', tags: ['仕事', '東京']);

      final a = lines.stored.firstWhere((l) => l.id == 'a');
      expect(a.memo, '出張');
      expect(a.tags, ['仕事', '東京']);
      // The other line is not touched.
      final b = lines.stored.firstWhere((l) => l.id == 'b');
      expect(b.memo, '');
      expect(b.tags, isEmpty);
    });

    test('trims, and drops empty and repeated tags', () async {
      await uc.execute(id: 'a', memo: '  メモ  ', tags: [' 仕事 ', '', '仕事', ' ']);

      final a = lines.stored.firstWhere((l) => l.id == 'a');
      expect(a.memo, 'メモ');
      expect(a.tags, ['仕事']);
    });

    test('clears the note with an empty memo and no tag', () async {
      await uc.execute(id: 'a', memo: 'x', tags: ['t']);
      await uc.execute(id: 'a', memo: '', tags: []);

      final a = lines.stored.firstWhere((l) => l.id == 'a');
      expect(a.memo, '');
      expect(a.tags, isEmpty);
    });

    test(
      'accepts the longest memo, the longest tag and the most tags',
      () async {
        await uc.execute(
          id: 'a',
          memo: 'あ' * SaveLineNoteUC.memoMaxLength,
          tags: [
            for (var i = 0; i < SaveLineNoteUC.tagMaxCount; i++)
              '${'い' * (SaveLineNoteUC.tagMaxLength - 1)}$i',
          ],
        );

        final a = lines.stored.firstWhere((l) => l.id == 'a');
        expect(a.memo.length, SaveLineNoteUC.memoMaxLength);
        expect(a.tags, hasLength(SaveLineNoteUC.tagMaxCount));
      },
    );

    test('rejects a note that is too long, saving nothing', () async {
      final bad = <(String, List<String>)>[
        ('あ' * (SaveLineNoteUC.memoMaxLength + 1), const []),
        ('', ['い' * (SaveLineNoteUC.tagMaxLength + 1)]),
        ('', [for (var i = 0; i <= SaveLineNoteUC.tagMaxCount; i++) 't$i']),
        ('', ['a;b']),
        ('', ['a\nb']),
        ('', ['a\rb']),
      ];
      for (final (memo, tags) in bad) {
        expect(
          () => uc.execute(id: 'a', memo: memo, tags: tags),
          throwsArgumentError,
        );
      }

      expect(lines.stored.first.memo, '');
    });

    test('rejects a line that is not stored', () async {
      expect(
        () => uc.execute(id: 'none', memo: 'x', tags: const []),
        throwsStateError,
      );
    });

    test('passes on a failure to store', () async {
      lines.error = StateError('x');

      expect(
        () => uc.execute(id: 'a', memo: 'x', tags: const []),
        throwsStateError,
      );
    });
  });

  group('copyWithNote', () {
    test('sets the note, and keeps the rest', () {
      final line = fakeStatementLine(id: 'a');

      final copy = copyWithNote(line, memo: 'm', tags: const ['t']);

      expect(copy.memo, 'm');
      expect(copy.tags, ['t']);
      expect(copy.id, 'a');
      expect(copy.fare, line.fare);
      expect(line.memo, '');
    });

    test('is kept by the other copies', () {
      final line = fakeStatementLine(
        id: 'a',
        withoutVehicleNumber: true,
        withoutEntrance: true,
        memo: 'm',
        tags: const ['t'],
      );

      final a = copyWithVehicleNumber(line, 1);
      final b = copyWithEntrance(line, entranceIc: '北');

      for (final copy in [a, b]) {
        expect(copy.memo, 'm');
        expect(copy.tags, ['t']);
      }
    });
  });

  group('the tags in the filter', () {
    final lines = [
      fakeStatementLine(id: 'a', tags: const ['仕事', '東京']),
      fakeStatementLine(id: 'b', tags: const ['私用']),
      fakeStatementLine(id: 'c'),
    ];

    test('are listed once, sorted', () {
      expect(tagChoicesOf(lines), ['私用', '東京', '仕事']..sort());
      expect(tagChoicesOf(const []), isEmpty);
    });

    test('keep the lines that have the tag', () {
      expect(filterStatementLines(lines, tag: '仕事').map((l) => l.id), ['a']);
      expect(filterStatementLines(lines, tag: '無い'), isEmpty);
      expect(filterStatementLines(lines), hasLength(3));
    });
  });

  group('the list, the map and the aggregation with a tag', () {
    final stored = [
      fakeStatementLine(id: 'a', fare: 1000, tags: const ['仕事', '東京']),
      fakeStatementLine(id: 'b', fare: 500, tags: const ['私用']),
      fakeStatementLine(id: 'c', fare: 200),
    ];

    FakeStatementLineIF source() =>
        FakeStatementLineIF()..stored.addAll(stored);

    test(
      'the list filters by the tag and gives the tags and the memo',
      () async {
        final list = await fakeListUC(source()).execute(tag: '仕事');

        expect(list.lines.map((l) => l.id), ['a']);
        expect(list.lines.single.tags, ['仕事', '東京']);
        expect(list.tagChoices, hasLength(3));
      },
    );

    test('the map filters by the tag', () async {
      final result = await fakeRouteMapUC(source()).execute(tag: '私用');

      expect(result.lineCount, 1);
      expect(result.tagChoices, hasLength(3));
    });

    test('the aggregation has a row for each tag and one for none', () async {
      final result = await fakeAggregateUC(source()).execute();

      final fares = {for (final r in result.tags) r.label: r.fare};
      // A line with two tags counts for both.
      expect(fares, {
        '仕事': 1000,
        '東京': 1000,
        '私用': 500,
        AggregateStatementsUC.untaggedLabel: 200,
      });
      expect(result.tagChoices, hasLength(3));

      final filtered = await fakeAggregateUC(source()).execute(tag: '東京');
      expect(filtered.summary.lineCount, 1);
    });
  });
}
