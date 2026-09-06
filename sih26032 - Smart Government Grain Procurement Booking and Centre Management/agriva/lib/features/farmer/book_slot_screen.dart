import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/centre.dart';
import '../../models/crop.dart';
import '../../models/enums.dart';
import '../../models/farmer.dart';
import '../../services/scheduler_service.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_states.dart';
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
  Crop? _crop;
  ProcurementCentre? _centre;
  DateTime? _date;
  final _quantityController = TextEditingController(text: '50');
  String? _quantityError;
  SlotRecommendation? _selectedSlot;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // If opened in the evening (after 16:00), default date to tomorrow for reviewer convenience
    if (now.hour >= 16) {
      _date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    } else {
      _date = DateTime(now.year, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double? get _quantity => double.tryParse(_quantityController.text);

  bool _validateStep1() {
    if (_centre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a procurement centre.')),
      );
      return false;
    }
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a procurement date.')),
      );
      return false;
    }
    final q = _quantity;
    if (q == null || q <= 0) {
      setState(() => _quantityError = 'Enter a valid quantity greater than 0 Q');
      return false;
    }
    setState(() => _quantityError = null);
    return true;
  }

  Future<void> _confirm() async {
    if (_selectedSlot == null) return;
    setState(() => _submitting = true);
    final farmerId = ref.read(authControllerProvider)!.id;
    final result = await ref.read(bookingControllerProvider).bookSlot(
      farmerId: farmerId,
      slotId: _selectedSlot!.slot.id,
      expectedQuantityQ: _quantity!,
    );
    setState(() => _submitting = false);

    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AgrivaColors.error,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AgrivaColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Slot Confirmed!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: TextStyle(fontSize: 14, color: AgrivaColors.textPrimaryFor(context)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AgrivaColors.primaryLight50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AgrivaColors.borderFor(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, color: AgrivaColors.primaryDark, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Booking Reference: ${result.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AgrivaColors.primaryDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AgrivaColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('View Booking Slip'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    context.pushReplacement('/farmer/booking/${result.id}');
  }

  @override
  Widget build(BuildContext context) {
    final centresAsync = ref.watch(centresProvider);
    final cropsAsync = ref.watch(activeCropsProvider);
    final farmerId = ref.watch(authControllerProvider)!.id;
    final farmerAsync = ref.watch(farmerByIdProvider(farmerId));

    return Scaffold(
      backgroundColor: AgrivaColors.backgroundFor(context),
      appBar: AgrivaAppBar(
        title: _step == 0
            ? 'Book Grain Slot'
            : _step == 1
                ? 'Select Time Slot'
                : 'Confirm Booking',
        subtitle: _step == 0
            ? 'Step 1 of 3: Crop & Centre'
            : _step == 1
                ? 'Step 2 of 3: Recommended Slot'
                : 'Step 3 of 3: Final Verification',
      ),
      body: MaxWidthBody(
        child: centresAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (centres) {
            return cropsAsync.when(
              loading: () => const LoadingState(),
              error: (e, st) => const ErrorState(),
              data: (crops) {
                return farmerAsync.when(
                  loading: () => const LoadingState(),
                  error: (e, st) => const ErrorState(),
                  data: (farmer) {
                    if (farmer != null && !farmer.isVerified) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF8E1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_clock_rounded,
                                  color: AgrivaColors.gold,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Verification Pending',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                farmer.verificationStatus == FarmerVerificationStatus.escalatedToDistrict
                                    ? 'Your profile is currently under review with the District Administration.\n\nSlot booking will unlock once verification is approved.'
                                    : 'Your registration is currently pending verification by your assigned Centre Operator (${farmer.assignedCentreId.isNotEmpty ? farmer.assignedCentreId : "regional centre"}).\n\nSlot booking will automatically unlock once your documents are approved.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AgrivaColors.textSecondaryFor(context),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AgrivaColors.primary),
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                label: const Text('Back to Home', style: TextStyle(color: Colors.white)),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    _crop ??= crops.firstOrNull;

                    // Filter centres that support selected crop
                    final supportedCentres = centres.where((c) {
                      if (_crop == null) return true;
                      return c.supportedCrops.any((s) => s.cropId == _crop!.id);
                    }).toList();

                    final displayCentres = supportedCentres.isNotEmpty ? supportedCentres : centres;

                    // Sort centres prioritizing assigned centre, then shortest distance
                    displayCentres.sort((a, b) {
                      if (farmer != null && farmer.assignedCentreId.isNotEmpty) {
                        if (a.id == farmer.assignedCentreId) return -1;
                        if (b.id == farmer.assignedCentreId) return 1;
                      }
                      final distA = _calculateDistance(a, farmer);
                      final distB = _calculateDistance(b, farmer);
                      return distA.compareTo(distB);
                    });

                    _centre ??= displayCentres.firstOrNull;

                    return Column(
                      children: [
                        _StepIndicator(step: _step),
                        Expanded(
                          child: switch (_step) {
                            0 => _Step1(
                                crops: crops,
                                selectedCrop: _crop,
                                onCropChanged: (c) {
                                  setState(() {
                                    _crop = c;
                                    // Reset centre to first supported centre
                                    final match = centres.where((cnt) =>
                                        cnt.supportedCrops.any((s) => s.cropId == c.id)).toList();
                                    if (match.isNotEmpty) {
                                      _centre = match.first;
                                    }
                                  });
                                },
                                centres: displayCentres,
                                selectedCentre: _centre,
                                onCentreChanged: (c) => setState(() => _centre = c),
                                date: _date!,
                                onDateChanged: (d) => setState(() => _date = d),
                                quantityController: _quantityController,
                                quantityError: _quantityError,
                                farmer: farmer,
                              ),
                            1 => _Step2(
                                centre: _centre!,
                                date: _date!,
                                quantity: _quantity ?? 50,
                                selectedSlot: _selectedSlot,
                                onSelect: (r) => setState(() => _selectedSlot = r),
                              ),
                            _ => _Step3(
                                crop: _crop,
                                centre: _centre!,
                                date: _date!,
                                quantity: _quantity ?? 50,
                                slot: _selectedSlot,
                              ),
                          },
                        ),
                        SafeArea(
                          top: false,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AgrivaColors.surfaceFor(context),
                              border: Border(top: BorderSide(color: AgrivaColors.borderFor(context))),
                            ),
                            child: _step == 2
                                ? Column(
                                    children: [
                                      PrimaryButton(
                                        label: 'Confirm & Generate Token',
                                        loading: _submitting,
                                        icon: Icons.check_circle_outline_rounded,
                                        onPressed: _confirm,
                                      ),
                                      const SizedBox(height: 8),
                                      SecondaryButton(
                                        label: 'Back to Slots',
                                        onPressed: () => setState(() => _step = 1),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      if (_step > 0)
                                        Expanded(
                                          child: SecondaryButton(
                                            label: 'Previous',
                                            icon: Icons.arrow_back_rounded,
                                            onPressed: () => setState(() => _step -= 1),
                                          ),
                                        ),
                                      if (_step > 0) const SizedBox(width: 12),
                                      Expanded(
                                        child: PrimaryButton(
                                          label: _step == 0 ? 'View Available Slots' : 'Proceed to Summary',
                                          icon: Icons.arrow_forward_rounded,
                                          onPressed: () {
                                            if (_step == 0) {
                                              if (_validateStep1()) setState(() => _step = 1);
                                            } else if (_selectedSlot != null && _selectedSlot!.feasible) {
                                              setState(() => _step = 2);
                                            } else if (_selectedSlot == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Please select a time slot.')),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(_selectedSlot!.reason)),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  static double _calculateDistance(ProcurementCentre centre, Farmer? farmer) {
    if (farmer == null) return 12.0;
    if (centre.district == farmer.district) {
      if (centre.id.contains('nagpur') || centre.id.contains('01')) {
        return farmer.distanceKm;
      }
      return (farmer.distanceKm + 14.5);
    }
    // Cross-district centre distance
    return 42.0 + (centre.name.hashCode.abs() % 28);
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  static const labels = ['Crop & Centre', 'Select Slot', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AgrivaColors.surfaceFor(context),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: i <= step ? AgrivaColors.primary : AgrivaColors.inactiveBg,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i <= step ? Colors.white : AgrivaColors.textMutedFor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                    color: i <= step ? AgrivaColors.textPrimaryFor(context) : AgrivaColors.textMutedFor(context),
                  ),
                ),
              ],
            ),
            if (i < labels.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 13, left: 6, right: 6),
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: i < step ? AgrivaColors.primary : AgrivaColors.borderFor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  final List<Crop> crops;
  final Crop? selectedCrop;
  final ValueChanged<Crop> onCropChanged;
  final List<ProcurementCentre> centres;
  final ProcurementCentre? selectedCentre;
  final ValueChanged<ProcurementCentre> onCentreChanged;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final TextEditingController quantityController;
  final String? quantityError;
  final Farmer? farmer;

  const _Step1({
    required this.crops,
    required this.selectedCrop,
    required this.onCropChanged,
    required this.centres,
    required this.selectedCentre,
    required this.onCentreChanged,
    required this.date,
    required this.onDateChanged,
    required this.quantityController,
    required this.quantityError,
    required this.farmer,
  });

  @override
  Widget build(BuildContext context) {
    final double? qty = double.tryParse(quantityController.text);
    final double msp = selectedCrop?.msp.toDouble() ?? 2275.0;
    final double totalEstimatedPayout = (qty ?? 0) * msp;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Crop Selection (README Section 2 & 5)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1. Select Crop to Procure',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimaryFor(context)),
            ),
            if (selectedCrop != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AgrivaColors.goldLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'MSP: ₹${selectedCrop!.msp}/Q',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AgrivaColors.goldDark),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: crops.map((c) {
            final isSelected = selectedCrop?.id == c.id;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onCropChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AgrivaColors.primaryLight : AgrivaColors.surfaceFor(context),
                  border: Border.all(
                    color: isSelected ? AgrivaColors.primary : AgrivaColors.borderFor(context),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AgrivaColors.primary.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.eco_outlined,
                      size: 16,
                      color: isSelected ? AgrivaColors.primary : AgrivaColors.textSecondaryFor(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AgrivaColors.primaryDark : AgrivaColors.textPrimaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // 2. Select Nearest Procurement Centre (Sorted by distance km)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '2. Select Procurement Centre',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimaryFor(context)),
            ),
            Text(
              'Sorted by nearest distance',
              style: TextStyle(fontSize: 11.5, color: AgrivaColors.textSecondaryFor(context)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: centres.map((c) {
            final isSelected = selectedCentre?.id == c.id;
            final distKm = _BookSlotScreenState._calculateDistance(c, farmer);
            final isNearest = centres.indexOf(c) == 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onCentreChanged(c),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AgrivaColors.primaryLight50 : AgrivaColors.surfaceFor(context),
                    border: Border.all(
                      color: isSelected ? AgrivaColors.primary : AgrivaColors.borderFor(context),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(left: 4, right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AgrivaColors.primary : AgrivaColors.borderFor(context),
                            width: 2,
                          ),
                          color: isSelected ? AgrivaColors.primary : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(Icons.circle, size: 8, color: Colors.white),
                              )
                            : null,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                ),
                                if (isNearest)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AgrivaColors.emeraldLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'NEAREST',
                                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AgrivaColors.primaryDark),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 13, color: AgrivaColors.textSecondaryFor(context)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${distKm.toStringAsFixed(1)} km · ${c.taluk}',
                                    style: TextStyle(fontSize: 12, color: AgrivaColors.textSecondaryFor(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(color: AgrivaColors.textMutedFor(context), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${c.dailyProcessingCapacityQ} Q/day capacity',
                                  style: const TextStyle(fontSize: 11.5, color: AgrivaColors.primaryDark, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // 3. Select Date
        Text(
          '3. Select Procurement Date',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimaryFor(context)),
        ),
        const SizedBox(height: 8),
        // Quick Date Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                () {
                  final chipDate = DateTime.now().add(Duration(days: i));
                  final isSelected = date.year == chipDate.year &&
                      date.month == chipDate.month &&
                      date.day == chipDate.day;
                  final dayLabel = i == 0
                      ? 'Today'
                      : i == 1
                          ? 'Tomorrow'
                          : DateFormat('EEE, d MMM').format(chipDate);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(dayLabel),
                      selected: isSelected,
                      selectedColor: AgrivaColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AgrivaColors.textPrimaryFor(context),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                      onSelected: (_) => onDateChanged(chipDate),
                    ),
                  );
                }(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(10),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AgrivaColors.surfaceFor(context),
              border: Border.all(color: AgrivaColors.borderFor(context)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_rounded, size: 18, color: AgrivaColors.primary),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          DateFormat('EEEE, d MMMM yyyy').format(date),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Change Date',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AgrivaColors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 4. Expected Quantity & MSP Calculation
        Text(
          '4. Expected Grain Quantity',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimaryFor(context)),
        ),
        const SizedBox(height: 8),
        AppTextField(
          label: 'Quantity (in Quintals)',
          controller: quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: quantityError,
          suffixText: 'Quintals (Q)',
          prefixIcon: const Icon(Icons.scale_rounded, color: AgrivaColors.primary, size: 20),
        ),
        const SizedBox(height: 10),

        // Payout Calculation Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AgrivaColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AgrivaColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.currency_rupee_rounded, color: AgrivaColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Direct DBT Payout: ₹${NumberFormat('#,##,###').format(totalEstimatedPayout)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AgrivaColors.primaryDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Based on ${qty?.toStringAsFixed(0) ?? "0"} Q × Official MSP ₹${selectedCrop?.msp ?? 2275}/Q',
                      style: TextStyle(fontSize: 11.5, color: AgrivaColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final farmerId = ref.watch(authControllerProvider)!.id;
    final recsAsync = ref.watch(
      slotRecommendationsProvider((
        farmerId: farmerId,
        centreId: centre.id,
        date: date,
        qty: quantity,
      )),
    );

    return recsAsync.when(
      loading: () => const LoadingState(),
      error: (e, st) => const ErrorState(),
      data: (recs) {
        if (selectedSlot == null) {
          final recommended = recs.where((r) => r.isRecommended).toList();
          if (recommended.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onSelect(recommended.first));
          } else if (recs.isNotEmpty) {
            final firstFeasible = recs.where((r) => r.feasible).firstOrNull;
            if (firstFeasible != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onSelect(firstFeasible));
            }
          }
        }

        if (recs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy_rounded, size: 48, color: AgrivaColors.textMutedFor(context)),
                  const SizedBox(height: 12),
                  const Text(
                    'No slots available for this date',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please return to Step 1 and select another date.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AgrivaColors.textSecondaryFor(context), fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AgrivaColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AgrivaColors.borderFor(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AgrivaColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${recs.where((r) => r.feasible).length} feasible slots found for ${DateFormat("d MMM yyyy").format(date)}',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AgrivaColors.textPrimaryFor(context)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final r in recs) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SlotCard(
                  recommendation: r,
                  selected: selectedSlot?.slot.id == r.slot.id,
                  onTap: () => onSelect(r),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Step3 extends ConsumerWidget {
  final Crop? crop;
  final ProcurementCentre centre;
  final DateTime date;
  final double quantity;
  final SlotRecommendation? slot;

  const _Step3({
    required this.crop,
    required this.centre,
    required this.date,
    required this.quantity,
    required this.slot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (slot == null) return const SizedBox.shrink();
    final farmerId = ref.watch(authControllerProvider)!.id;
    final farmerAsync = ref.watch(farmerByIdProvider(farmerId));

    return farmerAsync.when(
      loading: () => const LoadingState(),
      error: (e, st) => const ErrorState(),
      data: (farmer) {
        if (farmer == null) return const ErrorState();
        final departure = slot!.slot.start.subtract(
          Duration(minutes: farmer.estimatedTravelMinutes),
        );
        final msp = crop?.msp ?? 2275;
        final totalPayout = quantity * msp;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AgrivaColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AgrivaColors.borderFor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Booking Slip Preview',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AgrivaColors.primaryDark),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AgrivaColors.emeraldLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CONFIRMED MSP',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AgrivaColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _SummaryRow('Crop', crop?.name ?? 'Wheat'),
                  _SummaryRow('Procurement Centre', centre.name),
                  _SummaryRow('Taluk & District', '${centre.taluk}, ${centre.district}'),
                  _SummaryRow('Procurement Date', DateFormat('EEEE, d MMMM yyyy').format(date)),
                  _SummaryRow(
                    'Allotted Slot Window',
                    '${DateFormat('h:mm a').format(slot!.slot.start)} – ${DateFormat('h:mm a').format(slot!.slot.end)}',
                  ),
                  _SummaryRow('Quantity Booked', '${quantity.toStringAsFixed(0)} Quintals (Q)'),
                  _SummaryRow('Official MSP Rate', '₹$msp / Quintal'),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Estimated DBT Payout',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimaryFor(context)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '₹${NumberFormat('#,##,###').format(totalPayout)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AgrivaColors.primary),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AgrivaColors.primaryLight50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.directions_car_outlined, size: 18, color: AgrivaColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estimated travel: ${farmer.estimatedTravelMinutes} mins (${farmer.distanceKm} km). Recommended departure: ${DateFormat('h:mm a').format(departure)}.',
                            style: TextStyle(fontSize: 12, color: AgrivaColors.textSecondaryFor(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AgrivaColors.textSecondaryFor(context))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AgrivaColors.textPrimaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }
}
