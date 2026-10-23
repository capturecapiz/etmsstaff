import '../models/task_item.dart';
import '../models/leave_models.dart';
import '../models/travel_order.dart';
import '../models/announcement.dart';
import '../models/employee.dart';
import 'api_client.dart';

/// Everything beyond login/logout (which Session owns directly). One class
/// per the project's existing style of grouping related DB calls behind a
/// small set of helper functions (see includes/*.php on the PHP side).
class EdmateService {
  final ApiClient api;
  EdmateService(this.api);

  Future<DashboardData> dashboard() async {
    final resp = await api.post('dashboard.php', {});
    return DashboardData.fromJson(resp);
  }

  Future<List<TaskItem>> tasks({String? status}) async {
    final resp = await api.post('tasks.php', {
      if (status != null) 'status': status,
    });
    return ((resp['tasks'] as List?) ?? [])
        .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TaskDetail> taskDetail(int taskId) async {
    final resp = await api.post('task_detail.php', {'taskId': '$taskId'});
    return TaskDetail.fromJson(resp);
  }

  Future<void> updateTask(int taskId, {int? workCompleted, String? status}) async {
    await api.post('task_update.php', {
      'taskId': '$taskId',
      if (workCompleted != null) 'workCompleted': '$workCompleted',
      if (status != null) 'status': status,
    });
  }

  Future<TaskComment> addComment(int taskId, String text) async {
    final resp = await api.post('task_comment_add.php', {
      'taskId': '$taskId',
      'text': text,
    });
    return TaskComment.fromJson(resp['comment'] as Map<String, dynamic>);
  }

  Future<LeaveData> leaveTypes() async {
    final resp = await api.post('leave_types.php', {});
    return LeaveData.fromJson(resp);
  }

  Future<List<LeaveApplication>> leaveList() async {
    final resp = await api.post('leave_list.php', {});
    return ((resp['leaves'] as List?) ?? [])
        .map((e) => LeaveApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> applyLeave({
    required String leaveType,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String reason,
  }) async {
    await api.post('leave_apply.php', {
      'leaveType': leaveType,
      'dateFrom': dateFrom.toIso8601String().substring(0, 10),
      'dateTo': dateTo.toIso8601String().substring(0, 10),
      'reason': reason,
    });
  }

  Future<List<TravelOrder>> travelOrders() async {
    final resp = await api.post('travel_orders.php', {});
    return ((resp['orders'] as List?) ?? [])
        .map((e) => TravelOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTravelOrder({
    required String destination,
    required String purpose,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    await api.post('travel_order_create.php', {
      'destination': destination,
      'purpose': purpose,
      'dateFrom': dateFrom.toIso8601String().substring(0, 10),
      'dateTo': dateTo.toIso8601String().substring(0, 10),
    });
  }

  Future<List<Announcement>> announcements() async {
    final resp = await api.post('announcements.php', {});
    return ((resp['announcements'] as List?) ?? [])
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Employee> profile() async {
    final resp = await api.post('profile.php', {});
    return Employee.fromJson(resp['employee'] as Map<String, dynamic>);
  }
}

class DashboardData {
  final Employee employee;
  final Map<String, int> taskCounts;
  final List<LeaveBalance> leaveBalance;
  final bool isPermanent;
  final int announcementsUnread;

  DashboardData({
    required this.employee,
    required this.taskCounts,
    required this.leaveBalance,
    required this.isPermanent,
    required this.announcementsUnread,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final counts = (json['taskCounts'] as Map<String, dynamic>? ?? {});
    return DashboardData(
      employee: Employee.fromJson(json['employee'] as Map<String, dynamic>),
      taskCounts: counts.map((k, v) => MapEntry(k, (v as num).toInt())),
      leaveBalance: ((json['leaveBalance'] as List?) ?? [])
          .map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPermanent: json['isPermanent'] == true,
      announcementsUnread: (json['announcementsUnread'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaveData {
  final List<LeaveBalance> types;
  final bool isPermanent;

  LeaveData({required this.types, required this.isPermanent});

  factory LeaveData.fromJson(Map<String, dynamic> json) {
    return LeaveData(
      types: ((json['types'] as List?) ?? [])
          .map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPermanent: json['isPermanent'] == true,
    );
  }
}
