import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../state/state_admin_controller.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/max_width_body.dart';

class StateAdminAccountsScreen extends ConsumerWidget {
  const StateAdminAccountsScreen({super.key});

  Future<void> _createAdmin(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final districtController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('New District Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Name', controller: nameController),
            const SizedBox(height: 10),
            AppTextField(label: 'Employee ID', controller: idController),
            const SizedBox(height: 10),
            AppTextField(
              label: 'District id',
              controller: districtController,
              hint: 'district-erode',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      final res = await ref
          .read(stateAdminControllerProvider)
          .createDistrictAdmin(
            name: nameController.text.trim(),
            employeeId: idController.text.trim(),
            district: districtController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admins = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            onPressed: () => _createAdmin(context, ref),
          ),
        ],
      ),
      body: MaxWidthBody(
        child: admins.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (list) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final admin = list[i];
              return Card(
                child: ListTile(
                  title: Text(admin.name),
                  subtitle: Text(
                    '${admin.role.label} · ${admin.employeeId}${admin.isLocked ? ' · Locked' : ''}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      final controller = ref.read(stateAdminControllerProvider);
                      if (action == 'reset') {
                        final res = await controller.resetAdminPassword(
                          admin.id,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(res.message)));
                        }
                      } else if (action == 'deactivate') {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Deactivate account?',
                          message:
                              '${admin.name} will no longer be able to log in.',
                          destructive: true,
                        );
                        if (confirmed) {
                          await controller.deactivateAdmin(admin.id);
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'reset',
                        child: Text('Reset password'),
                      ),
                      PopupMenuItem(
                        value: 'deactivate',
                        child: Text('Deactivate'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
