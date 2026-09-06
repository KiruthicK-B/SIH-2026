import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../models/enums.dart';
import '../models/notification.dart';

class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

  const NotificationTile({
    super.key,
    required this.item,
    this.onTap,
    this.onRetry,
  });

  IconData get _icon => switch (item.type) {
    NotificationType.slotConfirmation => Icons.check_circle_outline,
    NotificationType.reminder => Icons.access_time_outlined,
    NotificationType.delay => Icons.warning_amber_outlined,
    NotificationType.rescheduleRequired => Icons.event_repeat_outlined,
    NotificationType.newSlotOffered => Icons.calendar_today_outlined,
    NotificationType.qualityResult => Icons.inventory_2_outlined,
    NotificationType.procurementComplete => Icons.scale_outlined,
    NotificationType.paymentUpdate => Icons.payments_outlined,
    NotificationType.rejection => Icons.report_gmailerrorred_outlined,
    NotificationType.grievanceUpdate => Icons.support_agent_outlined,
    NotificationType.broadcast => Icons.campaign_outlined,
    NotificationType.queueUpdate => Icons.groups_outlined,
    NotificationType.general => Icons.notifications_none_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AgrivaColors.border)),
          color: item.read
              ? Colors.transparent
              : AgrivaColors.primaryLight.withValues(alpha: 0.35),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AgrivaColors.primaryLight,
              child: Icon(_icon, size: 16, color: AgrivaColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AgrivaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM, h:mm a').format(item.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AgrivaColors.textMuted,
                    ),
                  ),
                  if (item.deliveryFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Text(
                            'Notification not delivered.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AgrivaColors.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onRetry,
                            child: const Text(
                              'Retry',
                              style: TextStyle(
                                fontSize: 11,
                                color: AgrivaColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
