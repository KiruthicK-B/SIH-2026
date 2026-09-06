import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../services/scheduler_service.dart';

class SlotCard extends StatelessWidget {
  final SlotRecommendation recommendation;
  final bool selected;
  final VoidCallback? onTap;

  const SlotCard({
    super.key,
    required this.recommendation,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final slot = recommendation.slot;
    final feasible = recommendation.feasible;
    final timeLabel =
        '${DateFormat('h:mm a').format(slot.start)} – ${DateFormat('h:mm a').format(slot.end)}';

    final borderColor = selected
        ? AgrivaColors.primary
        : (feasible ? AgrivaColors.border : AgrivaColors.border);
    final bgColor = selected ? AgrivaColors.primaryLight : AgrivaColors.surface;

    return Opacity(
      opacity: feasible ? 1 : 0.55,
      child: InkWell(
        onTap: feasible ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: RadioGroup<bool>(
            groupValue: selected ? true : null,
            onChanged: (_) {
              if (feasible) {
                onTap?.call();
              }
            },
            child: Row(
              children: [
                Radio<bool>(value: true, activeColor: AgrivaColors.primary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        feasible
                            ? '${recommendation.remainingFarmerSlots}/${slot.maxFarmers} available · ${recommendation.remainingQuantityQ.toStringAsFixed(0)} Q remaining'
                            : recommendation.reason,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: feasible
                              ? AgrivaColors.textSecondary
                              : AgrivaColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                if (recommendation.isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AgrivaColors.successBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AgrivaColors.success,
                      ),
                    ),
                  )
                else if (!feasible)
                  const Text(
                    'Unavailable',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AgrivaColors.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
