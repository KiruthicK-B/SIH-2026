import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../state/centre_admin_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_states.dart';
import '../../widgets/max_width_body.dart';

class DeclareDisruptionScreen extends ConsumerStatefulWidget {
  const DeclareDisruptionScreen({super.key});

  @override
  ConsumerState<DeclareDisruptionScreen> createState() => _DeclareDisruptionScreenState();
}

class _DeclareDisruptionScreenState extends ConsumerState<DeclareDisruptionScreen> {
  DisruptionType _type = DisruptionType.weighingMachineFailure;
  int _resolutionMinutes = 75;
  final Set<String> _affectedSlotIds = {};
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final centreId = user?.centreId;
    if (centreId == null || centreId.isEmpty) return const SizedBox.shrink();
    final centreAsync = ref.watch(centreByIdProvider(centreId));
    final now = DateTime.now();
    final slotsAsync = ref.watch(slotsForCentreAndDateProvider((centreId: centreId, date: now)));
    final disruptionsAsync = ref.watch(disruptionsForCentreProvider(centreId));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Disruptions'),
      body: MaxWidthBody(
        child: centreAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (centre) {
            if (centre == null) return const ErrorState();
            final upcomingSlots = (slotsAsync.value ?? const [])
                .where((s) => s.end.isAfter(now))
                .toList()
              ..sort((a, b) => a.start.compareTo(b.start));
            final activeDisruptions = (disruptionsAsync.value ?? const [])
                .where((d) => d.status == DisruptionStatus.active)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeDisruptions.isNotEmpty) ...[
                  const Text('Active Disruptions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  for (final d in activeDisruptions)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AgrivaColors.warningBg, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.type.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(
                                  'Expected resolution: ${DateFormat('h:mm a').format(d.expectedResolution)}',
                                  style: const TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final r = await ref.read(centreAdminControllerProvider).resolveDisruption(d.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
                              }
                            },
                            child: const Text('Resolve'),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 32),
                ],
                const Text('Declare Disruption', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(centre.name, style: const TextStyle(color: AgrivaColors.textSecondary)),
                const SizedBox(height: 16),
                const Text('Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: AgrivaColors.border), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DisruptionType>(
                      value: _type,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      items: DisruptionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                      onChanged: (t) => setState(() => _type = t!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Expected Resolution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [30, 60, 75, 120].map((m) {
                    final selected = _resolutionMinutes == m;
                    return ChoiceChip(
                      label: Text('$m min'),
                      selected: selected,
                      onSelected: (_) => setState(() => _resolutionMinutes = m),
                      selectedColor: AgrivaColors.primaryLight,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Affected Slots', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: upcomingSlots.map((s) {
                    final selected = _affectedSlotIds.contains(s.id);
                    return FilterChip(
                      label: Text('${DateFormat('h:mm a').format(s.start)}–${DateFormat('h:mm a').format(s.end)}'),
                      selected: selected,
                      onSelected: (v) => setState(() => v ? _affectedSlotIds.add(s.id) : _affectedSlotIds.remove(s.id)),
                      selectedColor: AgrivaColors.primaryLight,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Declare Disruption',
                  loading: _submitting,
                  onPressed: _affectedSlotIds.isEmpty
                      ? null
                      : () async {
                          setState(() => _submitting = true);
                          final result = await ref.read(centreAdminControllerProvider).declareDisruption(
                                centreId: centreId,
                                type: _type,
                                expectedResolution: DateTime.now().add(Duration(minutes: _resolutionMinutes)),
                                affectedSlotIds: _affectedSlotIds.toList(),
                              );
                          setState(() {
                            _submitting = false;
                            _affectedSlotIds.clear();
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
                          }
                        },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
