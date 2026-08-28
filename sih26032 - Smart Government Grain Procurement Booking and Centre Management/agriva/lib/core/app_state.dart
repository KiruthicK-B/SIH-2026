import '../models/audit_log.dart';
import '../models/booking.dart';
import '../models/centre.dart';
import '../models/disruption.dart';
import '../models/farmer.dart';
import '../models/inspection.dart';
import '../models/notification.dart';
import '../models/payment.dart';
import '../models/procurement.dart';
import '../models/queue_entry.dart';
import '../models/reschedule_offer.dart';
import '../models/slot.dart';
import '../models/user.dart';
import '../models/weighment.dart';

/// The entire AGRIVA frontend state — everything that would normally live
/// in a backend database, held here and persisted to shared_preferences.
class AgrivaAppState {
  final AppUser? currentUser;
  final List<AppUser> users;
  final List<Farmer> farmers;
  final List<ProcurementCentre> centres;
  final List<Slot> slots;
  final List<Booking> bookings;
  final List<QueueEntry> queueEntries;
  final List<Inspection> inspections;
  final List<Weighment> weighments;
  final List<Procurement> procurements;
  final List<Payment> payments;
  final List<Disruption> disruptions;
  final List<NotificationItem> notifications;
  final List<RescheduleOffer> rescheduleOffers;
  final List<AuditLog> auditLogs;

  const AgrivaAppState({
    this.currentUser,
    this.users = const [],
    this.farmers = const [],
    this.centres = const [],
    this.slots = const [],
    this.bookings = const [],
    this.queueEntries = const [],
    this.inspections = const [],
    this.weighments = const [],
    this.procurements = const [],
    this.payments = const [],
    this.disruptions = const [],
    this.notifications = const [],
    this.rescheduleOffers = const [],
    this.auditLogs = const [],
  });

  AgrivaAppState copyWith({
    AppUser? currentUser,
    bool clearCurrentUser = false,
    List<AppUser>? users,
    List<Farmer>? farmers,
    List<ProcurementCentre>? centres,
    List<Slot>? slots,
    List<Booking>? bookings,
    List<QueueEntry>? queueEntries,
    List<Inspection>? inspections,
    List<Weighment>? weighments,
    List<Procurement>? procurements,
    List<Payment>? payments,
    List<Disruption>? disruptions,
    List<NotificationItem>? notifications,
    List<RescheduleOffer>? rescheduleOffers,
    List<AuditLog>? auditLogs,
  }) {
    return AgrivaAppState(
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      users: users ?? this.users,
      farmers: farmers ?? this.farmers,
      centres: centres ?? this.centres,
      slots: slots ?? this.slots,
      bookings: bookings ?? this.bookings,
      queueEntries: queueEntries ?? this.queueEntries,
      inspections: inspections ?? this.inspections,
      weighments: weighments ?? this.weighments,
      procurements: procurements ?? this.procurements,
      payments: payments ?? this.payments,
      disruptions: disruptions ?? this.disruptions,
      notifications: notifications ?? this.notifications,
      rescheduleOffers: rescheduleOffers ?? this.rescheduleOffers,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }

  factory AgrivaAppState.fromJson(Map<String, dynamic> json) => AgrivaAppState(
    currentUser: json['currentUser'] != null
        ? AppUser.fromJson(json['currentUser'])
        : null,
    users: (json['users'] as List).map((e) => AppUser.fromJson(e)).toList(),
    farmers: (json['farmers'] as List).map((e) => Farmer.fromJson(e)).toList(),
    centres: (json['centres'] as List)
        .map((e) => ProcurementCentre.fromJson(e))
        .toList(),
    slots: (json['slots'] as List).map((e) => Slot.fromJson(e)).toList(),
    bookings: (json['bookings'] as List)
        .map((e) => Booking.fromJson(e))
        .toList(),
    queueEntries: (json['queueEntries'] as List)
        .map((e) => QueueEntry.fromJson(e))
        .toList(),
    inspections: (json['inspections'] as List)
        .map((e) => Inspection.fromJson(e))
        .toList(),
    weighments: (json['weighments'] as List)
        .map((e) => Weighment.fromJson(e))
        .toList(),
    procurements: (json['procurements'] as List)
        .map((e) => Procurement.fromJson(e))
        .toList(),
    payments: (json['payments'] as List)
        .map((e) => Payment.fromJson(e))
        .toList(),
    disruptions: (json['disruptions'] as List)
        .map((e) => Disruption.fromJson(e))
        .toList(),
    notifications: (json['notifications'] as List)
        .map((e) => NotificationItem.fromJson(e))
        .toList(),
    rescheduleOffers: (json['rescheduleOffers'] as List)
        .map((e) => RescheduleOffer.fromJson(e))
        .toList(),
    auditLogs: (json['auditLogs'] as List)
        .map((e) => AuditLog.fromJson(e))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'currentUser': currentUser?.toJson(),
    'users': users.map((e) => e.toJson()).toList(),
    'farmers': farmers.map((e) => e.toJson()).toList(),
    'centres': centres.map((e) => e.toJson()).toList(),
    'slots': slots.map((e) => e.toJson()).toList(),
    'bookings': bookings.map((e) => e.toJson()).toList(),
    'queueEntries': queueEntries.map((e) => e.toJson()).toList(),
    'inspections': inspections.map((e) => e.toJson()).toList(),
    'weighments': weighments.map((e) => e.toJson()).toList(),
    'procurements': procurements.map((e) => e.toJson()).toList(),
    'payments': payments.map((e) => e.toJson()).toList(),
    'disruptions': disruptions.map((e) => e.toJson()).toList(),
    'notifications': notifications.map((e) => e.toJson()).toList(),
    'rescheduleOffers': rescheduleOffers.map((e) => e.toJson()).toList(),
    'auditLogs': auditLogs.map((e) => e.toJson()).toList(),
  };
}
