import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../models/farmer.dart';
import '../../repositories/repository_providers.dart';
import '../../state/auth_controller.dart';
import '../../state/data_revision.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/max_width_body.dart';
import '../../widgets/status_badge.dart';
import 'district_providers.dart';

class ManagerVerificationsScreen extends ConsumerStatefulWidget {
  const ManagerVerificationsScreen({super.key});

  @override
  ConsumerState<ManagerVerificationsScreen> createState() =>
      _ManagerVerificationsScreenState();
}

class _ManagerVerificationsScreenState
    extends ConsumerState<ManagerVerificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final userDistrict = user?.district;
    if (userDistrict == null || userDistrict.isEmpty) return const SizedBox.shrink();
    final district = userDistrict;
    final pendingAsync = ref.watch(pendingFarmerVerificationsProvider(district));

    return Scaffold(
      backgroundColor: AgrivaColors.background,
      appBar: AgrivaAppBar(
        title: 'District Farmer Verifications',
        subtitle: 'Document Clearance & Approval',
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
            Tab(text: 'Escalated Cases'),
            Tab(text: 'All Pending in District'),
          ],
        ),
      ),
      body: MaxWidthBody(
        child: pendingAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (farmers) {
            final escalated = farmers
                .where((f) =>
                    f.verificationStatus == FarmerVerificationStatus.escalatedToDistrict)
                .toList();
            final allPending = farmers
                .where((f) =>
                    f.verificationStatus == FarmerVerificationStatus.pendingApproval)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(escalated, isEscalated: true),
                _buildList(allPending, isEscalated: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<Farmer> farmers, {required bool isEscalated}) {
    if (farmers.isEmpty) {
      return EmptyState(
        icon: isEscalated ? Icons.assignment_turned_in_outlined : Icons.verified_user_outlined,
        title: isEscalated ? 'No Escalated Cases' : 'No Pending Verifications',
        message: isEscalated
            ? 'No centres have escalated ambiguous farmer records for district clearance.'
            : 'Every registered farmer in this district has been approved.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: farmers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _DistrictFarmerCard(
        farmer: farmers[i],
        isEscalated: isEscalated,
      ),
    );
  }
}

class _DistrictFarmerCard extends ConsumerStatefulWidget {
  final Farmer farmer;
  final bool isEscalated;
  const _DistrictFarmerCard({required this.farmer, required this.isEscalated});

  @override
  ConsumerState<_DistrictFarmerCard> createState() =>
      _DistrictFarmerCardState();
}

class _DistrictFarmerCardState extends ConsumerState<_DistrictFarmerCard> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    final user = ref.read(authControllerProvider);
    final farmer = widget.farmer;
    final updated = farmer.copyWith(
      verificationStatus: FarmerVerificationStatus.approved,
      isVerified: true,
      verifiedAt: DateTime.now(),
      verifiedBy: user?.name ?? 'District Admin',
    );
    await ref.read(farmerRepositoryProvider).save(updated);
    ref.read(dataRevisionProvider.notifier).bump();
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${farmer.name} verified & approved. Slot booking unlocked.'),
          backgroundColor: AgrivaColors.success,
        ),
      );
    }
  }

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Specify reason for rejecting ${widget.farmer.name}\'s registration:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Land survey patta invalid or fraudulent identity document',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
        rejectionReason: reasonCtrl.text.trim(),
      );
      await ref.read(farmerRepositoryProvider).save(updated);
      ref.read(dataRevisionProvider.notifier).bump();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmer = widget.farmer;
    final cAt = farmer.createdAt;
    final isPendingOverdue = cAt != null &&
        DateTime.now().difference(cAt).inHours > 48;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isEscalated
              ? AgrivaColors.gold
              : (isPendingOverdue ? AgrivaColors.error : AgrivaColors.border),
          width: widget.isEscalated || isPendingOverdue ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      '${farmer.farmerCode} • Assigned: ${farmer.assignedCentreId}',
                      style: const TextStyle(fontSize: 11.5, color: AgrivaColors.textMuted),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: farmer.verificationStatus.label,
                tone: widget.isEscalated ? StatusTone.purple : StatusTone.warning,
              ),
            ],
          ),

          if (isPendingOverdue && !widget.isEscalated) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AgrivaColors.errorBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AgrivaColors.error),
                  SizedBox(width: 6),
                  Text(
                    'Pending > 48 hours without centre operator action',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AgrivaColors.error),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 20),

          Text(
            'Address: ${farmer.fullAddress}',
            style: const TextStyle(fontSize: 12.5, color: AgrivaColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Phone: ${farmer.phone} • Aadhaar: ${Farmer.maskAadhaar(farmer.aadhaarNumber)}',
            style: const TextStyle(fontSize: 12.5, color: AgrivaColors.textSecondary),
          ),

          if (widget.isEscalated && farmer.escalationNotes != null) ...[
            const SizedBox(height: 10),
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
                    '⚠️ Centre Operator Escalation Remarks:',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AgrivaColors.warning),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    farmer.escalationNotes ?? '',
                    style: const TextStyle(fontSize: 12, color: AgrivaColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
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
                      : const Icon(Icons.verified_rounded, size: 18),
                  label: Text(widget.isEscalated ? 'Resolve & Approve' : 'Approve Verification'),
                  onPressed: _busy
                      ? null
                      : () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: 'Approve this farmer?',
                            message:
                                'This confirms ${farmer.name}\'s identity and land records have been verified by the District Administration.',
                            confirmLabel: 'Approve & Unlock Slot',
                          );
                          if (confirmed) await _approve();
                        },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Reject Profile',
                icon: const Icon(Icons.cancel_outlined, color: AgrivaColors.error),
                onPressed: _busy ? null : _reject,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
