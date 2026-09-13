import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../state/auth_controller.dart';
import '../../state/grievance_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/max_width_body.dart';

class RaiseGrievanceScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  const RaiseGrievanceScreen({super.key, this.bookingId});

  @override
  ConsumerState<RaiseGrievanceScreen> createState() => _RaiseGrievanceScreenState();
}

class _RaiseGrievanceScreenState extends ConsumerState<RaiseGrievanceScreen> {
  GrievanceCategory _category = GrievanceCategory.qualityDispute;
  final _descriptionController = TextEditingController();
  bool _isEmergency = false;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(authControllerProvider);
    if (user == null || _descriptionController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final result = await ref.read(grievanceControllerProvider).raiseGrievance(
      farmerId: user.id,
      relatedBookingId: widget.bookingId,
      category: _category,
      description: _descriptionController.text.trim(),
      isEmergency: _isEmergency,
    );
    setState(() => _submitting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.success) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Raise a Grievance'),
      body: MaxWidthBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.bookingId != null) ...[
              Text(
                'Related booking: ${widget.bookingId}',
                style: TextStyle(fontSize: 12.5, color: AgrivaColors.textMutedFor(context)),
              ),
              const SizedBox(height: 14),
            ],
            const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GrievanceCategory.values.map((c) {
                return ChoiceChip(
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text('Describe the issue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'What happened?'),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _isEmergency,
              onChanged: (v) => setState(() => _isEmergency = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'This is a genuine hardship case requiring urgent review',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Submit', loading: _submitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
