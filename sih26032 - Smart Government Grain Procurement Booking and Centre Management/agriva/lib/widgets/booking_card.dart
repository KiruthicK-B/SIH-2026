import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../core/utils/status_mapper.dart';
import '../models/booking.dart';
import '../models/centre.dart';
import '../models/enums.dart';
import '../models/slot.dart';
import 'status_badge.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final Slot slot;
  final ProcurementCentre centre;
  final VoidCallback? onTap;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.slot,
    required this.centre,
    this.onTap,
    this.onReschedule,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canCancel =
        onCancel != null &&
        booking.isActive &&
        booking.checkedInAt == null &&
        booking.status != BookingStatus.rescheduleRequired &&
        booking.status != BookingStatus.waitlisted;
    final canReschedule =
        onReschedule != null &&
        booking.status == BookingStatus.rescheduleRequired;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AgrivaColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AgrivaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('d MMM yyyy, h:mm a').format(slot.start),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                StatusBadge(
                  label: booking.status.label,
                  tone: toneForBookingStatus(booking.status),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              centre.name,
              style: const TextStyle(
                fontSize: 13,
                color: AgrivaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${booking.expectedQuantityQ.toStringAsFixed(0)} Quintals',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AgrivaColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Token ${booking.token}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AgrivaColors.textMuted,
                  ),
                ),
              ],
            ),
            if (canCancel || canReschedule) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (canReschedule)
                    Expanded(
                      child: TextButton(
                        onPressed: onReschedule,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('Reschedule'),
                      ),
                    ),
                  if (canCancel)
                    Expanded(
                      child: TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
