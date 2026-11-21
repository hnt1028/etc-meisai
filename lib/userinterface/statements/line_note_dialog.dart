import 'package:etc_meisai/application/usecase/statements/save_line_note_uc.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:flutter/material.dart';

/// What the user wrote in [showLineNoteDialog].
class LineNoteInput {
  const LineNoteInput({required this.memo, required this.tags});

  final String memo;
  final List<String> tags;
}

/// OP-6 of SCR-003: asks for the memo and the tags of a statement line. The
/// tags are chosen from the ones that were used ([choices]), or typed.
/// Returns null when the dialog was cancelled.
Future<LineNoteInput?> showLineNoteDialog(
  BuildContext context, {
  required String memo,
  required List<String> tags,
  required List<String> choices,
}) {
  return showDialog<LineNoteInput>(
    context: context,
    builder: (_) => _LineNoteDialog(memo: memo, tags: tags, choices: choices),
  );
}

class _LineNoteDialog extends StatefulWidget {
  const _LineNoteDialog({
    required this.memo,
    required this.tags,
    required this.choices,
  });

  final String memo;
  final List<String> tags;
  final List<String> choices;

  @override
  State<_LineNoteDialog> createState() => _LineNoteDialogState();
}

class _LineNoteDialogState extends State<_LineNoteDialog> {
  late final _memo = TextEditingController(text: widget.memo);
  final _tagInput = TextEditingController();
  late final List<String> _tags = List.of(widget.tags);

  /// What is wrong with the tag that is typed, or null.
  String? _error;

  @override
  void dispose() {
    _memo.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  /// Adds the typed tag. A tag that is already there is not added twice.
  void _addTyped() {
    final tag = _tagInput.text.trim();
    if (tag.isEmpty) return;
    if (RegExp(r'[;\r\n]').hasMatch(tag)) {
      setState(() => _error = StatementDetailStrings.tagInvalid);
      return;
    }
    _add(tag);
    _tagInput.clear();
  }

  void _add(String tag) {
    setState(() {
      _error = null;
      if (_tags.contains(tag)) return;
      if (_tags.length >= SaveLineNoteUC.tagMaxCount) {
        _error = StatementDetailStrings.tagTooMany;
        return;
      }
      _tags.add(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unused = [
      for (final c in widget.choices)
        if (!_tags.contains(c)) c,
    ];
    return AlertDialog(
      title: const Text(StatementDetailStrings.noteDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('note-memo'),
              controller: _memo,
              maxLength: SaveLineNoteUC.memoMaxLength,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: StatementDetailStrings.memoInputLabel,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in _tags)
                    InputChip(
                      key: ValueKey('note-tag-$tag'),
                      label: Text(tag),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    ),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('note-tag-input'),
                    controller: _tagInput,
                    maxLength: SaveLineNoteUC.tagMaxLength,
                    onSubmitted: (_) => _addTyped(),
                    decoration: InputDecoration(
                      labelText: StatementDetailStrings.tagInputLabel,
                      errorText: _error,
                      counterText: '',
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('note-tag-add'),
                  tooltip: StatementDetailStrings.tagAdd,
                  onPressed: _addTyped,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (unused.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                StatementDetailStrings.tagChoicesHeader,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in unused)
                    ActionChip(
                      key: ValueKey('note-choice-$c'),
                      label: Text(c),
                      onPressed: () => _add(c),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(StatementDetailStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            LineNoteInput(memo: _memo.text, tags: List.unmodifiable(_tags)),
          ),
          child: const Text(StatementDetailStrings.save),
        ),
      ],
    );
  }
}
