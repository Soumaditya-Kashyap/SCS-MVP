import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/timetable_model.dart';
import '../auth/login_screen.dart';
import 'student_exams_screen.dart';
import 'student_routine_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      StudentHomePage(user: _currentUser),
      const StudentExamsScreen(),
      const StudentRoutineScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Exams'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Routine',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Exams';
      case 2:
        return 'Routine';
      default:
        return 'Smart Class Scheduler';
    }
  }
}

// Home Page Content
class StudentHomePage extends StatefulWidget {
  final AppUser? user;

  const StudentHomePage({super.key, this.user});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(child: CircularProgressIndicator());
    }

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

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger rebuild by changing the key
        setState(() {
          _refreshKey++;
        });
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Card
              _buildGreetingCard(context),
              const SizedBox(height: 20),

              // Today's Classes Section
              _buildSectionHeader('Today\'s Classes', Icons.schedule, today),
              const SizedBox(height: 12),
              _buildTodaysClasses(context),
              const SizedBox(height: 24),

              // Unscheduled Classes Section
              _buildSectionHeader('Upcoming Extra Classes', Icons.add_alert),
              const SizedBox(height: 12),
              _buildUnscheduledClasses(context),
              const SizedBox(height: 24),

              // Upcoming Exams Section
              _buildSectionHeader('Upcoming Exams', Icons.assignment_outlined),
              const SizedBox(height: 12),
              _buildUpcomingExams(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user!.enrollmentId ?? 'Student',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.user!.department} • Sem ${widget.user!.semester} • Sec ${widget.user!.section}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, [String? subtitle]) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTodaysClasses(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: FirestoreService().getTimetable(
        department: widget.user!.department,
        semester: widget.user!.semester!,
        section: widget.user!.section!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyState(
            'No timetable available',
            'Your timetable will appear here once created by faculty.',
            Icons.event_busy,
          );
        }

        final timetableData = snapshot.data!;
        final timetable = Timetable.fromMap(
          timetableData,
          timetableData['id'] ?? '',
        );
        final todaysClasses = timetable.getTodaysClasses();

        if (todaysClasses.isEmpty) {
          return _buildEmptyState(
            'No classes today',
            'Enjoy your day off!',
            Icons.celebration,
          );
        }

        return Column(
          children: todaysClasses.map((classPeriod) {
            return _buildClassCard(classPeriod);
          }).toList(),
        );
      },
    );
  }

  Widget _buildClassCard(ClassPeriod classPeriod) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: classPeriod.isBreak
              ? Colors.orange.shade100
              : Colors.blue.shade100,
          child: Icon(
            classPeriod.isBreak ? Icons.restaurant : Icons.book,
            color: classPeriod.isBreak
                ? Colors.orange.shade700
                : Colors.blue.shade700,
          ),
        ),
        title: Text(
          classPeriod.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('👨‍🏫 ${classPeriod.teacher}'),
            Text('📍 ${classPeriod.room} • ${classPeriod.courseCode}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            classPeriod.timeSlot,
            style: TextStyle(
              color: Colors.purple.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildUnscheduledClasses(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('unscheduled_$_refreshKey'),
      stream: FirestoreService().getUnscheduledClasses(widget.user!.department),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'No extra classes',
            'Extra classes scheduled by faculty will appear here.',
            Icons.check_circle_outline,
          );
        }

        final classes = snapshot.data!.docs
            .map(
              (doc) => UnscheduledClass.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .where((c) {
              // Filter by upcoming date
              if (!c.isUpcoming) return false;
              
              // Filter by semester: show if null (for all) or matches student's semester
              if (c.semester != null && c.semester != widget.user!.semester) {
                return false;
              }
              
              // Filter by section: show if null (for all) or matches student's section
              if (c.section != null && c.section != widget.user!.section) {
                return false;
              }
              
              return true;
            })
            .toList();

        if (classes.isEmpty) {
          return _buildEmptyState(
            'No upcoming extra classes',
            'You\'re all caught up!',
            Icons.check_circle_outline,
          );
        }

        return Column(
          children: classes.take(3).map((unscheduledClass) {
            return _buildUnscheduledClassCard(unscheduledClass);
          }).toList(),
        );
      },
    );
  }

  Widget _buildUnscheduledClassCard(UnscheduledClass unscheduledClass) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.amber.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber.shade200,
          child: Icon(Icons.add_alert, color: Colors.amber.shade900),
        ),
        title: Text(
          unscheduledClass.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('👨‍🏫 ${unscheduledClass.teacher}'),
            if (unscheduledClass.topic != null)
              Text('📝 ${unscheduledClass.topic}'),
            Text('📅 ${unscheduledClass.date} at ${unscheduledClass.time}'),
          ],
        ),
        trailing: unscheduledClass.isToday
            ? Chip(
                label: const Text('Today', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.red.shade100,
                side: BorderSide.none,
              )
            : null,
        isThreeLine: true,
      ),
    );
  }

  Widget _buildUpcomingExams(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('exams_$_refreshKey'),
      stream: FirestoreService().getExams(
        widget.user!.department,
        semester: widget.user!.semester,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'No exams scheduled',
            'Exam schedules will appear here.',
            Icons.assignment_turned_in,
          );
        }

        final exams = snapshot.data!.docs
            .map(
              (doc) => Exam.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .where((e) => e.isUpcoming)
            .toList();

        if (exams.isEmpty) {
          return _buildEmptyState(
            'No upcoming exams',
            'All clear for now!',
            Icons.assignment_turned_in,
          );
        }

        return Column(
          children: exams.take(3).map((exam) {
            return _buildExamCard(exam);
          }).toList(),
        );
      },
    );
  }

  Widget _buildExamCard(Exam exam) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.red.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade200,
          child: Icon(Icons.assignment, color: Colors.red.shade900),
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
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
