class AppUser {
  final String uid;
  final String email;
  final String role; // 'student' or 'admin'
  final String? enrollmentId;
  final String department;
  final String? course;
  final String? section;
  final String? semester;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.enrollmentId,
    required this.department,
    this.course,
    this.section,
    this.semester,
  });

  // Factory constructor to create AppUser from Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      enrollmentId: map['enrollmentId'],
      department: map['department'] ?? '',
      course: map['course'],
      section: map['section'],
      semester: map['semester'],
    );
  }

  // Convert AppUser to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'enrollmentId': enrollmentId,
      'department': department,
      'course': course,
      'section': section,
      'semester': semester,
    };
  }

  // Check if user is student
  bool get isStudent => role == 'student';

  // Check if user is admin
  bool get isAdmin => role == 'admin';
}
