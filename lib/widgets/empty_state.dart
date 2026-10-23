import 'package:flutter/material.dart';

/// Friendlier "nothing here" placeholder (icon + message), used instead
/// of a bare Center(Text(...)) across the list screens (Tasks, Leave,
/// Travel Order, Announcements). Wrapped in a ListView so it still works
/// inside a RefreshIndicator (which needs a scrollable child to detect
/// the pull-to-refresh gesture).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 110),
      children: [
        Icon(icon, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ],
    );
  }
}
