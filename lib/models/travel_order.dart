class TravelOrder {
  final int id;
  final String destination;
  final String purpose;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String status;
  final DateTime? createdAt;

  // Extra detail fields from the printed Travel Order document (see
  // add-travel-order.php's INSERT column list) — shown on the detail
  // view, not the list card.
  final String officerNames;
  final bool natureOfficialTime;
  final bool natureOfficialBusiness;
  final String recommendingName;
  final String recommendingDesignation;
  final String approvingName;
  final String approvingDesignation;

  TravelOrder({
    required this.id,
    required this.destination,
    required this.purpose,
    required this.status,
    this.dateFrom,
    this.dateTo,
    this.createdAt,
    this.officerNames = '',
    this.natureOfficialTime = false,
    this.natureOfficialBusiness = false,
    this.recommendingName = '',
    this.recommendingDesignation = '',
    this.approvingName = '',
    this.approvingDesignation = '',
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
      officerNames: json['officerNames'] as String? ?? '',
      natureOfficialTime: json['natureOfficialTime'] == true,
      natureOfficialBusiness: json['natureOfficialBusiness'] == true,
      recommendingName: json['recommendingName'] as String? ?? '',
      recommendingDesignation: json['recommendingDesignation'] as String? ?? '',
      approvingName: json['approvingName'] as String? ?? '',
      approvingDesignation: json['approvingDesignation'] as String? ?? '',
    );
  }
}
