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
  bool _isTableView = false; // Toggle between list and table view

  final List<String> _timeSlots = [
    '09:00-10:00',
    '10:00-11:00',
    '11:00-12:00',
    '12:00-01:00', // Lunch
    '01:00-02:00',
    '02:00-03:00',
    '03:00-04:00',
  ];

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

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

        return Column(
          children: [
            // View Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isTableView ? 'Table View' : 'List View',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('List'),
                        icon: Icon(Icons.list, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Table'),
                        icon: Icon(Icons.table_chart, size: 18),
                      ),
                    ],
                    selected: {_isTableView},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isTableView = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: _isTableView
                    ? _buildTableView(timetable)
                    : _buildListView(timetable),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListView(Timetable timetable) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timetable Info Card
          _buildInfoCard(),
          const SizedBox(height: 20),

          // Weekly Schedule
          ..._days.map((day) {
            final classes = timetable.getClassesForDay(day);
            return _buildDaySchedule(day, classes);
          }),
        ],
      ),
    );
  }

  Widget _buildTableView(Timetable timetable) {
    final routine = timetable.routine;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Your Timetable: ${_currentUser!.department} - Sem ${_currentUser!.semester} - Sec ${_currentUser!.section}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Table
              Table(
                border: TableBorder.all(color: Colors.grey[400]!, width: 1),
                columnWidths: {
                  0: const FixedColumnWidth(100), // Day column
                  for (var i = 1; i <= _timeSlots.length; i++)
                    i: const FixedColumnWidth(140), // Time slot columns
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue[700]),
                    children: [
                      _buildTableHeaderCell('Day / Time'),
                      ..._timeSlots.map((slot) => _buildTableHeaderCell(slot)),
                    ],
                  ),

                  // Data Rows
                  ..._days.map((day) {
                    final now = DateTime.now();
                    final dayNames = [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                    ];
                    final today = dayNames[now.weekday - 1];
                    final isToday = day == today;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.purple.shade50
                            : (_days.indexOf(day) % 2 == 0
                                  ? Colors.grey[50]
                                  : Colors.white),
                      ),
                      children: [
                        _buildDayCell(day, isToday),
                        ..._timeSlots.map((slot) {
                          return _buildClassCell(day, slot, routine);
                        }),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Legend
              _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDayCell(String day, bool isToday) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: isToday ? Colors.purple.shade100 : null,
      child: Text(
        day,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isToday ? Colors.purple.shade900 : null,
        ),
      ),
    );
  }

  Widget _buildClassCell(
    String day,
    String slot,
    Map<String, List<ClassPeriod>> routine,
  ) {
    // Get classes for this day
    final dayClasses = routine[day];
    if (dayClasses == null || dayClasses.isEmpty) {
      return _buildEmptyCellTable(slot);
    }

    // Find class for this time slot
    final classPeriod = dayClasses.firstWhere(
      (c) => c.timeSlot == slot,
      orElse: () => ClassPeriod(
        subject: '',
        teacher: '',
        courseCode: '',
        room: '',
        timeSlot: slot,
      ),
    );

    if (classPeriod.subject.isEmpty) {
      return _buildEmptyCellTable(slot);
    }

    // Check if lunch break
    final isLunch = slot == '12:00-01:00';

    return Container(
      padding: const EdgeInsets.all(8),
      color: isLunch ? Colors.orange[50] : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classPeriod.subject,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (classPeriod.teacher.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 10, color: Colors.grey[600]),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    classPeriod.teacher,
                    style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (classPeriod.room.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.room, size: 10, color: Colors.grey[600]),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    classPeriod.room,
                    style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCellTable(String slot) {
    final isLunch = slot == '12:00-01:00';

    return Container(
      padding: const EdgeInsets.all(8),
      color: isLunch ? Colors.orange[50] : null,
      child: Center(
        child: Text(
          isLunch ? '🍽️' : '-',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    color: Colors.orange[50],
                    margin: const EdgeInsets.only(right: 6),
                  ),
                  const Text('Lunch', style: TextStyle(fontSize: 11)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    color: Colors.purple[50],
                    margin: const EdgeInsets.only(right: 6),
                  ),
                  const Text('Today', style: TextStyle(fontSize: 11)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  const Text('Teacher', style: TextStyle(fontSize: 11)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.room, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  const Text('Room', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
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
