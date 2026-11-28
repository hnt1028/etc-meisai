import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

DateTime _dayOf(DateTime time) => DateTime(time.year, time.month, time.day);

/// Where the line starts. A line without an entrance starts at its exit.
DateTime _startOf(StatementLineDTO line) => line.entranceAt ?? line.exitAt;

/// Every day that has at least one statement line, oldest first. A line that
/// runs over midnight belongs to each day it touches.
List<DateTime> timelineDays(List<StatementLineDTO> lines) {
  final days = <DateTime>{};
  for (final line in lines) {
    var day = _dayOf(_startOf(line));
    final last = _dayOf(line.exitAt);
    while (!day.isAfter(last)) {
      days.add(day);
      day = DateTime(day.year, day.month, day.day + 1);
    }
  }
  return days.toList()..sort();
}

/// The lines that touch [day], earliest start first.
List<StatementLineDTO> linesOfDay(List<StatementLineDTO> lines, DateTime day) {
  final matched = lines
      .where(
        (l) =>
            !_dayOf(_startOf(l)).isAfter(day) &&
            !_dayOf(l.exitAt).isBefore(day),
      )
      .toList();
  final indexed = matched.asMap().entries.toList()
    ..sort((a, b) {
      final byStart = _startOf(a.value).compareTo(_startOf(b.value));
      return byStart != 0 ? byStart : a.key.compareTo(b.key);
    });
  return [for (final e in indexed) e.value];
}

/// The part of [day] (0.0 to 1.0) that [line] covers. A line without an
/// entrance has the same start and end.
({double start, double end}) spanOfDay(StatementLineDTO line, DateTime day) {
  final dayStart = day;
  final dayEnd = DateTime(day.year, day.month, day.day + 1);
  double fraction(DateTime time) {
    final clipped = time.isBefore(dayStart)
        ? dayStart
        : (time.isAfter(dayEnd) ? dayEnd : time);
    return clipped.difference(dayStart).inSeconds /
        dayEnd.difference(dayStart).inSeconds;
  }

  return (start: fraction(_startOf(line)), end: fraction(line.exitAt));
}

/// The timeline of SCR-002: the statement lines of one day as bars on a time
/// axis from 0:00 to 24:00.
class StatementTimeline extends ConsumerWidget {
  const StatementTimeline({super.key, required this.lines});

  final List<StatementLineDTO> lines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = timelineDays(lines);
    final selected = ref.watch(timelineDayProvider);
    final day = selected != null && days.contains(selected)
        ? selected
        : days.last;
    final index = days.indexOf(day);
    final controller = ref.read(timelineDayProvider.notifier);
    final dayLines = linesOfDay(lines, day);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: index > 0
                    ? () => controller.select(days[index - 1])
                    : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text(StatementListStrings.previousDay),
              ),
              Expanded(
                child: Text(
                  formatDate(day),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: index < days.length - 1
                    ? () => controller.select(days[index + 1])
                    : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text(StatementListStrings.nextDay),
                iconAlignment: IconAlignment.end,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) => _Chart(
                width: constraints.maxWidth,
                day: day,
                lines: dayLines,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A bar is never narrower than this, so that a short use can be seen and tapped.
const _minBarWidth = 6.0;

class _Chart extends StatelessWidget {
  const _Chart({required this.width, required this.day, required this.lines});

  final double width;
  final DateTime day;
  final List<StatementLineDTO> lines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        SizedBox(
          // As tall as the text, which can be made larger in the settings.
          height: MediaQuery.textScalerOf(context).scale(20),
          child: Stack(
            children: [
              for (final hour in const [0, 6, 12, 18, 24])
                Positioned(
                  left: (width * hour / 24 - 10).clamp(0.0, width - 20),
                  width: 20,
                  child: Text(
                    '$hour',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
        for (var i = 0; i < lines.length; i++)
          _Row(
            key: ValueKey('timeline-row-$i'),
            barKey: ValueKey('timeline-bar-$i'),
            width: width,
            line: lines[i],
            span: spanOfDay(lines[i], day),
            color: scheme.primary,
            pendingColor: scheme.error,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.barKey,
    required this.width,
    required this.line,
    required this.span,
    required this.color,
    required this.pendingColor,
  });

  final Key barKey;
  final double width;
  final StatementLineDTO line;
  final ({double start, double end}) span;
  final Color color;
  final Color pendingColor;

  @override
  Widget build(BuildContext context) {
    final pending = line.status == ConfirmationStatusValue.pending;
    final barWidth = ((span.end - span.start) * width).clamp(
      _minBarWidth,
      width,
    );
    final left = (span.start * width).clamp(0.0, width - barWidth);

    return InkWell(
      onTap: () => context.push('/statements/detail', extra: line),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${StatementListStrings.route(line.entranceIc, line.exitIc)}'
              '　${formatYen(line.fare)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 16,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  ),
                  for (final quarter in const [0.25, 0.5, 0.75])
                    Positioned(
                      left: width * quarter,
                      top: 0,
                      bottom: 0,
                      width: 1,
                      child: ColoredBox(color: Theme.of(context).dividerColor),
                    ),
                  Positioned(
                    left: left,
                    width: barWidth,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      key: barKey,
                      decoration: BoxDecoration(
                        color: pending ? null : color,
                        border: pending
                            ? Border.all(color: pendingColor, width: 2)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
