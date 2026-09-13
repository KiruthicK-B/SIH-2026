import 'package:flutter/material.dart';

import '../app/theme.dart';

class ShellDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const ShellDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Bottom navigation on narrow/portrait screens, a side NavigationRail on
/// wide screens (tablets, landscape, foldables) — same pages, same state.
class AdaptiveShell extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<Widget> pages;
  final List<ShellDestination> destinations;

  const AdaptiveShell({
    super.key,
    required this.index,
    required this.onTap,
    required this.pages,
    required this.destinations,
  });

  static const _wideBreakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AgrivaColors.surfaceDark : Colors.white;
    final selectedColor = isDark ? AgrivaColors.primaryAccentDark : AgrivaColors.primary;
    final unselectedColor = isDark ? AgrivaColors.textSecondaryDark : AgrivaColors.textSecondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;

        if (!isWide) {
          return Scaffold(
            body: IndexedStack(index: index, children: pages),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: surface,
              selectedItemColor: selectedColor,
              unselectedItemColor: unselectedColor,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              elevation: 8,
              currentIndex: index,
              onTap: onTap,
              items: [
                for (final d in destinations)
                  BottomNavigationBarItem(
                    icon: Icon(d.icon),
                    activeIcon: Icon(d.activeIcon),
                    label: d.label,
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: onTap,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: surface,
                  selectedIconTheme: IconThemeData(color: selectedColor),
                  unselectedIconTheme: IconThemeData(color: unselectedColor),
                  selectedLabelTextStyle: TextStyle(color: selectedColor, fontWeight: FontWeight.w700, fontSize: 11),
                  unselectedLabelTextStyle: TextStyle(color: unselectedColor, fontWeight: FontWeight.w500, fontSize: 11),
                  minWidth: 84,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.activeIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, color: isDark ? AgrivaColors.borderDark : AgrivaColors.border),
                Expanded(
                  child: IndexedStack(index: index, children: pages),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
