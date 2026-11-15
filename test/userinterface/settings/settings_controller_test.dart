import 'dart:async';
import 'dart:typed_data';

import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/userinterface/settings/settings_controller.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

ProviderContainer _container({
  required FakeStatementIF statement,
  required FakeStatementLineIF lines,
  Future<Uint8List?> Function()? picker,
}) {
  final container = ProviderContainer(
    overrides: [
      importStatementUCProvider.overrideWithValue(
        ImportStatementUC(statement: statement, statementLines: lines),
      ),
      deleteAllStatementLinesUCProvider.overrideWithValue(
        DeleteAllStatementLinesUC(statementLines: lines),
      ),
      csvPickerProvider.overrideWithValue(
        picker ?? () async => Uint8List.fromList([1]),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts idle with nothing to show', () {
    final c = _container(
      statement: FakeStatementIF([]),
      lines: FakeStatementLineIF(),
    );
    final state = c.read(settingsControllerProvider);
    expect(state.busy, isFalse);
    expect(state.result, isNull);
    expect(state.error, isNull);
    expect(state.notice, isNull);
  });

  group('importCsv', () {
    test('stores the lines and keeps the counts', () async {
      final lines = FakeStatementLineIF();
      final c = _container(
        statement: FakeStatementIF([
          fakeStatementLine(),
          fakeStatementLine(exitIc: 'C-IC'),
        ]),
        lines: lines,
      );

      await c.read(settingsControllerProvider.notifier).importCsv();

      final state = c.read(settingsControllerProvider);
      expect(state.result?.addedCount, 2);
      expect(state.error, isNull);
      expect(lines.stored, hasLength(2));
    });

    test('does nothing when no file is chosen', () async {
      final lines = FakeStatementLineIF();
      final c = _container(
        statement: FakeStatementIF([fakeStatementLine()]),
        lines: lines,
        picker: () async => null,
      );

      await c.read(settingsControllerProvider.notifier).importCsv();

      final state = c.read(settingsControllerProvider);
      expect(state.result, isNull);
      expect(state.error, isNull);
      expect(lines.stored, isEmpty);
    });

    test('shows what is invalid in the CSV', () async {
      final c = _container(
        statement: FakeStatementIF([], error: const FormatException('2行目: 不正')),
        lines: FakeStatementLineIF(),
      );

      await c.read(settingsControllerProvider.notifier).importCsv();

      expect(
        c.read(settingsControllerProvider).error,
        SettingsStrings.importFailed('2行目: 不正'),
      );
    });

    test('hides the details of an unexpected failure', () async {
      final lines = FakeStatementLineIF()..error = StateError('card 0000');
      final c = _container(
        statement: FakeStatementIF([fakeStatementLine()]),
        lines: lines,
      );

      await c.read(settingsControllerProvider.notifier).importCsv();

      final error = c.read(settingsControllerProvider).error;
      expect(error, SettingsStrings.importUnexpected);
      expect(error, isNot(contains('0000')));
    });

    test('ignores a second call while one is running', () async {
      final gate = Completer<void>();
      final lines = FakeStatementLineIF()..gate = gate.future;
      var picks = 0;
      final c = _container(
        statement: FakeStatementIF([fakeStatementLine()]),
        lines: lines,
        picker: () async {
          picks++;
          return Uint8List.fromList([1]);
        },
      );
      final controller = c.read(settingsControllerProvider.notifier);

      final first = controller.importCsv();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(settingsControllerProvider).busy, isTrue);
      await controller.importCsv();
      gate.complete();
      await first;

      expect(picks, 1);
      expect(c.read(settingsControllerProvider).busy, isFalse);
    });
  });

  group('deleteAll', () {
    test('removes every line and says so', () async {
      final lines = FakeStatementLineIF();
      await lines.save(fakeStatementLine());
      final c = _container(statement: FakeStatementIF([]), lines: lines);

      await c.read(settingsControllerProvider.notifier).deleteAll();

      expect(lines.stored, isEmpty);
      expect(
        c.read(settingsControllerProvider).notice,
        SettingsStrings.deleted,
      );
    });

    test('shows a failure without its details', () async {
      final lines = FakeStatementLineIF()..error = StateError('card 0000');
      final c = _container(statement: FakeStatementIF([]), lines: lines);

      await c.read(settingsControllerProvider.notifier).deleteAll();

      final state = c.read(settingsControllerProvider);
      expect(state.error, SettingsStrings.deleteFailed);
      expect(state.notice, isNull);
    });

    test('ignores a second call while one is running', () async {
      final gate = Completer<void>();
      final lines = FakeStatementLineIF()..gate = gate.future;
      final c = _container(statement: FakeStatementIF([]), lines: lines);
      final controller = c.read(settingsControllerProvider.notifier);

      final first = controller.deleteAll();
      await controller.deleteAll();
      gate.complete();
      await first;

      expect(
        c.read(settingsControllerProvider).notice,
        SettingsStrings.deleted,
      );
    });
  });

  group('providers', () {
    test('the use cases must be overridden', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(() => c.read(importStatementUCProvider), throwsA(anything));
      expect(
        () => c.read(deleteAllStatementLinesUCProvider),
        throwsA(anything),
      );
    });

    test('the file picker is the real one by default', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(csvPickerProvider), isA<Function>());
    });
  });
}
