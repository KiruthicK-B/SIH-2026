import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'status_badge.dart';

class AlertBanner extends StatelessWidget {
  final String title;
  final String message;
  final StatusTone tone;
  final IconData? icon;

  const AlertBanner({
    super.key,
    required this.title,
    required this.message,
    this.tone = StatusTone.warning,
    this.icon,
  });

  (Color, Color, IconData) get _style => switch (tone) {
    StatusTone.success => (
      AgrivaColors.success,
      AgrivaColors.successBg,
      Icons.check_circle_outline,
    ),
    StatusTone.warning => (
      AgrivaColors.warning,
      AgrivaColors.warningBg,
      Icons.warning_amber_outlined,
    ),
    StatusTone.error => (
      AgrivaColors.error,
      AgrivaColors.errorBg,
      Icons.error_outline,
    ),
    StatusTone.info => (
      AgrivaColors.info,
      AgrivaColors.infoBg,
      Icons.info_outline,
    ),
    StatusTone.inactive => (
      AgrivaColors.textMuted,
      AgrivaColors.inactiveBg,
      Icons.circle_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg, defaultIcon) = _style;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: AgrivaColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
