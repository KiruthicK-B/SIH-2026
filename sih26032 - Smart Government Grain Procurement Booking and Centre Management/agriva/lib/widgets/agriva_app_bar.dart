import 'package:flutter/material.dart';

class AgrivaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  /// A `TabBar` (or similar) belongs here, not in [actions] — `actions` is a
  /// `Row` with no room to lay out a full-width tab strip, which clips it.
  final PreferredSizeWidget? bottom;

  const AgrivaAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    (subtitle == null ? kToolbarHeight : kToolbarHeight + 6) +
        (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: Colors.white,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFFD1E7DD),
              ),
            ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
