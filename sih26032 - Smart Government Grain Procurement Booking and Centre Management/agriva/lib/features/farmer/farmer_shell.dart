import 'package:flutter/material.dart';

import '../../widgets/adaptive_shell.dart';
import 'farmer_home_screen.dart';
import 'my_bookings_screen.dart';
import 'queue_status_screen.dart';
import 'profile_screen.dart';

class FarmerShell extends StatefulWidget {
  const FarmerShell({super.key});

  @override
  State<FarmerShell> createState() => _FarmerShellState();
}

class _FarmerShellState extends State<FarmerShell> {
  int _index = 0;

  void _goToTab(int i) => setState(() => _index = i);

  static const _destinations = [
    ShellDestination(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    ShellDestination(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Bookings',
    ),
    ShellDestination(
      icon: Icons.queue_outlined,
      activeIcon: Icons.queue,
      label: 'Queue',
    ),
    ShellDestination(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      FarmerHomeScreen(
        onGoToQueue: () => _goToTab(2),
        onGoToBookings: () => _goToTab(1),
      ),
      const MyBookingsScreen(),
      const QueueStatusScreen(),
      const ProfileScreen(),
    ];

    return AdaptiveShell(
      index: _index,
      onTap: _goToTab,
      pages: pages,
      destinations: _destinations,
    );
  }
}
