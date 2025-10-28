import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/timetable_model.dart';

class StudentExamsScreen extends StatefulWidget {
  const StudentExamsScreen({super.key});

  @override
  State<StudentExamsScreen> createState() => _StudentExamsScreenState();
}

class _StudentExamsScreenState extends State<StudentExamsScreen> {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentAppUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().getExams(
        _currentUser!.department,
        semester: _currentUser!.semester,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final exams = snapshot.data!.docs
            .map(
              (doc) => Exam.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .toList();

        // Sort by date
        exams.sort((a, b) {
          final dateA = DateTime.tryParse(a.date) ?? DateTime.now();
          final dateB = DateTime.tryParse(b.date) ?? DateTime.now();
          return dateB.compareTo(dateA);
        });

        final upcomingExams = exams.where((e) => e.isUpcoming).toList();
        final pastExams = exams.where((e) => e.isPast).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcomingExams.isNotEmpty) ...[
                _buildSectionHeader('Upcoming Exams', Icons.event, Colors.red),
                const SizedBox(height: 12),
                ...upcomingExams.map((exam) => _buildExamCard(exam, true)),
                const SizedBox(height: 24),
              ],
              if (pastExams.isNotEmpty) ...[
                _buildSectionHeader('Past Exams', Icons.history, Colors.grey),
                const SizedBox(height: 12),
                ...pastExams.map((exam) => _buildExamCard(exam, false)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildExamCard(Exam exam, bool isUpcoming) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUpcoming ? Colors.red.shade50 : Colors.grey.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUpcoming
              ? Colors.red.shade200
              : Colors.grey.shade300,
          child: Icon(
            Icons.assignment,
            color: isUpcoming ? Colors.red.shade900 : Colors.grey.shade700,
          ),
        ),
        title: Text(
          exam.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('📋 ${exam.type}'),
            Text('📅 ${exam.date}'),
            if (exam.room != null) Text('📍 ${exam.room}'),
            if (exam.section != null) Text('🎓 Section ${exam.section}'),
          ],
        ),
        trailing: isUpcoming
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Upcoming',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              )
            : null,
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Exams Scheduled',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Exam schedules will appear here when faculty adds them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
