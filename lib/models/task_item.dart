class TaskItem {
  final int id;
  final String title;
  final String? priority;
  final String? client;
  final DateTime? assignDate;
  final DateTime? endDate;
  final int workCompleted; // 0-100
  final String status; // Not Started | Inprogress | Completed | Cancelled | Past Due

  TaskItem({
    required this.id,
    required this.title,
    required this.workCompleted,
    required this.status,
    this.priority,
    this.client,
    this.assignDate,
    this.endDate,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v as String);
    }

    return TaskItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      priority: json['priority'] as String?,
      client: json['client'] as String?,
      assignDate: parseDate(json['assignDate']),
      endDate: parseDate(json['endDate']),
      workCompleted: (json['workCompleted'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'Not Started',
    );
  }
}

class TaskComment {
  final int id;
  final String author;
  final String text;
  final DateTime? createdAt;
  final bool isAdmin;

  TaskComment({
    required this.id,
    required this.author,
    required this.text,
    required this.isAdmin,
    this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      author: json['author'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isAdmin: json['isAdmin'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class TaskDetail {
  final TaskItem task;
  final List<TaskComment> comments;
  final String? description;

  TaskDetail({required this.task, required this.comments, this.description});

  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    return TaskDetail(
      task: TaskItem.fromJson(json['task'] as Map<String, dynamic>),
      description: json['description'] as String?,
      comments: ((json['comments'] as List?) ?? [])
          .map((e) => TaskComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
