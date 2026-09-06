import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../models/farmer.dart';
import '../../repositories/repository_providers.dart';
import '../../state/auth_controller.dart';
import '../../state/data_revision.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/max_width_body.dart';
import '../../widgets/status_badge.dart';

final centreFarmersProvider =
    FutureProvider.family<List<Farmer>, String>((ref, centreId) async {
  ref.watch(dataRevisionProvider);
  final allFarmers = await ref.read(farmerRepositoryProvider).getAll();
  return allFarmers.where((f) => f.assignedCentreId == centreId).toList();
});

class OperatorVerificationsScreen extends ConsumerStatefulWidget {
  const OperatorVerificationsScreen({super.key});

  @override
  ConsumerState<OperatorVerificationsScreen> createState() =>
      _OperatorVerificationsScreenState();
}

class _OperatorVerificationsScreenState
    extends ConsumerState<OperatorVerificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final centreId = user?.centreId;
    if (centreId == null || centreId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Centre not assigned')));
    }

    final farmersAsync = ref.watch(centreFarmersProvider(centreId));

    return Scaffold(
      backgroundColor: AgrivaColors.background,
      appBar: AgrivaAppBar(
        title: 'Farmer Verifications',
        subtitle: 'Direct Purchase Centre Review',
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFB2DFDB),
          indicatorColor: const Color(0xFFFCD34D),
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Pending Review'),
            Tab(text: 'Escalated'),
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: MaxWidthBody(
        child: farmersAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => ErrorState(message: e.toString()),
          data: (farmers) {
            final pending = farmers
                .where((f) =>
                    f.verificationStatus == FarmerVerificationStatus.pendingApproval)
                .toList();
            final escalated = farmers
                .where((f) =>
                    f.verificationStatus == FarmerVerificationStatus.escalatedToDistrict)
                .toList();
            final approved = farmers
                .where((f) =>
                    f.verificationStatus == FarmerVerificationStatus.approved)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(pending, isPending: true),
                _buildList(escalated, isEscalated: true),
                _buildList(approved, isApproved: true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(
    List<Farmer> farmers, {
    bool isPending = false,
    bool isEscalated = false,
    bool isApproved = false,
  }) {
    if (farmers.isEmpty) {
      return EmptyState(
        icon: isPending
            ? Icons.checklist_rounded
            : (isEscalated ? Icons.escalator_warning_rounded : Icons.verified_rounded),
        title: isPending
            ? 'No Pending Verifications'
            : (isEscalated ? 'No Escalated Cases' : 'No Approved Farmers Yet'),
        message: isPending
            ? 'All registered farmers mapped to this centre have been reviewed.'
            : (isEscalated
                ? 'No farmers currently forwarded to District Admin.'
                : 'Approved profiles will appear here.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: farmers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _FarmerVerificationCard(
        farmer: farmers[i],
        isPending: isPending,
        isEscalated: isEscalated,
        isApproved: isApproved,
      ),
    );
  }
}

class _FarmerVerificationCard extends ConsumerStatefulWidget {
  final Farmer farmer;
  final bool isPending;
  final bool isEscalated;
  final bool isApproved;

  const _FarmerVerificationCard({
    required this.farmer,
    this.isPending = false,
    this.isEscalated = false,
    this.isApproved = false,
  });

  @override
  ConsumerState<_FarmerVerificationCard> createState() =>
      _FarmerVerificationCardState();
}

class _FarmerVerificationCardState
    extends ConsumerState<_FarmerVerificationCard> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    final user = ref.read(authControllerProvider);
    final updated = widget.farmer.copyWith(
      verificationStatus: FarmerVerificationStatus.approved,
      isVerified: true,
      verifiedAt: DateTime.now(),
      verifiedBy: user?.name ?? 'Centre Operator',
    );
    await ref.read(farmerRepositoryProvider).save(updated);
    ref.read(dataRevisionProvider.notifier).bump();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _escalate() async {
    final noteController = TextEditingController(
      text: 'Survey boundary overlap / require Tahsildar land record clearance.',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.forward_to_inbox_rounded, color: AgrivaColors.warning, size: 24),
            SizedBox(width: 8),
            Text('Move to District Admin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escalate ${widget.farmer.name}\'s profile to District Admin for higher-level review or dispute resolution.',
              style: const TextStyle(fontSize: 13, color: AgrivaColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Escalation Reason / Notes for District Admin',
                hintText: 'e.g. Document mismatch, survey boundary dispute...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AgrivaColors.warning),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Escalate to District Admin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _busy = true);
      final updated = widget.farmer.copyWith(
        verificationStatus: FarmerVerificationStatus.escalatedToDistrict,
        escalationNotes: noteController.text.trim(),
        escalatedAt: DateTime.now(),
      );
      await ref.read(farmerRepositoryProvider).save(updated);
      ref.read(dataRevisionProvider.notifier).bump();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Verification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Specify reason for rejecting this farmer registration. The farmer will be notified.',
              style: TextStyle(fontSize: 13, color: AgrivaColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'e.g. Invalid Aadhaar or unverified land record',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AgrivaColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _busy = true);
      final updated = widget.farmer.copyWith(
        verificationStatus: FarmerVerificationStatus.rejected,
        rejectionReason: reasonController.text.trim(),
      );
      await ref.read(farmerRepositoryProvider).save(updated);
      ref.read(dataRevisionProvider.notifier).bump();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmer = widget.farmer;
    final isPendingLong = farmer.createdAt != null &&
        DateTime.now().difference(farmer.createdAt!).inHours > 48;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPendingLong && widget.isPending
              ? AgrivaColors.warning
              : AgrivaColors.border,
          width: isPendingLong && widget.isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmer.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      '${farmer.farmerCode} • Registered ${farmer.createdAt != null ? DateFormat('d MMM yyyy').format(farmer.createdAt!) : 'Recently'}',
                      style: const TextStyle(fontSize: 11.5, color: AgrivaColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: farmer.verificationStatus.label,
                tone: switch (farmer.verificationStatus) {
                  FarmerVerificationStatus.approved => StatusTone.success,
                  FarmerVerificationStatus.pendingApproval => StatusTone.warning,
                  FarmerVerificationStatus.escalatedToDistrict => StatusTone.purple,
                  FarmerVerificationStatus.rejected => StatusTone.error,
                },
              ),
            ],
          ),

          if (isPendingLong && widget.isPending) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AgrivaColors.warningBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: const [
                  Icon(Icons.schedule_rounded, size: 14, color: AgrivaColors.warning),
                  SizedBox(width: 6),
                  Text(
                    '⚠️ Verification pending > 48 hours (Flagged for District Oversight)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AgrivaColors.warning),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 20),

          // Identity & Address Details
          _detailRow(Icons.phone_rounded, 'Mobile', farmer.phone),
          _detailRow(Icons.fingerprint_rounded, 'Aadhaar', Farmer.maskAadhaar(farmer.aadhaarNumber)),
          _detailRow(Icons.location_on_rounded, 'Address', farmer.fullAddress),

          if (farmer.bankAccountNumber != null && farmer.bankAccountNumber!.isNotEmpty)
            _detailRow(
              Icons.account_balance_rounded,
              'Bank / IFSC',
              '${Farmer.maskAccount(farmer.bankAccountNumber)} (${farmer.bankIfsc ?? "N/A"})',
            ),

          if (widget.isEscalated && farmer.escalationNotes != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AgrivaColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AgrivaColors.gold.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Forwarded to District Admin with Notes:',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AgrivaColors.warning),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    farmer.escalationNotes!,
                    style: const TextStyle(fontSize: 12, color: AgrivaColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],

          if (widget.isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AgrivaColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Approve & Unlock Slot'),
                    onPressed: _busy ? null : _approve,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AgrivaColors.warning,
                      side: const BorderSide(color: AgrivaColors.warning),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                    label: const Text('Escalate', style: TextStyle(fontSize: 12.5)),
                    onPressed: _busy ? null : _escalate,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reject Profile',
                  icon: const Icon(Icons.cancel_outlined, color: AgrivaColors.error),
                  onPressed: _busy ? null : _reject,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AgrivaColors.textMuted),
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AgrivaColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AgrivaColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
