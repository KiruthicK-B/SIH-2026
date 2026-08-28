import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../providers/app_state_provider.dart';
import 'router.dart';
import 'theme.dart';

class AgrivaApp extends ConsumerWidget {
  const AgrivaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final role = ref.watch(appStateProvider.select((s) => s.currentUser?.role));
    final theme = (role == UserRole.operator || role == UserRole.admin)
        ? AgrivaTheme.operatorBlue
        : AgrivaTheme.light;

    return MaterialApp.router(
      title: 'AGRIVA',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
