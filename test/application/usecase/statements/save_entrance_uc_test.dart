import 'package:etc_meisai/application/usecase/statements/save_entrance_uc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('SaveEntranceUC', () {
    late FakeStatementLineIF lines;
    late SaveEntranceUC uc;

    // The line exits at 2026-01-10 09:15 (the default of the fake).
    setUp(() {
      lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(id: 'blank', withoutEntrance: true))
        ..stored.add(fakeStatementLine(id: 'filled', exitIc: 'C-IC'));
      uc = SaveEntranceUC(statementLines: lines);
    });

    final before = DateTime(2026, 1, 10, 8, 0);

    test('saves the entrance date and time of a line that has none', () async {
      await uc.execute(id: 'blank', entranceAt: before);

      final line = lines.stored.firstWhere((l) => l.id == 'blank');
      expect(line.entranceAt, before);
      // The IC was not given, so it stays blank.
      expect(line.entranceIc, isNull);
      // The other line is not touched.
      expect(
        lines.stored.firstWhere((l) => l.id == 'filled').entranceAt,
        isNot(before),
      );
    });

    test('saves the entrance IC, with the spaces around it removed', () async {
      await uc.execute(id: 'blank', entranceIc: '  テスト北ＩＣ ');

      final line = lines.stored.firstWhere((l) => l.id == 'blank');
      expect(line.entranceIc, 'テスト北ＩＣ');
      expect(line.entranceAt, isNull);
    });

    test('saves both at once', () async {
      await uc.execute(id: 'blank', entranceAt: before, entranceIc: '北');

      final line = lines.stored.firstWhere((l) => l.id == 'blank');
      expect(line.entranceAt, before);
      expect(line.entranceIc, '北');
    });

    test('accepts an entrance at the same time as the exit', () async {
      await uc.execute(id: 'blank', entranceAt: DateTime(2026, 1, 10, 9, 15));

      expect(lines.stored.first.entranceAt, DateTime(2026, 1, 10, 9, 15));
    });

    test('rejects an entrance after the exit, saving nothing', () async {
      await expectLater(
        uc.execute(
          id: 'blank',
          entranceAt: DateTime(2026, 1, 10, 9, 16),
          entranceIc: '北',
        ),
        throwsArgumentError,
      );

      // Nothing was saved, not even the IC that was fine.
      final line = lines.stored.firstWhere((l) => l.id == 'blank');
      expect(line.entranceAt, isNull);
      expect(line.entranceIc, isNull);
    });

    test('rejects nothing given, and a blank IC', () async {
      await expectLater(uc.execute(id: 'blank'), throwsArgumentError);
      await expectLater(
        uc.execute(id: 'blank', entranceIc: '   '),
        throwsArgumentError,
      );
      await expectLater(
        uc.execute(id: 'blank', entranceIc: ''),
        throwsArgumentError,
      );
    });

    test('does not change what a line already has', () async {
      final filled = lines.stored.firstWhere((l) => l.id == 'filled');

      await expectLater(
        uc.execute(id: 'filled', entranceAt: before),
        throwsStateError,
      );
      await expectLater(
        uc.execute(id: 'filled', entranceIc: '北'),
        throwsStateError,
      );

      final now = lines.stored.firstWhere((l) => l.id == 'filled');
      expect(now.entranceAt, filled.entranceAt);
      expect(now.entranceIc, filled.entranceIc);
    });

    test('saves nothing when only one of two is already there', () async {
      await uc.execute(id: 'blank', entranceIc: '北');

      // The IC is there now, so giving both fails, and the time is not saved.
      await expectLater(
        uc.execute(id: 'blank', entranceAt: before, entranceIc: '南'),
        throwsStateError,
      );

      final line = lines.stored.firstWhere((l) => l.id == 'blank');
      expect(line.entranceIc, '北');
      expect(line.entranceAt, isNull);
    });

    test('cannot be done twice for one item', () async {
      await uc.execute(id: 'blank', entranceAt: before);

      await expectLater(
        uc.execute(id: 'blank', entranceAt: DateTime(2026, 1, 10, 7)),
        throwsStateError,
      );
      expect(lines.stored.first.entranceAt, before);
    });

    test('rejects an id that is not stored', () {
      expect(uc.execute(id: 'nothing', entranceIc: '北'), throwsStateError);
    });

    test('does not put what the user entered in an error message', () async {
      try {
        await uc.execute(id: 'filled', entranceIc: 'SECRET');
        fail('should have thrown');
      } on StateError catch (e) {
        expect(e.message, isNot(contains('SECRET')));
      }
      try {
        await uc.execute(id: 'blank', entranceAt: DateTime(2026, 1, 10, 23));
        fail('should have thrown');
      } on ArgumentError catch (e) {
        expect(e.message.toString(), isNot(contains('2026')));
      }
    });

    test('passes on a failure to save', () {
      lines.error = StateError('disk');

      expect(uc.execute(id: 'blank', entranceIc: '北'), throwsStateError);
    });
  });
}
