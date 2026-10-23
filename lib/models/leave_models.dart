class LeaveBalance {
  final String type;
  final double balance;

  LeaveBalance({required this.type, required this.balance});

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      type: json['type'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LeaveApplication {
  final int id;
  final String type;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double days;
  final String status; // Pending | Approved | Disapproved
  final DateTime? filedAt;

  LeaveApplication({
    required this.id,
    required this.type,
    required this.days,
    required this.status,
    this.dateFrom,
    this.dateTo,
    this.filedAt,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v as String);
    return LeaveApplication(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      days: (json['days'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'Pending',
      dateFrom: parseDate(json['dateFrom']),
      dateTo: parseDate(json['dateTo']),
      filedAt: parseDate(json['filedAt']),
    );
  }
}
