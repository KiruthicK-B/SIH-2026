import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_repositories.dart';
import 'booking_repositories.dart';
import 'catalog_repositories.dart';
import 'farmer_repositories.dart';
import 'remote/remote_admin_repositories.dart';
import 'remote/remote_booking_repositories.dart';
import 'remote/remote_catalog_repositories.dart';
import 'remote/remote_farmer_repositories.dart';
import 'remote/remote_support_repositories.dart';
import 'support_repositories.dart';

/// Phase 2: every provider now resolves to an HTTP-backed implementation
/// (lib/repositories/remote/*) talking to the AGRIVA Node/Postgres backend
/// via lib/core/config/api_config.dart's kApiBaseUrl — nothing that reads
/// through these providers changes. Swap back to a Local*Repository() here
/// to return to the Hive-only Phase 1 behaviour.
final farmerRepositoryProvider = Provider<FarmerRepository>(
  (ref) => RemoteFarmerRepository(),
);
final landRecordRepositoryProvider = Provider<LandRecordRepository>(
  (ref) => RemoteLandRecordRepository(),
);

final cropRepositoryProvider = Provider<CropRepository>(
  (ref) => RemoteCropRepository(),
);
final centreRepositoryProvider = Provider<CentreRepository>(
  (ref) => RemoteCentreRepository(),
);
final slotRepositoryProvider = Provider<SlotRepository>(
  (ref) => RemoteSlotRepository(),
);
final districtRepositoryProvider = Provider<DistrictRepository>(
  (ref) => RemoteDistrictRepository(),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => RemoteBookingRepository(),
);
final queueRepositoryProvider = Provider<QueueRepository>(
  (ref) => RemoteQueueRepository(),
);
final procurementRepositoryProvider = Provider<ProcurementRepository>(
  (ref) => RemoteProcurementRepository(),
);
final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => RemotePaymentRepository(),
);
final rescheduleOfferRepositoryProvider = Provider<RescheduleOfferRepository>(
  (ref) => RemoteRescheduleOfferRepository(),
);
final disruptionRepositoryProvider = Provider<DisruptionRepository>(
  (ref) => RemoteDisruptionRepository(),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => RemoteAdminRepository(),
);
final broadcastRepositoryProvider = Provider<BroadcastRepository>(
  (ref) => RemoteBroadcastRepository(),
);

final grievanceRepositoryProvider = Provider<GrievanceRepository>(
  (ref) => RemoteGrievanceRepository(),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => RemoteNotificationRepository(),
);
final auditLogRepositoryProvider = Provider<AuditLogRepository>(
  (ref) => RemoteAuditLogRepository(),
);
