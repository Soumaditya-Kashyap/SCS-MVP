import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/timetable_model.dart';

class StudentRoutineScreen extends StatefulWidget {
  const StudentRoutineScreen({super.key});

  @override
  State<StudentRoutineScreen> createState() => _StudentRoutineScreenState();
}

class _StudentRoutineScreenState extends State<StudentRoutineScreen> {
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

    return FutureBuilder<Map<String, dynamic>?>(
      future: FirestoreService().getTimetable(
        department: _currentUser!.department,
        semester: _currentUser!.semester!,
        section: _currentUser!.section!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyState();
        }

        final timetableData = snapshot.data!;
        final timetable = Timetable.fromMap(
          timetableData,
          timetableData['id'] ?? '',
        );

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timetable Info Card
                _buildInfoCard(),
                const SizedBox(height: 20),

                // Weekly Schedule
                ...[
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                ].map((day) {
                  final classes = timetable.getClassesForDay(day);
                  return _buildDaySchedule(day, classes);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Weekly Routine',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentUser!.department} • Sem ${_currentUser!.semester} • Sec ${_currentUser!.section}',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySchedule(String day, List<ClassPeriod> classes) {
    final now = DateTime.now();
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final today = days[now.weekday - 1];
    final isToday = day == today;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isToday ? Colors.purple.shade50 : null,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isToday
              ? Colors.purple.shade200
              : Colors.grey.shade200,
          child: Text(
            day.substring(0, 3),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.purple.shade900 : Colors.grey.shade700,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.purple.shade900 : null,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Chip(
                label: const Text('Today', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.purple.shade100,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        subtitle: Text('${classes.length} classes'),
        children: classes.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No classes scheduled',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ]
            : classes.map((classPeriod) {
                return ListTile(
                  dense: true,
                  leading: Icon(
                    classPeriod.isBreak ? Icons.restaurant : Icons.book,
                    color: classPeriod.isBreak ? Colors.orange : Colors.blue,
                    size: 20,
                  ),
                  title: Text(
                    classPeriod.subject,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    '${classPeriod.teacher} • ${classPeriod.room}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    classPeriod.timeSlot,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                );
              }).toList(),
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
              Icons.calendar_today_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Timetable Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your weekly routine will appear here once created by faculty.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
