import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_controller.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? Colors.red.shade700 : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showAgrivaSignOutDialog(BuildContext context, WidgetRef ref) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Sign Out?',
    message: 'Are you sure you want to sign out from the AGRIVA portal?',
    confirmLabel: 'Sign Out',
    destructive: true,
  );
  if (confirmed) {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }
}
