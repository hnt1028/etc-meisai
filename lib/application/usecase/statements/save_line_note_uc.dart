import 'package:etc_meisai/application/interface/statement_line_if.dart';

/// Stores the memo and the tags the user wrote for a statement line.
/// Design: PRC-027.
class SaveLineNoteUC {
  const SaveLineNoteUC({required this.statementLines});

  /// The longest memo, in characters.
  static const memoMaxLength = 200;

  /// The most tags of one line, and the longest tag, in characters.
  static const tagMaxCount = 10;
  static const tagMaxLength = 20;

  final StatementLineIF statementLines;

  /// [memo] and each tag are trimmed. Empty tags and repeated tags are
  /// dropped. Throws an [ArgumentError] when the memo or the tags are too long
  /// or too many, or when a tag has `;` or a line break (the tags are stored
  /// joined with `;`). Throws a [StateError] when the line is not found.
  Future<void> execute({
    required String id,
    required String memo,
    required List<String> tags,
  }) async {
    final cleanMemo = memo.trim();
    if (cleanMemo.length > memoMaxLength) {
      throw ArgumentError('The memo is too long.');
    }
    final cleanTags = <String>[];
    for (final tag in tags.map((t) => t.trim())) {
      if (tag.isEmpty || cleanTags.contains(tag)) continue;
      if (tag.length > tagMaxLength || RegExp(r'[;\r\n]').hasMatch(tag)) {
        throw ArgumentError('A tag is not valid.');
      }
      cleanTags.add(tag);
    }
    if (cleanTags.length > tagMaxCount) {
      throw ArgumentError('There are too many tags.');
    }
    if (await statementLines.findById(id) == null) {
      throw StateError('The statement line is not found.');
    }
    await statementLines.updateNote(id, memo: cleanMemo, tags: cleanTags);
  }
}
