import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/district.dart';
import '../../models/enums.dart';
import '../../models/farmer.dart';
import '../../models/land_record.dart';
import '../../repositories/repository_providers.dart';
import '../../services/location_cluster_service.dart';
import '../../state/auth_controller.dart';
import '../../state/locale_controller.dart';
import '../../state/state_admin_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/max_width_body.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final String phone;
  const RegistrationScreen({super.key, required this.phone});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  int _step = 0;
  District? _district;
  String _taluk = '';
  final _nameController = TextEditingController();
  final _doorNoController = TextEditingController();
  final _streetController = TextEditingController();
  final _villageController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _surveyController = TextEditingController();
  final _areaController = TextEditingController(text: '2.5');
  final _ownerCodeController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  LandOwnershipType _ownership = LandOwnershipType.owner;
  bool _consentGiven = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _doorNoController.dispose();
    _streetController.dispose();
    _villageController.dispose();
    _pincodeController.dispose();
    _aadhaarController.dispose();
    _surveyController.dispose();
    _areaController.dispose();
    _ownerCodeController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  bool get _requiresConsent => _ownership != LandOwnershipType.owner;

  ClusterMappingResult get _assignedCentre =>
      LocationClusterService.getAssignedCentre(
        district: _district?.name ?? 'Erode',
        taluk: _taluk.isNotEmpty ? _taluk : 'Erode Rural',
        village: _villageController.text.trim(),
      );

  bool _validateCurrentStep() {
    setState(() => _error = null);

    if (_step == 0) {
      final name = _nameController.text.trim();
      if (name.length < 3) {
        setState(() => _error = 'Please enter your full legal name (min 3 characters).');
        return false;
      }
      if (_district == null) {
        setState(() => _error = 'Please select your District.');
        return false;
      }
      if (_taluk.isEmpty) {
        setState(() => _error = 'Please select your Taluk / Block.');
        return false;
      }
      final village = _villageController.text.trim();
      if (village.isEmpty) {
        setState(() => _error = 'Please specify your Village or Town.');
        return false;
      }
      final door = _doorNoController.text.trim();
      final street = _streetController.text.trim();
      if (door.isEmpty || street.isEmpty) {
        setState(() => _error = 'Please enter complete address details (Door No and Street).');
        return false;
      }
      final pincode = _pincodeController.text.trim();
      if (pincode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pincode)) {
        setState(() => _error = 'Please enter a valid 6-digit PIN Code.');
        return false;
      }
      final aadhaar = _aadhaarController.text.trim();
      if (aadhaar.length != 12 || !RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
        setState(() => _error = 'Aadhaar number must be exactly 12 digits.');
        return false;
      }
    } else if (_step == 1) {
      final survey = _surveyController.text.trim();
      if (survey.isEmpty) {
        setState(() => _error = 'Please enter your Land Survey / Patta Number.');
        return false;
      }
      final area = double.tryParse(_areaController.text.trim());
      if (area == null || area <= 0) {
        setState(() => _error = 'Please enter a valid cultivable land area in acres.');
        return false;
      }
      if (_requiresConsent && !_consentGiven) {
        setState(() => _error = 'Consent confirmation is required for tenant or sharecropper farmers.');
        return false;
      }
    } else if (_step == 2) {
      final account = _accountController.text.trim();
      if (account.isNotEmpty && (account.length < 9 || account.length > 18)) {
        setState(() => _error = 'Bank Account Number must be between 9 and 18 digits.');
        return false;
      }
      final ifsc = _ifscController.text.trim().toUpperCase();
      if (ifsc.isNotEmpty && !RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
        setState(() => _error = 'Please enter a valid 11-character IFSC Code (e.g. SBIN0001420).');
        return false;
      }
    }

    return true;
  }

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final farmerRepo = ref.read(farmerRepositoryProvider);
      final aadhaar = _aadhaarController.text.trim();

      if (await farmerRepo.existsByPhoneAndAadhaar(widget.phone, aadhaar)) {
        setState(() {
          _error = 'An account with this phone or Aadhaar number already exists.';
          _submitting = false;
        });
        return;
      }

      final locale = ref.read(localeControllerProvider)?.languageCode ?? 'en';
      final farmerId = 'farmer-${DateTime.now().microsecondsSinceEpoch}';
      final mapping = _assignedCentre;

      final farmer = Farmer(
        id: farmerId,
        name: _nameController.text.trim(),
        farmerCode: 'FRM-TN-${(DateTime.now().millisecondsSinceEpoch % 9000) + 1000}',
        phone: widget.phone,
        preferredLanguage: locale,
        district: _district!.id,
        taluk: _taluk,
        village: _villageController.text.trim(),
        doorNo: _doorNoController.text.trim(),
        street: _streetController.text.trim(),
        pincode: _pincodeController.text.trim(),
        assignedCentreId: mapping.centreId,
        distanceKm: mapping.approxDistanceKm,
        estimatedTravelMinutes: mapping.estimatedTravelMinutes,
        aadhaarNumber: aadhaar,
        verificationStatus: FarmerVerificationStatus.pendingApproval,
        isVerified: false,
        createdAt: DateTime.now(),
      );
      await farmerRepo.save(farmer);

      final area = double.tryParse(_areaController.text.trim()) ?? 2.5;
      await ref.read(landRecordRepositoryProvider).save(
        LandRecord(
          id: 'land-$farmerId',
          farmerId: farmerId,
          surveyNumber: _surveyController.text.trim(),
          areaInAcres: area,
          village: farmer.village,
          district: farmer.district,
          ownershipType: _ownership,
          linkedOwnerFarmerId: _requiresConsent && _ownerCodeController.text.trim().isNotEmpty
              ? _ownerCodeController.text.trim()
              : null,
          consentDocPath: _requiresConsent && _consentGiven
              ? 'mock/consent_$farmerId.pdf'
              : null,
        ),
      );

      final account = _accountController.text.trim();
      final ifsc = _ifscController.text.trim().toUpperCase();
      if (account.isNotEmpty) {
        await farmerRepo.save(
          farmer.copyWith(
            bankAccountNumber: account,
            bankIfsc: ifsc,
          ),
        );
      }

      await ref.read(authControllerProvider.notifier).loginAsFarmer(farmer);
    } catch (e) {
      if (mounted) setState(() => _error = 'Registration failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _personalStep(),
      _landStep(),
      _bankStep(),
      _confirmStep(),
    ];

    return Scaffold(
      backgroundColor: AgrivaColors.background,
      appBar: AppBar(
        title: const Text('Farmer Registration', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: MaxWidthBody(
        maxWidth: 580,
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / steps.length,
              backgroundColor: AgrivaColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AgrivaColors.primary),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: steps[_step],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AgrivaColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AgrivaColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AgrivaColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: AgrivaColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AgrivaColors.error, fontSize: 12.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: SecondaryButton(
                            label: 'Back',
                            onPressed: () => setState(() {
                              _step--;
                              _error = null;
                            }),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          label: _step == steps.length - 1 ? 'Submit for Verification' : 'Continue',
                          loading: _submitting,
                          onPressed: () {
                            if (_step == steps.length - 1) {
                              _submit();
                            } else {
                              if (_validateCurrentStep()) {
                                setState(() => _step++);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personalStep() => Consumer(
        builder: (context, ref, _) {
          final districtsAsync = ref.watch(districtsProvider);
          final taluks = _district != null
              ? LocationClusterService.districtTaluks[_district!.name] ?? []
              : [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Personal & Location Profile',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AgrivaColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter accurate location details. Your profile will be automatically linked to your regional procurement centre.',
                style: TextStyle(fontSize: 12.5, color: AgrivaColors.textSecondary),
              ),
              const SizedBox(height: 18),

              AppTextField(
                label: 'Farmer Full Name (as per Aadhaar)',
                controller: _nameController,
                hint: 'e.g. R. Murugan',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AgrivaColors.primary),
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Aadhaar Number (Strictly 12 Digits)',
                controller: _aadhaarController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                hint: '12-digit UIDAI number',
                prefixIcon: const Icon(Icons.fingerprint_rounded, size: 20, color: AgrivaColors.primary),
              ),
              const SizedBox(height: 14),

              // District Selector
              const Text('Tamil Nadu District', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              districtsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => const Text('Failed to load districts.', style: TextStyle(color: AgrivaColors.error)),
                data: (districts) {
                  _district ??= districts.firstOrNull;
                  if (_taluk.isEmpty && _district != null) {
                    final defaultTaluks = LocationClusterService.districtTaluks[_district!.name] ?? [];
                    if (defaultTaluks.isNotEmpty) _taluk = defaultTaluks.first;
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: districts.map((d) {
                      final selected = _district?.id == d.id;
                      return ChoiceChip(
                        label: Text(d.name),
                        selected: selected,
                        selectedColor: AgrivaColors.primaryLight50,
                        labelStyle: TextStyle(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AgrivaColors.primary : AgrivaColors.textPrimary,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _district = d;
                            final list = LocationClusterService.districtTaluks[d.name] ?? [];
                            _taluk = list.isNotEmpty ? list.first : '';
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Taluk / Block Selector
              if (taluks.isNotEmpty) ...[
                const Text('Taluk / Block', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: taluks.map((t) {
                    final isSel = _taluk == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: isSel,
                      selectedColor: AgrivaColors.primaryLight50,
                      labelStyle: TextStyle(
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? AgrivaColors.primary : AgrivaColors.textPrimary,
                      ),
                      onSelected: (_) => setState(() => _taluk = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Village Name with suggestions
              AppTextField(
                label: 'Village / Revenue Town',
                controller: _villageController,
                hint: 'e.g. Chennimalai, Thindal, Vallam',
                prefixIcon: const Icon(Icons.location_city_rounded, size: 20, color: AgrivaColors.primary),
              ),

              // Sample Village Chips
              if (_taluk.isNotEmpty && LocationClusterService.talukVillages[_taluk] != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: LocationClusterService.talukVillages[_taluk]!.map((v) {
                    return ActionChip(
                      label: Text(v, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AgrivaColors.surface,
                      onPressed: () => setState(() => _villageController.text = v),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),

              // Complete Address details: Door No, Street, Pincode
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: 'Door / Flat No',
                      controller: _doorNoController,
                      hint: 'e.g. 14/2B',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: AppTextField(
                      label: 'Street / Locality',
                      controller: _streetController,
                      hint: 'e.g. Kovai Main Road',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Pincode (Strictly 6 Digits)',
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                hint: 'e.g. 638012',
                prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20, color: AgrivaColors.primary),
              ),
              const SizedBox(height: 16),

              // Live Automatic Procurement Centre Allocation Preview
              _buildAutoAllocationCard(),
            ],
          );
        },
      );

  Widget _buildAutoAllocationCard() {
    final mapping = _assignedCentre;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AgrivaColors.primaryLight50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AgrivaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.hub_rounded, size: 18, color: AgrivaColors.primary),
              SizedBox(width: 8),
              Text(
                'Automatic Centre Assignment',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AgrivaColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Assigned Centre: ${mapping.centreName} (${mapping.centreCode})',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            '${mapping.clusterName} • Approx ${mapping.approxDistanceKm} km (${mapping.estimatedTravelMinutes} mins transit)',
            style: const TextStyle(fontSize: 11.5, color: AgrivaColors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            '✓ Logistics & quota managed automatically by cluster. Verification request will route directly to this centre operator.',
            style: TextStyle(fontSize: 11, color: AgrivaColors.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _landStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Land Ownership & Survey', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Procurement quota is calculated based on verified agricultural land records.',
            style: TextStyle(fontSize: 12.5, color: AgrivaColors.textSecondary),
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Survey / Patta Number',
            controller: _surveyController,
            hint: 'e.g. SY-104/2B',
            prefixIcon: const Icon(Icons.terrain_rounded, size: 20, color: AgrivaColors.primary),
          ),
          const SizedBox(height: 14),

          AppTextField(
            label: 'Cultivable Area (Acres)',
            controller: _areaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hint: 'e.g. 2.5',
            prefixIcon: const Icon(Icons.square_foot_rounded, size: 20, color: AgrivaColors.primary),
          ),
          const SizedBox(height: 16),

          const Text('Land Ownership Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: LandOwnershipType.values.map((t) {
              final selected = _ownership == t;
              return ChoiceChip(
                label: Text(t.label),
                selected: selected,
                selectedColor: AgrivaColors.primaryLight50,
                labelStyle: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AgrivaColors.primary : AgrivaColors.textPrimary,
                ),
                onSelected: (_) => setState(() => _ownership = t),
              );
            }).toList(),
          ),

          if (_requiresConsent) ...[
            const SizedBox(height: 16),
            AppTextField(
              label: "Landowner's Farmer Code or Aadhaar",
              controller: _ownerCodeController,
              hint: 'e.g. FRM-TN-1001',
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _consentGiven,
              onChanged: (v) => setState(() => _consentGiven = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                "I confirm legal landowner consent and lease affidavit are on file.",
                style: TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ],
      );

  Widget _bankStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Direct Benefit Transfer (DBT) Bank Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'MSP sale proceeds will be credited directly to this Aadhaar-linked bank account within 24–48 hours of weighment.',
            style: TextStyle(fontSize: 12.5, color: AgrivaColors.textSecondary),
          ),
          const SizedBox(height: 18),

          AppTextField(
            label: 'Bank Account Number',
            controller: _accountController,
            keyboardType: TextInputType.number,
            hint: '9 to 18 digits account number',
            prefixIcon: const Icon(Icons.account_balance_rounded, size: 20, color: AgrivaColors.primary),
          ),
          const SizedBox(height: 14),

          AppTextField(
            label: 'Bank IFSC Code',
            controller: _ifscController,
            hint: 'e.g. SBIN0001420',
            prefixIcon: const Icon(Icons.pin_outlined, size: 20, color: AgrivaColors.primary),
          ),
        ],
      );

  Widget _confirmStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Review & Confirm Registration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Please verify your details before submitting to the centre operator.',
            style: TextStyle(fontSize: 12.5, color: AgrivaColors.textSecondary),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AgrivaColors.border),
            ),
            child: Column(
              children: [
                _summaryRow('Mobile Number', widget.phone),
                _summaryRow('Farmer Name', _nameController.text),
                _summaryRow('Aadhaar', Farmer.maskAadhaar(_aadhaarController.text)),
                _summaryRow('District', _district?.name ?? ''),
                _summaryRow('Taluk / Block', _taluk),
                _summaryRow('Village', _villageController.text),
                _summaryRow('Complete Address', '${_doorNoController.text}, ${_streetController.text}, PIN: ${_pincodeController.text}'),
                _summaryRow('Assigned Centre', '${_assignedCentre.centreName} (${_assignedCentre.centreCode})'),
                _summaryRow('Survey Number', _surveyController.text),
                _summaryRow('Land Area', '${_areaController.text} Acres'),
                _summaryRow('Ownership', _ownership.label),
                if (_accountController.text.isNotEmpty)
                  _summaryRow('Bank Account', Farmer.maskAccount(_accountController.text)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AgrivaColors.warningBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AgrivaColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 18, color: AgrivaColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upon submission, your profile will be sent to the Centre Operator for verification. Slot booking will unlock as soon as verification is complete.',
                    style: TextStyle(fontSize: 12, color: AgrivaColors.warning, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 125,
              child: Text(
                label,
                style: const TextStyle(color: AgrivaColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AgrivaColors.textPrimary),
              ),
            ),
          ],
        ),
      );
}
