import 'package:flutter/material.dart';

/// Wraps scrollable page bodies so they don't stretch edge-to-edge into
/// unreadably wide lines on tablets / landscape / desktop widths, while
/// staying full-width (unchanged) on phones.
class MaxWidthBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MaxWidthBody({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
