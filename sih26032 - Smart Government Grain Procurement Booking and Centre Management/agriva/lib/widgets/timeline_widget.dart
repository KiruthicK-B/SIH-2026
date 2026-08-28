import 'package:flutter/material.dart';

import '../app/theme.dart';

enum TimelineStepState { done, active, blocked, pending }

class TimelineStepData {
  final String title;
  final String? subtitle;
  final TimelineStepState state;

  const TimelineStepData({
    required this.title,
    this.subtitle,
    required this.state,
  });
}

class TimelineWidget extends StatelessWidget {
  final List<TimelineStepData> steps;

  const TimelineWidget({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(data: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineStepData data;
  final bool isLast;

  const _TimelineRow({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (data.state) {
      TimelineStepState.done => (AgrivaColors.success, Icons.check),
      TimelineStepState.active => (AgrivaColors.primary, null),
      TimelineStepState.blocked => (AgrivaColors.warning, Icons.priority_high),
      TimelineStepState.pending => (AgrivaColors.textMuted, null),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.state == TimelineStepState.pending
                      ? Colors.white
                      : color,
                  border: Border.all(color: color, width: 2),
                ),
                child: icon != null
                    ? Icon(icon, size: 14, color: Colors.white)
                    : data.state == TimelineStepState.active
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(
                      alpha: data.state == TimelineStepState.done ? 0.4 : 0.2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: data.state == TimelineStepState.pending
                          ? AgrivaColors.textMuted
                          : AgrivaColors.textPrimary,
                    ),
                  ),
                  if (data.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AgrivaColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
