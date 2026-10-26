import 'package:flutter/material.dart';

/// Consistent "icon + title" section heading used above the dashboard's
/// task/leave blocks and other grouped content, so every section label
/// in the app shares the same weight/size/spacing.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const SectionHeader({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: .1),
        ),
      ],
    );
  }
}
