import 'package:flutter/material.dart';

class AgrivaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const AgrivaAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle == null ? kToolbarHeight : kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }
}
