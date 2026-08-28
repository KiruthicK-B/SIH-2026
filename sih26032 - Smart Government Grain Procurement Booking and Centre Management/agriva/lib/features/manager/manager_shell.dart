import 'package:flutter/material.dart';

import '../../widgets/adaptive_shell.dart';
import 'manager_dashboard_screen.dart';
import 'manager_centres_screen.dart';
import 'manager_analytics_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  static const _destinations = [
    ShellDestination(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    ShellDestination(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      label: 'Centres',
    ),
    ShellDestination(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights,
      label: 'Analytics',
    ),
  ];

  static const _pages = [
    ManagerDashboardScreen(),
    ManagerCentresScreen(),
    ManagerAnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveShell(
      index: _index,
      onTap: (i) => setState(() => _index = i),
      pages: _pages,
      destinations: _destinations,
    );
  }
}
