import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/leave_models.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import '../widgets/status_pill.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import 'leave_apply_screen.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  List<LeaveBalance> _balances = [];
  List<LeaveApplication> _applications = [];
  bool _isPermanent = true;
  bool _loading = true;
  String? _error;

  late EdmateService _service;

  @override
  void initState() {
    super.initState();
    _service = EdmateService(context.read<Session>().api);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final types = await _service.leaveTypes();
      final apps = await _service.leaveList();
      if (mounted) {
        setState(() {
          _balances = types.types;
          _isPermanent = types.isPermanent;
          _applications = apps;
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave')),
      floatingActionButton: _isPermanent
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LeaveApplyScreen(balances: _balances)),
                );
                _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Apply for Leave'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : !_isPermanent
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Leave management is available to Permanent employees only, same as on the web portal.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const SectionHeader(title: 'Leave Balance', icon: Icons.event_available_outlined),
                          const SizedBox(height: 10),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: _balances.map((b) {
                                  final pct = (b.balance / 15).clamp(0, 1).toDouble();
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 110,
                                          child: Text(b.type, style: const TextStyle(fontSize: 13)),
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
                                        Text('${b.balance.toStringAsFixed(1)}d',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const SectionHeader(title: 'My Applications', icon: Icons.assignment_outlined),
                          const SizedBox(height: 10),
                          if (_applications.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 30),
                              child: EmptyState(icon: Icons.assignment_turned_in_outlined, message: 'No leave applications yet.'),
                            ),
                          ..._applications.map((a) => Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  title: Text(a.type, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    a.dateFrom != null && a.dateTo != null
                                        ? '${DateFormat.yMMMd().format(a.dateFrom!)} - ${DateFormat.yMMMd().format(a.dateTo!)} (${a.days} day${a.days == 1 ? '' : 's'})'
                                        : '${a.days} day(s)',
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  trailing: StatusPill(label: a.status, color: statusColorFor(a.status)),
                                ),
                              )),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
    );
  }
}
