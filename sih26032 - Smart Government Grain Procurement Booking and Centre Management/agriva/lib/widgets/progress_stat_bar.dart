import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Used for both capacity and storage progress (README's CapacityProgressBar
/// / StorageProgressBar collapse into one parameterised widget).
class ProgressStatBar extends StatelessWidget {
  final String label;
  final double current;
  final double max;
  final String Function(double value)? formatter;
  final Color? color;

  const ProgressStatBar({
    super.key,
    required this.label,
    required this.current,
    required this.max,
    this.formatter,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0);
    final fmt = formatter ?? (v) => v.toStringAsFixed(0);
    final barColor =
        color ??
        (percent >= 1
            ? AgrivaColors.error
            : percent >= 0.85
            ? AgrivaColors.warning
            : AgrivaColors.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AgrivaColors.textSecondary,
              ),
            ),
            Text(
              '${fmt(current)} / ${fmt(max)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AgrivaColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 7,
            backgroundColor: AgrivaColors.inactiveBg,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(percent * 100).toStringAsFixed(0)}% occupied',
          style: const TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
        ),
      ],
    );
  }
}
