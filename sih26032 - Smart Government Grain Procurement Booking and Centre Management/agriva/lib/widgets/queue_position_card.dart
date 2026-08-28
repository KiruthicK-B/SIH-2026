import 'package:flutter/material.dart';

import '../app/theme.dart';

class QueuePositionCard extends StatelessWidget {
  final int position;
  final int totalInQueue;
  final int estimatedWaitMinutes;

  const QueuePositionCard({
    super.key,
    required this.position,
    required this.totalInQueue,
    required this.estimatedWaitMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AgrivaColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AgrivaColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR QUEUE POSITION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AgrivaColors.primaryDark,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  position <= 0 ? '—' : '$position / $totalInQueue',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AgrivaColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: AgrivaColors.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated Wait',
                style: TextStyle(
                  fontSize: 11,
                  color: AgrivaColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$estimatedWaitMinutes min',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AgrivaColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
