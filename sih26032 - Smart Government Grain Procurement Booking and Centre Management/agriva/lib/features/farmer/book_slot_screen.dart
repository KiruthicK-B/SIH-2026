import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/centre.dart';
import '../../providers/app_state_provider.dart';
import '../../services/scheduler_service.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/slot_card.dart';
import '../../widgets/max_width_body.dart';

class BookSlotScreen extends ConsumerStatefulWidget {
  const BookSlotScreen({super.key});

  @override
  ConsumerState<BookSlotScreen> createState() => _BookSlotScreenState();
}

class _BookSlotScreenState extends ConsumerState<BookSlotScreen> {
  int _step = 0;
  ProcurementCentre? _centre;
  DateTime? _date;
  final _quantityController = TextEditingController(text: '50');
  String? _quantityError;
  SlotRecommendation? _selectedSlot;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final centres = ref.read(appStateProvider).centres;
    _centre = centres.first;
    _date = DateTime.now();
  }

  double? get _quantity => double.tryParse(_quantityController.text);

  bool _validateStep1() {
    if (_centre == null) return false;
    if (_date == null ||
        _date!.isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        )) {
      return false;
    }
    final q = _quantity;
    if (q == null || q <= 0) {
      setState(() => _quantityError = 'Enter a quantity greater than 0.');
      return false;
    }
    setState(() => _quantityError = null);
    return true;
  }

  Future<void> _confirm() async {
    if (_selectedSlot == null) return;
    setState(() => _submitting = true);
    final notifier = ref.read(appStateProvider.notifier);
    final farmerId = ref.read(appStateProvider).currentUser!.id;
    final result = notifier.bookSlot(
      farmerId: farmerId,
      slotId: _selectedSlot!.slot.id,
      expectedQuantityQ: _quantity!,
    );
    setState(() => _submitting = false);

    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Slot Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            const SizedBox(height: 6),
            Text(
              'Booking ID: ${result.id}',
              style: const TextStyle(
                color: AgrivaColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    context.pushReplacement('/farmer/booking/${result.id}');
  }

  @override
  Widget build(BuildContext context) {
    final centres = ref.watch(appStateProvider).centres;

    return Scaffold(
      appBar: AgrivaAppBar(
        title: _step == 0
            ? 'Book New Slot'
            : _step == 1
            ? 'Select Time Slot'
            : 'Confirm Booking',
      ),
      body: MaxWidthBody(
        child: Column(
          children: [
            _StepIndicator(step: _step),
            Expanded(
              child: switch (_step) {
                0 => _Step1(
                  centres: centres,
                  selectedCentre: _centre,
                  onCentreChanged: (c) => setState(() => _centre = c),
                  date: _date!,
                  onDateChanged: (d) => setState(() => _date = d),
                  quantityController: _quantityController,
                  quantityError: _quantityError,
                ),
                1 => _Step2(
                  centre: _centre!,
                  date: _date!,
                  quantity: _quantity ?? 0,
                  selectedSlot: _selectedSlot,
                  onSelect: (r) => setState(() => _selectedSlot = r),
                ),
                _ => _Step3(
                  centre: _centre!,
                  date: _date!,
                  quantity: _quantity ?? 0,
                  slot: _selectedSlot,
                ),
              },
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _step == 2
                    ? Column(
                        children: [
                          PrimaryButton(
                            label: 'Confirm Booking',
                            loading: _submitting,
                            onPressed: _confirm,
                          ),
                          const SizedBox(height: 10),
                          SecondaryButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          if (_step > 0)
                            Expanded(
                              child: SecondaryButton(
                                label: 'Previous',
                                onPressed: () => setState(() => _step -= 1),
                              ),
                            ),
                          if (_step > 0) const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Next',
                              onPressed: () {
                                if (_step == 0) {
                                  if (_validateStep1())
                                    setState(() => _step = 1);
                                } else if (_selectedSlot != null &&
                                    _selectedSlot!.feasible) {
                                  setState(() => _step = 2);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  static const labels = ['Centre & Date', 'Select Slot', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Column(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: i <= step
                      ? AgrivaColors.primary
                      : AgrivaColors.inactiveBg,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i <= step ? Colors.white : AgrivaColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: i <= step
                        ? AgrivaColors.textPrimary
                        : AgrivaColors.textMuted,
                  ),
                ),
              ],
            ),
            if (i < labels.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: -12,
                  ),
                  color: i < step ? AgrivaColors.primary : AgrivaColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  final List<ProcurementCentre> centres;
  final ProcurementCentre? selectedCentre;
  final ValueChanged<ProcurementCentre> onCentreChanged;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final TextEditingController quantityController;
  final String? quantityError;

  const _Step1({
    required this.centres,
    required this.selectedCentre,
    required this.onCentreChanged,
    required this.date,
    required this.onDateChanged,
    required this.quantityController,
    required this.quantityError,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Select Centre',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AgrivaColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProcurementCentre>(
              value: selectedCentre,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              items: centres
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (c) => c != null ? onCentreChanged(c) : null,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Select Date',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 14)),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AgrivaColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('d MMM yyyy').format(date)),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AgrivaColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        AppTextField(
          label: 'Expected Quantity (Quintals)',
          controller: quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: quantityError,
          suffixText: 'Q',
        ),
      ],
    );
  }
}

class _Step2 extends ConsumerWidget {
  final ProcurementCentre centre;
  final DateTime date;
  final double quantity;
  final SlotRecommendation? selectedSlot;
  final ValueChanged<SlotRecommendation> onSelect;

  const _Step2({
    required this.centre,
    required this.date,
    required this.quantity,
    required this.selectedSlot,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmerId = ref.watch(appStateProvider).currentUser!.id;
    final recs = ref
        .watch(appStateProvider.notifier)
        .recommendSlots(
          farmerId: farmerId,
          centreId: centre.id,
          date: date,
          expectedQuantityQ: quantity,
        );

    if (selectedSlot == null) {
      final recommended = recs.where((r) => r.isRecommended).toList();
      if (recommended.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => onSelect(recommended.first),
        );
      }
    }

    if (recs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No slots available for this date.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = recs[i];
        return SlotCard(
          recommendation: r,
          selected: selectedSlot?.slot.id == r.slot.id,
          onTap: () => onSelect(r),
        );
      },
    );
  }
}

class _Step3 extends ConsumerWidget {
  final ProcurementCentre centre;
  final DateTime date;
  final double quantity;
  final SlotRecommendation? slot;

  const _Step3({
    required this.centre,
    required this.date,
    required this.quantity,
    required this.slot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (slot == null) return const SizedBox.shrink();
    final farmerId = ref.watch(appStateProvider).currentUser!.id;
    final farmer = ref
        .watch(appStateProvider)
        .farmers
        .firstWhere((f) => f.id == farmerId);
    final departure = slot!.slot.start.subtract(
      Duration(minutes: farmer.estimatedTravelMinutes),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AgrivaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _SummaryRow('Centre', centre.name),
              _SummaryRow('Date', DateFormat('d MMM yyyy').format(date)),
              _SummaryRow(
                'Time Slot',
                '${DateFormat('h:mm a').format(slot!.slot.start)} – ${DateFormat('h:mm a').format(slot!.slot.end)}',
              ),
              _SummaryRow(
                'Expected Quantity',
                '${quantity.toStringAsFixed(0)} Quintals',
              ),
              const Divider(height: 24),
              const Text(
                'Note',
                style: TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please reach centre 30 mins before your slot time.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AgrivaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Token will be generated after confirmation · recommended departure ${DateFormat('h:mm a').format(departure)} (${farmer.estimatedTravelMinutes} min travel)',
          style: const TextStyle(fontSize: 11.5, color: AgrivaColors.textMuted),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AgrivaColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
