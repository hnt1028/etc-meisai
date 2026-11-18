import 'dart:math' as math;

import 'package:etc_meisai/application/dto/operator_color_dto.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/common/section_title.dart';
import 'package:etc_meisai/userinterface/route_map/operator_color_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OP-7 and OP-8 of SCR-001: the color of the lines of every road operator on
/// the map. Tapping an operator opens its color (a color wheel and a palette).
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

/// The colors to choose from, with their names (read aloud, and shown as the
/// tooltip). Each one is an opaque ARGB number.
const operatorColorPalette = <({String name, int color})>[
  (name: SettingsStrings.paletteRed, color: 0xFFD32F2F),
  (name: SettingsStrings.palettePink, color: 0xFFF06292),
  (name: SettingsStrings.palettePurple, color: 0xFF8E24AA),
  (name: SettingsStrings.paletteIndigo, color: 0xFF3949AB),
  (name: SettingsStrings.paletteBlue, color: 0xFF1976D2),
  (name: SettingsStrings.paletteCyan, color: 0xFF0097A7),
  (name: SettingsStrings.paletteTeal, color: 0xFF00897B),
  (name: SettingsStrings.paletteGreen, color: 0xFF388E3C),
  (name: SettingsStrings.paletteLime, color: 0xFF7CB342),
  (name: SettingsStrings.paletteYellow, color: 0xFFFBC02D),
  (name: SettingsStrings.paletteOrange, color: 0xFFF57C00),
  (name: SettingsStrings.paletteBrown, color: 0xFF6D4C41),
  (name: SettingsStrings.paletteGrey, color: 0xFF757575),
  (name: SettingsStrings.paletteBlack, color: 0xFF212121),
];

/// Asks for the color of an operator by a palette, showing the color. Returns
/// null when the dialog was cancelled.
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
  late int _color = widget.current.color;
  late HSVColor _hsv = HSVColor.fromColor(Color(widget.current.color));

  /// A color from the wheel or the brightness slider.
  void _setHsv(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _color = hsv.toColor().toARGB32();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.current.operatorName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              key: const ValueKey('operator-color-preview'),
              height: 40,
              decoration: BoxDecoration(
                color: Color(_color),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: _ColorWheel(
                key: const ValueKey('color-wheel'),
                hsv: _hsv,
                onChanged: _setHsv,
              ),
            ),
            Row(
              children: [
                const Text(SettingsStrings.operatorColorBrightness),
                Expanded(
                  child: Slider(
                    key: const ValueKey('slider-brightness'),
                    value: _hsv.value,
                    onChanged: (v) => _setHsv(_hsv.withValue(v)),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in operatorColorPalette)
                  Tooltip(
                    message: entry.name,
                    child: InkWell(
                      key: ValueKey('palette-${entry.color.toRadixString(16)}'),
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() {
                        _color = entry.color;
                        _hsv = HSVColor.fromColor(Color(entry.color));
                      }),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Color(entry.color),
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: _color == entry.color
                            ? Icon(
                                Icons.check,
                                color:
                                    Color(entry.color).computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
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
          onPressed: _color == widget.current.color
              ? null
              : () => Navigator.of(context).pop(OperatorColorChoice(_color)),
          child: const Text(SettingsStrings.operatorColorSave),
        ),
      ],
    );
  }
}

/// A color wheel: the angle is the hue, the distance from the center is the
/// saturation. The brightness is set apart, and shades the wheel. Tapping or
/// dragging chooses a color.
class _ColorWheel extends StatelessWidget {
  const _ColorWheel({super.key, required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  static const _size = 200.0;

  void _pick(Offset local) {
    const radius = _size / 2;
    final d = local - const Offset(radius, radius);
    final hue = (math.atan2(d.dy, d.dx) * 180 / math.pi + 360) % 360;
    final saturation = math.min(d.distance / radius, 1.0);
    onChanged(hsv.withHue(hue).withSaturation(saturation));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: SettingsStrings.operatorColorWheel,
      child: GestureDetector(
        onTapDown: (d) => _pick(d.localPosition),
        onPanStart: (d) => _pick(d.localPosition),
        onPanUpdate: (d) => _pick(d.localPosition),
        child: CustomPaint(
          size: const Size.square(_size),
          painter: _WheelPainter(hsv),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter(this.hsv);

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            for (var h = 0; h <= 360; h += 60)
              HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
          ],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0x00FFFFFF)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.black.withValues(alpha: 1 - hsv.value),
    );
    // The mark of the chosen color.
    final angle = hsv.hue * math.pi / 180;
    final mark =
        center +
        Offset(math.cos(angle), math.sin(angle)) * (hsv.saturation * radius);
    canvas.drawCircle(
      mark,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
    canvas.drawCircle(
      mark,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.hsv != hsv;
}
