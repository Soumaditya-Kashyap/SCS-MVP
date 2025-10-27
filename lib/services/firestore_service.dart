import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USERS ====================

  // Get user by ID
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!, uid);
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // ==================== TIMETABLES ====================

  // Get timetable for specific department/semester/section
  Future<Map<String, dynamic>?> getTimetable({
    required String department,
    required String semester,
    required String section,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('timetables')
          .where('department', isEqualTo: department)
          .where('semester', isEqualTo: semester)
          .where('section', isEqualTo: section)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return querySnapshot.docs.first.data();
    } catch (e) {
      throw Exception('Failed to get timetable: ${e.toString()}');
    }
  }

  // Create or update timetable
  Future<void> saveTimetable({
    required String department,
    required String semester,
    required String section,
    required Map<String, dynamic> routine,
  }) async {
    try {
      final timetableData = {
        'department': department,
        'semester': semester,
        'section': section,
        'routine': routine,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Check if timetable exists
      final querySnapshot = await _firestore
          .collection('timetables')
          .where('department', isEqualTo: department)
          .where('semester', isEqualTo: semester)
          .where('section', isEqualTo: section)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Create new timetable
        await _firestore.collection('timetables').add(timetableData);
      } else {
        // Update existing timetable
        await _firestore
            .collection('timetables')
            .doc(querySnapshot.docs.first.id)
            .update(timetableData);
      }
    } catch (e) {
      throw Exception('Failed to save timetable: ${e.toString()}');
    }
  }

  // ==================== UNSCHEDULED CLASSES ====================

  // Get unscheduled classes for a department
  Stream<QuerySnapshot> getUnscheduledClasses(String department) {
    return _firestore
        .collection('unscheduled_classes')
        .where('department', isEqualTo: department)
        .where(
          'date',
          isGreaterThanOrEqualTo: DateTime.now().toIso8601String().split(
            'T',
          )[0],
        )
        .orderBy('date')
        .orderBy('time')
        .snapshots();
  }

  // Add unscheduled class
  Future<void> addUnscheduledClass({
    required String department,
    required String subject,
    required String date,
    required String time,
    required String faculty,
    String? topic,
    String? semester,
    String? section,
  }) async {
    try {
      await _firestore.collection('unscheduled_classes').add({
        'department': department,
        'subject': subject,
        'date': date,
        'time': time,
        'faculty': faculty,
        'topic': topic,
        'semester': semester,
        'section': section,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add unscheduled class: ${e.toString()}');
    }
  }

  // Delete unscheduled class
  Future<void> deleteUnscheduledClass(String id) async {
    try {
      await _firestore.collection('unscheduled_classes').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete unscheduled class: ${e.toString()}');
    }
  }

  // ==================== EXAMS ====================

  // Get exams for a department
  Stream<QuerySnapshot> getExams(String department, {String? semester}) {
    Query query = _firestore
        .collection('exams')
        .where('department', isEqualTo: department);

    if (semester != null) {
      query = query.where('semester', isEqualTo: semester);
    }

    return query.orderBy('date').snapshots();
  }

  // Add exam
  Future<void> addExam({
    required String department,
    required String semester,
    required String subject,
    required String date,
    required String type,
    String? room,
    String? section,
  }) async {
    try {
      await _firestore.collection('exams').add({
        'department': department,
        'semester': semester,
        'subject': subject,
        'date': date,
        'type': type,
        'room': room,
        'section': section,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add exam: ${e.toString()}');
    }
  }

  // Delete exam
  Future<void> deleteExam(String id) async {
    try {
      await _firestore.collection('exams').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete exam: ${e.toString()}');
    }
  }
}
