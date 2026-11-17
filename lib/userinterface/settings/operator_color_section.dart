import 'package:etc_meisai/application/dto/operator_color_dto.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/common/section_title.dart';
import 'package:etc_meisai/userinterface/route_map/operator_color_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OP-7 and OP-8 of SCR-001: the color of the lines of every road operator on
/// the map. Tapping an operator opens its color (red, green and blue sliders).
class OperatorColorSection extends ConsumerWidget {
  const OperatorColorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(operatorColorsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(SettingsStrings.operatorColorSection),
        Text(
          SettingsStrings.operatorColorNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        colors.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Padding(
            padding: EdgeInsets.only(top: 8),
            child: MessageText(
              SettingsStrings.operatorColorLoadFailed,
              isError: true,
            ),
          ),
          data: (list) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in list)
                ListTile(
                  key: ValueKey('operator-color-${c.operatorName}'),
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(c.color),
                  ),
                  title: Text(c.operatorName),
                  subtitle: Text(
                    c.isDefault
                        ? SettingsStrings.operatorColorDefault
                        : SettingsStrings.operatorColorChanged,
                  ),
                  onTap: () => _change(context, ref, c),
                ),
              const SizedBox(height: 4),
              OutlinedButton(
                onPressed: list.every((c) => c.isDefault)
                    ? null
                    : () => _run(
                        context,
                        ref,
                        () => ref.read(resetOperatorColorsUCProvider).execute(),
                      ),
                child: const Text(SettingsStrings.operatorColorResetAll),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    OperatorColorDTO current,
  ) async {
    final choice = await showOperatorColorDialog(context, current);
    if (choice == null || !context.mounted) return;
    final name = current.operatorName;
    final color = choice.color;
    await _run(
      context,
      ref,
      () => color == null
          ? ref.read(resetOperatorColorsUCProvider).execute(operatorName: name)
          : ref
                .read(saveOperatorColorUCProvider)
                .execute(operatorName: name, color: color),
    );
  }

  /// Runs [action], and reads the colors again. A failure is shown as a
  /// message, without details.
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(SettingsStrings.operatorColorSaveFailed)),
      );
    }
    ref.invalidate(operatorColorsProvider);
  }
}

/// What the user decided in [showOperatorColorDialog]: a color to save, or,
/// when [color] is null, to use the default again.
class OperatorColorChoice {
  const OperatorColorChoice(this.color);

  final int? color;
}

/// Asks for the color of an operator with red, green and blue sliders, showing
/// the color. Returns null when the dialog was cancelled.
Future<OperatorColorChoice?> showOperatorColorDialog(
  BuildContext context,
  OperatorColorDTO current,
) {
  return showDialog<OperatorColorChoice>(
    context: context,
    builder: (_) => _OperatorColorDialog(current: current),
  );
}

class _OperatorColorDialog extends StatefulWidget {
  const _OperatorColorDialog({required this.current});

  final OperatorColorDTO current;

  @override
  State<_OperatorColorDialog> createState() => _OperatorColorDialogState();
}

class _OperatorColorDialogState extends State<_OperatorColorDialog> {
  late int _red = (widget.current.color >> 16) & 0xFF;
  late int _green = (widget.current.color >> 8) & 0xFF;
  late int _blue = widget.current.color & 0xFF;

  int get _color => 0xFF000000 | (_red << 16) | (_green << 8) | _blue;

  Widget _slider(String key, String label, int value, ValueChanged<int> set) {
    return Row(
      children: [
        SizedBox(width: 24, child: Text(label)),
        Expanded(
          child: Slider(
            key: ValueKey(key),
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            label: '$value',
            onChanged: (v) => setState(() => set(v.round())),
          ),
        ),
        SizedBox(width: 32, child: Text('$value', textAlign: TextAlign.end)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.current.operatorName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const ValueKey('operator-color-preview'),
            height: 40,
            decoration: BoxDecoration(
              color: Color(_color),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          _slider(
            'slider-red',
            SettingsStrings.operatorColorRed,
            _red,
            (v) => _red = v,
          ),
          _slider(
            'slider-green',
            SettingsStrings.operatorColorGreen,
            _green,
            (v) => _green = v,
          ),
          _slider(
            'slider-blue',
            SettingsStrings.operatorColorBlue,
            _blue,
            (v) => _blue = v,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(SettingsStrings.operatorColorCancel),
        ),
        TextButton(
          onPressed: widget.current.isDefault
              ? null
              : () =>
                    Navigator.of(context).pop(const OperatorColorChoice(null)),
          child: const Text(SettingsStrings.operatorColorReset),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(OperatorColorChoice(_color)),
          child: const Text(SettingsStrings.operatorColorSave),
        ),
      ],
    );
  }
}
