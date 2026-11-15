import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  test('removes every stored statement line', () async {
    final lines = FakeStatementLineIF();
    await lines.save(fakeStatementLine());
    await lines.save(fakeStatementLine(exitIc: 'C-IC'));

    await DeleteAllStatementLinesUC(statementLines: lines).execute();

    expect(await lines.findAll(), isEmpty);
  });

  test('does not fail when nothing is stored', () async {
    final lines = FakeStatementLineIF();
    await DeleteAllStatementLinesUC(statementLines: lines).execute();
    expect(await lines.findAll(), isEmpty);
  });

  test('passes a failure on to the caller', () {
    final lines = FakeStatementLineIF()..error = StateError('disk');
    expect(
      DeleteAllStatementLinesUC(statementLines: lines).execute(),
      throwsStateError,
    );
  });
}
