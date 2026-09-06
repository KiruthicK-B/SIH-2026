import 'package:flutter/material.dart';

import '../app/theme.dart';

enum StatusTone { success, warning, error, info, inactive, purple }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusTone tone;

  const StatusBadge({super.key, required this.label, required this.tone});

  (Color, Color) get _colors => switch (tone) {
    StatusTone.success => (AgrivaColors.success, AgrivaColors.successBg),
    StatusTone.warning => (AgrivaColors.warning, AgrivaColors.warningBg),
    StatusTone.error => (AgrivaColors.error, AgrivaColors.errorBg),
    StatusTone.info => (AgrivaColors.info, AgrivaColors.infoBg),
    StatusTone.inactive => (AgrivaColors.inactive, AgrivaColors.inactiveBg),
    StatusTone.purple => (const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (fg, bg) = isDark ? _darkColors : _colors;
    final borderColor = isDark ? fg.withValues(alpha: 0.35) : statusToneBorder(tone.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  (Color, Color) get _darkColors => switch (tone) {
    StatusTone.success => (const Color(0xFF4ADE80), const Color(0x264ADE80)),
    StatusTone.warning => (const Color(0xFFFBBF24), const Color(0x26FBBF24)),
    StatusTone.error => (const Color(0xFFF87171), const Color(0x26F87171)),
    StatusTone.info => (const Color(0xFF60A5FA), const Color(0x2660A5FA)),
    StatusTone.inactive => (const Color(0xFF94A3B8), const Color(0x2694A3B8)),
    StatusTone.purple => (const Color(0xFFA78BFA), const Color(0x26A78BFA)),
  };
}
