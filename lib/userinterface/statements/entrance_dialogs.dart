import 'package:etc_meisai/application/dto/entrance_candidates_dto.dart';
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

/// OP-5 of SCR-003: asks for the entrance IC, from a list of choices
/// (PRC-020). Typing a name is one of the choices, for an IC that is not in
/// the list. Returns the IC name, or null when the dialog was cancelled. It can
/// be saved once, so the dialog says so.
///
/// [candidates] is empty when they could not be read: then only the typing is
/// offered.
Future<String?> showEntranceIcDialog(
  BuildContext context, {
  EntranceCandidatesDTO candidates = const EntranceCandidatesDTO(
    used: [],
    sameRoute: [],
  ),
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _EntranceIcDialog(candidates: candidates),
  );
}

class _EntranceIcDialog extends StatefulWidget {
  const _EntranceIcDialog({required this.candidates});

  final EntranceCandidatesDTO candidates;

  @override
  State<_EntranceIcDialog> createState() => _EntranceIcDialogState();
}

class _EntranceIcDialogState extends State<_EntranceIcDialog> {
  final _filter = TextEditingController();
  final _typed = TextEditingController();

  /// The chosen IC name, or null when none, or when the typing is chosen.
  String? _chosen;
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    // With no choices, there is only the typing.
    _typing =
        widget.candidates.used.isEmpty && widget.candidates.sameRoute.isEmpty;
  }

  @override
  void dispose() {
    _filter.dispose();
    _typed.dispose();
    super.dispose();
  }

  String get _query => _filter.text.trim();

  /// The name to save, or null when nothing can be saved yet.
  String? get _name {
    if (_typing) {
      final typed = _typed.text.trim();
      return typed.isEmpty ? null : typed;
    }
    return _chosen;
  }

  List<EntranceCandidateDTO> _shown(List<EntranceCandidateDTO> list) => [
    for (final c in list)
      if (_query.isEmpty || c.icName.contains(_query)) c,
  ];

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );

  Widget _tile(EntranceCandidateDTO c, String keyPrefix, {String? extra}) {
    final routes = c.routeNames.join('・');
    final subtitle = [?extra, if (routes.isNotEmpty) routes].join('　');
    final selected = !_typing && _chosen == c.icName;
    return ListTile(
      key: ValueKey('$keyPrefix-${c.icName}'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      selected: selected,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(c.icName),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      onTap: () => setState(() {
        _typing = false;
        _chosen = c.icName;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final used = _shown(widget.candidates.used);
    final sameRoute = _shown(widget.candidates.sameRoute);
    final hasChoices =
        widget.candidates.used.isNotEmpty ||
        widget.candidates.sameRoute.isNotEmpty;
    return AlertDialog(
      title: const Text(StatementDetailStrings.entranceIcDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasChoices) ...[
              TextField(
                key: const ValueKey('entrance-ic-filter'),
                controller: _filter,
                decoration: const InputDecoration(
                  labelText: StatementDetailStrings.entranceIcFilterLabel,
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (used.isNotEmpty) ...[
                      _header(StatementDetailStrings.entranceIcUsedHeader),
                      for (final c in used)
                        _tile(
                          c,
                          'used',
                          extra: c.uses > 0
                              ? StatementDetailStrings.entranceIcUses(c.uses)
                              : null,
                        ),
                    ],
                    if (sameRoute.isNotEmpty) ...[
                      _header(StatementDetailStrings.entranceIcSameRouteHeader),
                      for (final c in sameRoute) _tile(c, 'route'),
                    ],
                    if (used.isEmpty && sameRoute.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(StatementDetailStrings.entranceIcNoMatch),
                      ),
                    const Divider(),
                    ListTile(
                      key: const ValueKey('entrance-ic-free'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      selected: _typing,
                      leading: Icon(
                        _typing
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      title: const Text(
                        StatementDetailStrings.entranceIcFreeInput,
                      ),
                      onTap: () => setState(() => _typing = true),
                    ),
                  ],
                ),
              ),
            ],
            if (_typing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  key: const ValueKey('entrance-ic-typed'),
                  controller: _typed,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: StatementDetailStrings.entranceIcInputLabel,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              StatementDetailStrings.enteredOnceNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(StatementDetailStrings.cancel),
        ),
        FilledButton(
          onPressed: _name == null
              ? null
              : () => Navigator.of(context).pop(_name),
          child: const Text(StatementDetailStrings.save),
        ),
      ],
    );
  }
}
