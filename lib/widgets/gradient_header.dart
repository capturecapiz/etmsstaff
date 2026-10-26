import 'package:flutter/material.dart';

/// The curved blue gradient banner used at the top of every main screen in
/// this app — Dashboard, Tasks, Leave, Travel Order, Profile — so the app
/// reads as one consistent "brand surface" instead of a flat white AppBar
/// per screen. Put title/avatar/actions and (optionally) a HeaderStatRow
/// inside it; ordinary page content goes below, outside it.
class GradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF5B9BF8)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x293B82F6), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A single number+label pair for HeaderStatRow (e.g. "17" over
/// "Present"), matching the reference design's Attendance/Leave/Task
/// header stat rows.
class HeaderStat extends StatelessWidget {
  final String value;
  final String label;

  const HeaderStat({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10.5), textAlign: TextAlign.center),
      ],
    );
  }
}

/// A row of HeaderStat entries spaced evenly, with thin dividers between
/// them — the "17 | 4 | 1 | 22" style stat strip inside a GradientHeader.
class HeaderStatRow extends StatelessWidget {
  final List<HeaderStat> stats;

  const HeaderStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) {
        children.add(Container(width: 1, height: 28, color: Colors.white.withOpacity(0.25)));
      }
      children.add(Expanded(child: stats[i]));
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: children),
    );
  }
}
