import 'package:flutter/material.dart';

import '../../widgets/adaptive_shell.dart';
import 'state_admin_dashboard_screen.dart';
import 'state_admin_crops_screen.dart';
import 'state_admin_accounts_screen.dart';
import 'state_admin_broadcasts_screen.dart';
import 'state_admin_account_screen.dart';

/// State/Super Admin shell (README §5.4): master data, district admin
/// accounts, state-wide analytics, broadcasts, escalation log.
class StateAdminShell extends StatefulWidget {
  const StateAdminShell({super.key});

  @override
  State<StateAdminShell> createState() => _StateAdminShellState();
}

class _StateAdminShellState extends State<StateAdminShell> {
  int _index = 0;

  static const _destinations = [
    ShellDestination(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Overview',
    ),
    ShellDestination(
      icon: Icons.grass_outlined,
      activeIcon: Icons.grass,
      label: 'Crops & MSP',
    ),
    ShellDestination(
      icon: Icons.admin_panel_settings_outlined,
      activeIcon: Icons.admin_panel_settings,
      label: 'Admins',
    ),
    ShellDestination(
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign,
      label: 'Broadcasts',
    ),
    ShellDestination(
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'Account',
    ),
  ];

  static const _pages = [
    StateAdminDashboardScreen(),
    StateAdminCropsScreen(),
    StateAdminAccountsScreen(),
    StateAdminBroadcastsScreen(),
    StateAdminAccountScreen(),
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
