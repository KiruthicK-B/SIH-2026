import '../core/app_state.dart';
import '../models/audit_log.dart';
import '../models/booking.dart';
import '../models/disruption.dart';
import '../models/enums.dart';
import '../models/inspection.dart';
import '../models/notification.dart';
import '../models/payment.dart';
import '../models/procurement.dart';
import '../models/queue_entry.dart';
import '../models/slot.dart';
import '../models/weighment.dart';
import 'demo_centres.dart';
import 'demo_users.dart';

DateTime _at(DateTime day, int hour) =>
    DateTime(day.year, day.month, day.day, hour);

List<Slot> _hourlySlots({
  required String centreId,
  required DateTime day,
  required int startHour,
  required int endHour,
  required int maxFarmers,
  required double maxQuantityQ,
  required List<int> baselineFarmersByHour,
  required List<double> baselineQuantityByHour,
}) {
  final slots = <Slot>[];
  for (var h = startHour; h < endHour; h++) {
    final idx = h - startHour;
    slots.add(
      Slot(
        id: '$centreId-${day.year}${day.month}${day.day}-$h',
        centreId: centreId,
        start: _at(day, h),
        end: _at(day, h + 1),
        maxFarmers: maxFarmers,
        maxQuantityQ: maxQuantityQ,
        baselineFarmers: baselineFarmersByHour[idx],
        baselineQuantityQ: baselineQuantityByHour[idx],
      ),
    );
  }
  return slots;
}

/// Builds a fresh, deterministic AGRIVA demo state anchored to [now] so
/// booking dates are always valid (never in the past) regardless of when
/// the demo is actually run.
AgrivaAppState buildInitialDemoState(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final farmers = buildDemoFarmers();
  final centres = buildDemoCentres();
  final users = buildDemoUsers();

  final slots = <Slot>[
    ..._hourlySlots(
      centreId: centreAId,
      day: today,
      startHour: 8,
      endHour: 17,
      maxFarmers: 10,
      maxQuantityQ: 110,
      baselineFarmersByHour: [7, 8, 5, 4, 6, 3, 2, 9, 10],
      baselineQuantityByHour: [90, 100, 60, 50, 70, 40, 25, 105, 110],
    ),
    ..._hourlySlots(
      centreId: centreAId,
      day: tomorrow,
      startHour: 8,
      endHour: 17,
      maxFarmers: 10,
      maxQuantityQ: 110,
      baselineFarmersByHour: [2, 3, 2, 1, 2, 1, 1, 2, 1],
      baselineQuantityByHour: [20, 30, 20, 10, 20, 10, 10, 20, 10],
    ),
    ..._hourlySlots(
      centreId: centreBId,
      day: today,
      startHour: 8,
      endHour: 17,
      maxFarmers: 10,
      maxQuantityQ: 90,
      baselineFarmersByHour: [9, 9, 10, 9, 8, 9, 9, 10, 9],
      baselineQuantityByHour: [82, 84, 90, 80, 70, 82, 85, 90, 84],
    ),
    ..._hourlySlots(
      centreId: centreBId,
      day: tomorrow,
      startHour: 8,
      endHour: 17,
      maxFarmers: 10,
      maxQuantityQ: 90,
      baselineFarmersByHour: [6, 6, 5, 6, 5, 6, 6, 5, 6],
      baselineQuantityByHour: [50, 50, 45, 50, 45, 50, 50, 45, 50],
    ),
  ];

  Slot slotFor(String centreId, DateTime day, int hour) => slots.firstWhere(
    (s) => s.centreId == centreId && s.start == _at(day, hour),
  );

  // ---- Ravi's history: one completed booking from ~8 days ago ----
  final raviPastDay = today.subtract(const Duration(days: 8));
  final raviPastSlot = Slot(
    id: 'centre-abc-past-ravi',
    centreId: centreAId,
    start: _at(raviPastDay, 9),
    end: _at(raviPastDay, 10),
    maxFarmers: 10,
    maxQuantityQ: 110,
  );
  slots.add(raviPastSlot);

  final raviPastBooking = Booking(
    id: 'AGR-10001',
    farmerId: raviFarmerId,
    centreId: centreAId,
    slotId: raviPastSlot.id,
    expectedQuantityQ: 50,
    status: BookingStatus.completed,
    token: 'T101',
    createdAt: raviPastDay.subtract(const Duration(days: 2)),
    checkedInAt: _at(raviPastDay, 9),
  );

  final raviPastInspection = Inspection(
    id: 'insp-ravi-past',
    bookingId: raviPastBooking.id,
    moisturePercent: 17.5,
    result: InspectionStatus.passed,
    inspector: 'Suresh Babu',
    timestamp: _at(raviPastDay, 9).add(const Duration(minutes: 20)),
  );

  final raviPastWeighment = Weighment(
    id: 'weigh-ravi-past',
    bookingId: raviPastBooking.id,
    expectedQuantityQ: 50,
    actualQuantityQ: 45,
    timestamp: _at(raviPastDay, 9).add(const Duration(minutes: 40)),
  );

  final raviPastProcurement = Procurement(
    id: 'proc-ravi-past',
    bookingId: raviPastBooking.id,
    status: ProcurementStatus.completed,
    acceptedQuantityQ: 45,
    timestamp: _at(raviPastDay, 9).add(const Duration(minutes: 45)),
  );

  final raviPastPayment = Payment(
    id: 'pay-ravi-past',
    bookingId: raviPastBooking.id,
    amount: 45 * 2500,
    status: PaymentStatus.paid,
    lastUpdated: _at(raviPastDay, 9).add(const Duration(hours: 26)),
  );

  // ---- Suresh Babu & Mohan Rao: currently in-progress today at Centre A ----
  final sureshBooking = Booking(
    id: 'AGR-20001',
    farmerId: 'farmer-suresh',
    centreId: centreAId,
    slotId: slotFor(centreAId, today, 8).id,
    expectedQuantityQ: 45,
    status: BookingStatus.processing,
    token: 'T001',
    createdAt: today.subtract(const Duration(days: 1)),
    checkedInAt: _at(today, 8).add(const Duration(minutes: 42)),
  );
  final mohanBooking = Booking(
    id: 'AGR-20002',
    farmerId: 'farmer-mohan',
    centreId: centreAId,
    slotId: slotFor(centreAId, today, 8).id,
    expectedQuantityQ: 60,
    status: BookingStatus.processing,
    token: 'T002',
    createdAt: today.subtract(const Duration(days: 1)),
    checkedInAt: _at(today, 8).add(const Duration(minutes: 51)),
  );

  // ---- Anil Kumar & Vivek Singh: completed today at Centre A ----
  final anilBooking = Booking(
    id: 'AGR-20003',
    farmerId: 'farmer-anil',
    centreId: centreAId,
    slotId: slotFor(centreAId, today, 9).id,
    expectedQuantityQ: 50,
    status: BookingStatus.completed,
    token: 'T003',
    createdAt: today.subtract(const Duration(days: 1)),
    checkedInAt: _at(today, 9),
  );
  final vivekBooking = Booking(
    id: 'AGR-20004',
    farmerId: 'farmer-vivek',
    centreId: centreAId,
    slotId: slotFor(centreAId, today, 9).id,
    expectedQuantityQ: 55,
    status: BookingStatus.completed,
    token: 'T004',
    createdAt: today.subtract(const Duration(days: 1)),
    checkedInAt: _at(today, 9).add(const Duration(minutes: 10)),
  );

  final anilInspection = Inspection(
    id: 'insp-anil',
    bookingId: anilBooking.id,
    moisturePercent: 16.8,
    result: InspectionStatus.passed,
    inspector: 'Suresh Babu',
    timestamp: _at(today, 9).add(const Duration(minutes: 15)),
  );
  final anilWeighment = Weighment(
    id: 'weigh-anil',
    bookingId: anilBooking.id,
    expectedQuantityQ: 50,
    actualQuantityQ: 49.5,
    timestamp: _at(today, 9).add(const Duration(minutes: 30)),
  );
  final anilProcurement = Procurement(
    id: 'proc-anil',
    bookingId: anilBooking.id,
    status: ProcurementStatus.completed,
    acceptedQuantityQ: 49.5,
    timestamp: _at(today, 9).add(const Duration(minutes: 32)),
  );
  final anilPayment = Payment(
    id: 'pay-anil',
    bookingId: anilBooking.id,
    amount: 49.5 * 2500,
    status: PaymentStatus.paid,
    lastUpdated: _at(today, 9).add(const Duration(hours: 2)),
  );

  final vivekInspection = Inspection(
    id: 'insp-vivek',
    bookingId: vivekBooking.id,
    moisturePercent: 17.9,
    result: InspectionStatus.passed,
    inspector: 'Suresh Babu',
    timestamp: _at(today, 9).add(const Duration(minutes: 40)),
  );
  final vivekWeighment = Weighment(
    id: 'weigh-vivek',
    bookingId: vivekBooking.id,
    expectedQuantityQ: 55,
    actualQuantityQ: 54,
    timestamp: _at(today, 9).add(const Duration(minutes: 55)),
  );
  final vivekProcurement = Procurement(
    id: 'proc-vivek',
    bookingId: vivekBooking.id,
    status: ProcurementStatus.completed,
    acceptedQuantityQ: 54,
    timestamp: _at(today, 9).add(const Duration(minutes: 58)),
  );
  final vivekPayment = Payment(
    id: 'pay-vivek',
    bookingId: vivekBooking.id,
    amount: 54 * 2500,
    status: PaymentStatus.processing,
    lastUpdated: _at(today, 9).add(const Duration(hours: 1)),
  );

  // ---- Kumar: waitlisted, ready to be offered released capacity ----
  final kumarWaitlistedBooking = Booking(
    id: 'AGR-30001',
    farmerId: 'farmer-palanikumar',
    centreId: centreAId,
    slotId: slotFor(centreAId, today, 16).id,
    expectedQuantityQ: 30,
    status: BookingStatus.waitlisted,
    token: 'W001',
    createdAt: today.subtract(const Duration(hours: 3)),
  );

  final queueEntries = [
    QueueEntry(
      id: 'q-suresh',
      bookingId: sureshBooking.id,
      token: sureshBooking.token,
      stage: QueueStage.weighment,
      enteredAt: sureshBooking.checkedInAt!,
    ),
    QueueEntry(
      id: 'q-mohan',
      bookingId: mohanBooking.id,
      token: mohanBooking.token,
      stage: QueueStage.qualityCheck,
      enteredAt: mohanBooking.checkedInAt!,
    ),
    QueueEntry(
      id: 'q-anil',
      bookingId: anilBooking.id,
      token: anilBooking.token,
      stage: QueueStage.completed,
      enteredAt: anilBooking.checkedInAt!,
    ),
    QueueEntry(
      id: 'q-vivek',
      bookingId: vivekBooking.id,
      token: vivekBooking.token,
      stage: QueueStage.completed,
      enteredAt: vivekBooking.checkedInAt!,
    ),
  ];

  // ---- Baseline disruption history: one resolved earlier today, none active ----
  final disruptions = [
    Disruption(
      id: 'disr-resolved-1',
      centreId: centreBId,
      type: DisruptionType.networkIssue,
      start: _at(today, 7).add(const Duration(minutes: 30)),
      expectedResolution: _at(today, 8).add(const Duration(minutes: 15)),
      actualResolution: _at(today, 8),
      status: DisruptionStatus.resolved,
      affectedSlotIds: const [],
    ),
  ];

  final notifications = [
    NotificationItem(
      id: 'ntf-welcome',
      userId: raviFarmerId,
      title: 'Welcome to AGRIVA',
      message: 'Book your next procurement slot in a few taps.',
      timestamp: today.subtract(const Duration(days: 1)),
      read: true,
      kind: NotificationKind.general,
    ),
    NotificationItem(
      id: 'ntf-ravi-past-complete',
      userId: raviFarmerId,
      title: 'Procurement Complete',
      message: '45.0 Q accepted at ABC Government Procurement Centre.',
      timestamp: raviPastWeighment.timestamp,
      read: true,
      kind: NotificationKind.procurementComplete,
    ),
    NotificationItem(
      id: 'ntf-ravi-past-payment',
      userId: raviFarmerId,
      title: 'Payment',
      message: 'Payment of ₹1,12,500.00 has been completed.',
      timestamp: raviPastPayment.lastUpdated,
      read: true,
      kind: NotificationKind.payment,
    ),
  ];

  final auditLogs = [
    AuditLog(
      id: 'audit-1',
      actor: 'Ravi Kumar',
      action: 'Booking Completed',
      entity: 'Booking',
      entityId: raviPastBooking.id,
      timestamp: raviPastProcurement.timestamp,
      newState: 'completed',
    ),
    AuditLog(
      id: 'audit-2',
      actor: 'Suresh Babu',
      action: 'Disruption Resolved',
      entity: 'Disruption',
      entityId: 'disr-resolved-1',
      timestamp: _at(today, 8),
      oldState: 'active',
      newState: 'resolved',
    ),
  ];

  return AgrivaAppState(
    currentUser: null,
    users: users,
    farmers: farmers,
    centres: centres,
    slots: slots,
    bookings: [
      raviPastBooking,
      sureshBooking,
      mohanBooking,
      anilBooking,
      vivekBooking,
      kumarWaitlistedBooking,
    ],
    queueEntries: queueEntries,
    inspections: [raviPastInspection, anilInspection, vivekInspection],
    weighments: [raviPastWeighment, anilWeighment, vivekWeighment],
    procurements: [raviPastProcurement, anilProcurement, vivekProcurement],
    payments: [raviPastPayment, anilPayment, vivekPayment],
    disruptions: disruptions,
    notifications: notifications,
    rescheduleOffers: const [],
    auditLogs: auditLogs,
  );
}
