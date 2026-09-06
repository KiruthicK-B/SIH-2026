import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_repositories.dart';
import 'booking_repositories.dart';
import 'catalog_repositories.dart';
import 'farmer_repositories.dart';
import 'local/local_admin_repositories.dart';
import 'local/local_booking_repositories.dart';
import 'local/local_catalog_repositories.dart';
import 'local/local_farmer_repositories.dart';
import 'local/local_support_repositories.dart';
import 'support_repositories.dart';

/// Every provider here resolves to a Phase-1 (Hive/local) implementation.
/// Swapping to a Phase-2 backend means changing only the right-hand side of
/// these `Provider` bodies — nothing that reads through them changes.
final farmerRepositoryProvider = Provider<FarmerRepository>(
  (ref) => LocalFarmerRepository(),
);
final landRecordRepositoryProvider = Provider<LandRecordRepository>(
  (ref) => LocalLandRecordRepository(),
);

final cropRepositoryProvider = Provider<CropRepository>(
  (ref) => LocalCropRepository(),
);
final centreRepositoryProvider = Provider<CentreRepository>(
  (ref) => LocalCentreRepository(),
);
final slotRepositoryProvider = Provider<SlotRepository>(
  (ref) => LocalSlotRepository(),
);
final districtRepositoryProvider = Provider<DistrictRepository>(
  (ref) => LocalDistrictRepository(),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => LocalBookingRepository(),
);
final queueRepositoryProvider = Provider<QueueRepository>(
  (ref) => LocalQueueRepository(),
);
final procurementRepositoryProvider = Provider<ProcurementRepository>(
  (ref) => LocalProcurementRepository(),
);
final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => LocalPaymentRepository(),
);
final rescheduleOfferRepositoryProvider = Provider<RescheduleOfferRepository>(
  (ref) => LocalRescheduleOfferRepository(),
);
final disruptionRepositoryProvider = Provider<DisruptionRepository>(
  (ref) => LocalDisruptionRepository(),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => LocalAdminRepository(),
);
final broadcastRepositoryProvider = Provider<BroadcastRepository>(
  (ref) => LocalBroadcastRepository(),
);

final grievanceRepositoryProvider = Provider<GrievanceRepository>(
  (ref) => LocalGrievanceRepository(),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => LocalNotificationRepository(),
);
final auditLogRepositoryProvider = Provider<AuditLogRepository>(
  (ref) => LocalAuditLogRepository(),
);
