class TravelOrder {
  final int id;
  final String destination;
  final String purpose;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String status;
  final DateTime? createdAt;

  TravelOrder({
    required this.id,
    required this.destination,
    required this.purpose,
    required this.status,
    this.dateFrom,
    this.dateTo,
    this.createdAt,
  });

  factory TravelOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v as String);
    return TravelOrder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      destination: json['destination'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      dateFrom: parseDate(json['dateFrom']),
      dateTo: parseDate(json['dateTo']),
      createdAt: parseDate(json['createdAt']),
    );
  }
}
