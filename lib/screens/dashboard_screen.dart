import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import '../widgets/app_logo.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import 'announcements_screen.dart';
import 'tasks_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      final data = await EdmateService(session.api).dashboard();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AppLogo(size: 24),
            SizedBox(width: 8),
            Text('Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Announcements',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => session.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(_error!, textAlign: TextAlign.center)),
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      ),
                    ],
                  )
                : _buildBody(context, _data!),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardData data) {
    final emp = data.employee;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF5B9BF8)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: emp.photoUrl != null ? NetworkImage(emp.photoUrl!) : null,
                child: emp.photoUrl == null
                    ? Text(
                        emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${emp.name}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(emp.designation, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                    Text(emp.department, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Your Tasks', icon: Icons.checklist_rtl_rounded),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            StatCard(
              label: 'Not Started',
              value: data.taskCounts['notStarted'] ?? 0,
              color: Colors.blueGrey,
              icon: Icons.hourglass_empty_rounded,
              onTap: () => _openTasks(context, 'Not Started'),
            ),
            StatCard(
              label: 'In Progress',
              value: data.taskCounts['inProgress'] ?? 0,
              color: const Color(0xFF3B82F6),
              icon: Icons.autorenew_rounded,
              onTap: () => _openTasks(context, 'Inprogress'),
            ),
            StatCard(
              label: 'Past Due',
              value: data.taskCounts['pastDue'] ?? 0,
              color: Colors.redAccent,
              icon: Icons.warning_amber_rounded,
              onTap: () => _openTasks(context, 'Past Due'),
            ),
            StatCard(
              label: 'Completed',
              value: data.taskCounts['completed'] ?? 0,
              color: Colors.green,
              icon: Icons.check_circle_outline_rounded,
              onTap: () => _openTasks(context, 'Completed'),
            ),
          ],
        ),
        if (data.isPermanent && data.leaveBalance.isNotEmpty) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Leave Balance', icon: Icons.event_available_outlined),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: data.leaveBalance.map((lb) {
                  final pct = (lb.balance / 15).clamp(0, 1).toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(lb.type, style: const TextStyle(fontSize: 13)),
                        ),
                        Expanded(
                          child: LinearPercentIndicator(
                            lineHeight: 10,
                            percent: pct,
                            backgroundColor: const Color(0xFFE8EEFC),
                            progressColor: const Color(0xFF3B82F6),
                            barRadius: const Radius.circular(6),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${lb.balance.toStringAsFixed(1)}d', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openTasks(BuildContext context, String statusFilter) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TasksScreen(initialStatus: statusFilter)),
    );
  }
}
