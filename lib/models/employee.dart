class Employee {
  final int id;
  final String name;
  final String designation;
  final String department;
  final String classification;
  final String? photoUrl;
  final bool isPermanent;

  Employee({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.classification,
    required this.isPermanent,
    this.photoUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      department: json['department'] as String? ?? '',
      classification: json['classification'] as String? ?? '',
      isPermanent: json['isPermanent'] == true,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
