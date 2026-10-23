import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/leave_models.dart';
import '../models/employee.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import '../widgets/status_pill.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import 'leave_apply_screen.dart';
import 'profile_screen.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  List<LeaveBalance> _balances = [];
  List<LeaveApplication> _applications = [];
  Employee? _employee;
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
      final emp = await _service.profile();
      if (mounted) {
        setState(() {
          _balances = types.types;
          _isPermanent = types.isPermanent;
          _applications = apps;
          _employee = emp;
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Mirrors create_leave.php's web-side gate exactly: before letting
  /// someone open the Leave Application form, both firstName/lastName and
  /// salary must already be set on their profile (see
  /// api-bootstrap.php's apiEmployeeToJson / profile_update.php's
  /// write-once fields). If not, send them to Profile to fill those in
  /// first instead of opening a form that would just fail server-side.
  Future<void> _startApply() async {
    final emp = _employee;
    if (emp != null && (!emp.isNameSet || !emp.isSalarySet)) {
      final goToProfile = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete Your Profile'),
          content: const Text(
            'Before applying for leave, please complete your name and salary details in your Profile. '
            'This is a one-time setup needed for the official leave form.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Go to Profile')),
          ],
        ),
      );
      if (goToProfile == true && mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        _load();
      }
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LeaveApplyScreen(balances: _balances)),
    );
    _load();
  }

  void _showLeaveDetail(LeaveApplication a) {
    final df = DateFormat.yMMMd();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(a.type, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    StatusPill(label: a.status, color: statusColorFor(a.status)),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow(Icons.date_range_outlined, 'Inclusive Dates',
                    a.dateFrom != null && a.dateTo != null ? '${df.format(a.dateFrom!)} - ${df.format(a.dateTo!)}' : '-'),
                _detailRow(Icons.timelapse_outlined, 'Number of Days', '${a.days} day${a.days == 1 ? '' : 's'}'),
                _detailRow(Icons.event_available_outlined, 'Date Filed', a.filedAt != null ? df.format(a.filedAt!) : '-'),
                if (a.reason.isNotEmpty) _detailRow(Icons.notes_rounded, 'Reason', a.reason),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave')),
      floatingActionButton: _isPermanent
          ? FloatingActionButton.extended(
              onPressed: _startApply,
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
                                  onTap: () => _showLeaveDetail(a),
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
