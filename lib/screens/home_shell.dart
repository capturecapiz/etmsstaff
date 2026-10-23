import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'leave_screen.dart';
import 'travel_order_screen.dart';
import 'profile_screen.dart';

/// Bottom-nav shell holding the 5 main sections, mirroring edmate's own
/// sidebar sections (Dashboard / Task Status / Leave / Travel Order /
/// Profile) just collapsed into a mobile-friendly bottom bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TasksScreen(),
    LeaveScreen(),
    TravelOrderScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: DecoratedBox(
        // A soft top shadow so the bar reads as a floating surface above
        // the content, rather than a flat line sitting under it.
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
            NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available), label: 'Leave'),
            NavigationDestination(icon: Icon(Icons.card_travel_outlined), selectedIcon: Icon(Icons.card_travel), label: 'Travel'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
