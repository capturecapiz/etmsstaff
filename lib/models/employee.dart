class Employee {
  final int id;
  final String name;
  final String designation;
  final String department;
  final String classification;
  final String? photoUrl;
  final bool isPermanent;

  // Profile fields (see api-bootstrap.php's apiEmployeeToJson) — all
  // freely editable from the Profile screen via profile_update.php,
  // including firstName/lastName/middleInitial and salary.
  final String firstName;
  final String lastName;
  final String middleInitial;
  final String contactNumber;
  final String email;
  final DateTime? dateOfBirth;
  final String address;
  final double? salary;

  /// True once both firstName and lastName are set server-side. The
  /// mobile Leave screen gates "Apply for Leave" on this, same as
  /// create_leave.php's web form does — editing the name afterward no
  /// longer re-locks it, it's just no longer required before applying.
  final bool isNameSet;

  /// True once salary is set (and > 0) server-side. Same gate, for the
  /// same reason (both feed the official CS Form 6 leave PDF).
  final bool isSalarySet;

  Employee({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.classification,
    required this.isPermanent,
    this.photoUrl,
    this.firstName = '',
    this.lastName = '',
    this.middleInitial = '',
    this.contactNumber = '',
    this.email = '',
    this.dateOfBirth,
    this.address = '',
    this.salary,
    this.isNameSet = false,
    this.isSalarySet = false,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v as String);
    return Employee(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      department: json['department'] as String? ?? '',
      classification: json['classification'] as String? ?? '',
      isPermanent: json['isPermanent'] == true,
      photoUrl: json['photoUrl'] as String?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      middleInitial: json['middleInitial'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: parseDate(json['dateOfBirth']),
      address: json['address'] as String? ?? '',
      salary: (json['salary'] as num?)?.toDouble(),
      isNameSet: json['isNameSet'] == true,
      isSalarySet: json['isSalarySet'] == true,
    );
  }
}
