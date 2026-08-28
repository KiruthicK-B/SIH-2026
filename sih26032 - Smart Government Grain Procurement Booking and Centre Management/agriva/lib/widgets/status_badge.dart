import 'package:flutter/material.dart';

import '../app/theme.dart';

enum StatusTone { success, warning, error, info, inactive }

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
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
