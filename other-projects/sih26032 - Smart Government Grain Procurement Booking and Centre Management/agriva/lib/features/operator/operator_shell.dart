import 'package:flutter/material.dart';

import '../../widgets/adaptive_shell.dart';
import 'operator_dashboard_screen.dart';
import 'operator_queue_screen.dart';
import 'operator_schedule_screen.dart';
import 'operator_more_screen.dart';

class OperatorShell extends StatefulWidget {
  const OperatorShell({super.key});

  @override
  State<OperatorShell> createState() => _OperatorShellState();
}

class _OperatorShellState extends State<OperatorShell> {
  int _index = 0;

  static const _destinations = [
    ShellDestination(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    ShellDestination(
      icon: Icons.queue_outlined,
      activeIcon: Icons.queue,
      label: 'Queue',
    ),
    ShellDestination(
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note,
      label: 'Bookings',
    ),
    ShellDestination(
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'Account',
    ),
  ];

  static const _pages = [
    OperatorDashboardScreen(),
    OperatorQueueScreen(),
    OperatorScheduleScreen(),
    OperatorMoreScreen(),
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
