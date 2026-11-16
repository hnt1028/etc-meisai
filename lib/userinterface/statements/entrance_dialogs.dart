import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:flutter/material.dart';

/// OP-4 of SCR-003: asks for the entrance date and time (a date, then a time),
/// and then for the user's confirmation, because it can be saved once. Returns
/// the date and time, or null when the user cancelled at any step.
///
/// [estimate] is the estimated entrance (PRC-016): the pickers start with it,
/// and say so. Without one, they start with the exit.
Future<DateTime?> showEntranceAtDialog(
  BuildContext context, {
  required DateTime exitAt,
  DateTime? estimate,
}) async {
  final exitDay = DateTime(exitAt.year, exitAt.month, exitAt.day);
  final start = estimate ?? exitAt;
  final day = await showDatePicker(
    context: context,
    initialDate: DateTime(start.year, start.month, start.day),
    firstDate: DateTime(2000),
    // The entrance is not after the exit.
    lastDate: exitDay,
    helpText: estimate == null
        ? StatementDetailStrings.entranceAtPickDate
        : StatementDetailStrings.entranceAtPickDateEstimated,
  );
  if (day == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    // The estimate is for its own date: on another date, the time of the exit.
    initialTime: TimeOfDay.fromDateTime(
      estimate != null &&
              day.year == estimate.year &&
              day.month == estimate.month &&
              day.day == estimate.day
          ? estimate
          : exitAt,
    ),
    helpText: estimate == null
        ? StatementDetailStrings.entranceAtPickTime
        : StatementDetailStrings.entranceAtPickTimeEstimated,
  );
  if (time == null || !context.mounted) return null;
  final entranceAt = DateTime(
    day.year,
    day.month,
    day.day,
    time.hour,
    time.minute,
  );
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(StatementDetailStrings.entranceAtDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatDateTime(entranceAt),
            style: Theme.of(dialogContext).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            StatementDetailStrings.enteredOnceNotice,
            style: Theme.of(dialogContext).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(StatementDetailStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(StatementDetailStrings.save),
        ),
      ],
    ),
  );
  return confirmed == true ? entranceAt : null;
}

/// OP-5 of SCR-003: asks for the entrance IC. Returns the IC name, or null
/// when the dialog was cancelled. It can be saved once, so the dialog says so.
Future<String?> showEntranceIcDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _EntranceIcDialog(),
  );
}

class _EntranceIcDialog extends StatefulWidget {
  const _EntranceIcDialog();

  @override
  State<_EntranceIcDialog> createState() => _EntranceIcDialogState();
}

class _EntranceIcDialogState extends State<_EntranceIcDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => _controller.text.trim();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(StatementDetailStrings.entranceIcDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: StatementDetailStrings.entranceIcInputLabel,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(
            StatementDetailStrings.enteredOnceNotice,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(StatementDetailStrings.cancel),
        ),
        FilledButton(
          onPressed: _name.isEmpty
              ? null
              : () => Navigator.of(context).pop(_name),
          child: const Text(StatementDetailStrings.save),
        ),
      ],
    );
  }
}
