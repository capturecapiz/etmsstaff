import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import '../widgets/status_pill.dart';
import '../widgets/section_header.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  TaskDetail? _detail;
  bool _loading = true;
  String? _error;
  double _progress = 0;
  final _commentCtrl = TextEditingController();
  bool _sending = false;
  bool _savingProgress = false;

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
      final detail = await _service.taskDetail(widget.taskId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _progress = detail.task.workCompleted.toDouble();
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProgress() async {
    setState(() => _savingProgress = true);
    try {
      String? newStatus;
      if (_progress >= 100) {
        newStatus = 'Completed';
      } else if (_progress > 0) {
        newStatus = 'Inprogress';
      }
      await _service.updateTask(widget.taskId, workCompleted: _progress.round(), status: newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress updated.')));
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingProgress = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.addComment(widget.taskId, text);
      _commentCtrl.clear();
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(context, _detail!),
    );
  }

  Widget _buildBody(BuildContext context, TaskDetail detail) {
    final task = detail.task;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(label: task.status, color: statusColorFor(task.status)),
                ],
              ),
              if (task.priority != null) ...[
                const SizedBox(height: 8),
                Chip(
                  label: Text(task.priority!),
                  visualDensity: VisualDensity.compact,
                ),
              ],
              if (task.assignDate != null || task.endDate != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (task.assignDate != null)
                      Expanded(
                        child: _dateChip(Icons.event_note_outlined, 'Assigned', DateFormat.yMMMd().format(task.assignDate!)),
                      ),
                    if (task.assignDate != null && task.endDate != null) const SizedBox(width: 10),
                    if (task.endDate != null)
                      Expanded(
                        child: _dateChip(Icons.event_outlined, 'Due', DateFormat.yMMMd().format(task.endDate!)),
                      ),
                  ],
                ),
              ],
              if (detail.description != null && detail.description!.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionHeader(title: 'Description', icon: Icons.notes_rounded),
                const SizedBox(height: 8),
                Text(detail.description!, style: const TextStyle(height: 1.4)),
              ],
              const SizedBox(height: 20),
              const SectionHeader(title: 'Your Progress', icon: Icons.trending_up_rounded),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF3B82F6),
                                thumbColor: const Color(0xFF3B82F6),
                              ),
                              child: Slider(
                                value: _progress,
                                min: 0,
                                max: 100,
                                divisions: 20,
                                label: '${_progress.round()}%',
                                onChanged: (v) => setState(() => _progress = v),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${_progress.round()}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ElevatedButton(
                            onPressed: _savingProgress ? null : _saveProgress,
                            child: _savingProgress
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Progress'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 32),
              const SectionHeader(title: 'Comments', icon: Icons.forum_outlined),
              const SizedBox(height: 10),
              if (detail.comments.isEmpty)
                Text('No comments yet.', style: TextStyle(color: Colors.grey[500])),
              ...detail.comments.map((c) => Align(
                    alignment: c.isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: c.isAdmin ? Colors.grey.shade100 : const Color(0xFF3B82F6).withOpacity(0.12),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(c.isAdmin ? 4 : 14),
                          bottomRight: Radius.circular(c.isAdmin ? 14 : 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.author, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text(c.text, style: const TextStyle(height: 1.3)),
                          if (c.createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(DateFormat.yMMMd().add_jm().format(c.createdAt!),
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(hintText: 'Write a comment...'),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _sendComment,
                  icon: _sending
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
