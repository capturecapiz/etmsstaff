import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import '../widgets/status_pill.dart';
import '../widgets/empty_state.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  final String? initialStatus;
  const TasksScreen({super.key, this.initialStatus});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  static const _statuses = ['All', 'Not Started', 'Inprogress', 'Past Due', 'Completed', 'Cancelled'];
  late String _selected = widget.initialStatus ?? 'All';

  List<TaskItem> _tasks = [];
  bool _loading = true;
  String? _error;

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
      final tasks = await EdmateService(session.api)
          .tasks(status: _selected == 'All' ? null : _selected);
      if (mounted) setState(() => _tasks = tasks);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _statuses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final s = _statuses[i];
                  final selected = s == _selected;
                  return ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selected = s);
                      _load();
                    },
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _tasks.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _load,
                            child: const EmptyState(
                              icon: Icons.inbox_outlined,
                              message: 'No tasks here.',
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _tasks.length,
                              itemBuilder: (context, i) {
                                final t = _tasks[i];
                                return Card(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t.id)),
                                      );
                                      _load();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  t.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              StatusPill(label: t.status, color: statusColorFor(t.status)),
                                            ],
                                          ),
                                          if (t.endDate != null) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.event_outlined, size: 13, color: Colors.grey[500]),
                                                const SizedBox(width: 4),
                                                Text('Due ${DateFormat.yMMMd().format(t.endDate!)}',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: LinearProgressIndicator(
                                              value: t.workCompleted / 100,
                                              minHeight: 6,
                                              backgroundColor: Colors.grey.shade200,
                                              color: const Color(0xFF3B82F6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
