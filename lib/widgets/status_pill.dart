import 'package:flutter/material.dart';

/// Small rounded colored label used everywhere a task/leave/travel-order
/// status is shown (tasks list, task detail, leave list, travel orders).
/// Centralized so every status pill in the app looks and behaves the
/// same instead of several slightly different copies of the same
/// Container+BoxDecoration.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

/// Shared status->color mapping so Tasks, Task Detail, Leave and Travel
/// Order all color the same status word identically instead of each
/// screen keeping its own slightly different switch statement.
Color statusColorFor(String status) {
  switch (status) {
    case 'Completed':
    case 'Approved':
      return const Color(0xFF1A7F37);
    case 'Past Due':
    case 'Disapproved':
      return const Color(0xFFC0392B);
    case 'Inprogress':
      return const Color(0xFF3B82F6);
    case 'Cancelled':
      return Colors.grey;
    case 'Pending':
    case 'Forwarded':
      return const Color(0xFFB4610A);
    default:
      return Colors.blueGrey;
  }
}
