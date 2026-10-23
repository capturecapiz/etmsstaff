import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import '../config.dart';
import '../widgets/section_header.dart';
import '../widgets/gradient_header.dart';
import 'announcements_screen.dart';
import 'tasks_screen.dart';
import 'leave_screen.dart';
import 'travel_order_screen.dart';

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
    final emp = _data?.employee;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            GradientHeader(
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        backgroundImage: resolveServerUrl(emp?.photoUrl) != null
                            ? NetworkImage(resolveServerUrl(emp?.photoUrl)!)
                            : null,
                        child: resolveServerUrl(emp?.photoUrl) == null
                            ? Text(
                                emp != null && emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp != null ? 'Hi, ${emp.name}' : 'Hi there',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              emp?.designation ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.campaign_outlined, color: Colors.white),
                        tooltip: 'Announcements',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Log out',
                        onPressed: () => session.logout(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_data != null)
                    HeaderStatRow(
                      stats: [
                        HeaderStat(value: '${_data!.taskCounts['notStarted'] ?? 0}', label: 'Not\nStarted'),
                        HeaderStat(value: '${_data!.taskCounts['inProgress'] ?? 0}', label: 'In\nProgress'),
                        HeaderStat(value: '${_data!.taskCounts['pastDue'] ?? 0}', label: 'Past\nDue'),
                        HeaderStat(value: '${_data!.taskCounts['completed'] ?? 0}', label: 'Completed'),
                      ],
                    ),
                ],
              ),
            ),
            if (_loading)
              const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_data != null)
              _buildBody(context, _data!),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Quick Actions', icon: Icons.apps_rounded),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.82,
            children: [
              _QuickAction(
                label: 'Tasks',
                icon: Icons.checklist_rtl_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasksScreen())),
              ),
              _QuickAction(
                label: 'Leave',
                icon: Icons.event_available_outlined,
                color: const Color(0xFF22A06B),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaveScreen())),
              ),
              _QuickAction(
                label: 'Travel\nOrder',
                icon: Icons.card_travel_outlined,
                color: const Color(0xFFE08A2B),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TravelOrderScreen())),
              ),
              _QuickAction(
                label: 'Announce-\nments',
                icon: Icons.campaign_outlined,
                color: const Color(0xFF8B5CF6),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
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
      ),
    );
  }
}

/// A colored rounded-square icon tile + label, used in the Dashboard's
/// "Quick Actions" grid — the category-grid pattern from the reference
/// design, mapped onto this app's real sections (Tasks/Leave/Travel
/// Order/Announcements) instead of features the backend doesn't have.
class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
