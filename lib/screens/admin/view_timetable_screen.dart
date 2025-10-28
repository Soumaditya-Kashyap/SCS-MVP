import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class ViewTimetableScreen extends StatefulWidget {
  const ViewTimetableScreen({super.key});

  @override
  State<ViewTimetableScreen> createState() => _ViewTimetableScreenState();
}

class _ViewTimetableScreenState extends State<ViewTimetableScreen> {
  final _firestoreService = FirestoreService();

  String? _selectedDepartment;
  String? _selectedSemester;
  String? _selectedSection;
  bool _isLoading = false;
  Map<String, dynamic>? _timetableData;

  final List<String> _departments = ['CSE', 'ECE', 'ME', 'CE', 'EE', 'IT'];
  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];
  final List<String> _sections = ['A', 'B', 'C', 'D'];

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<String> _timeSlots = [
    '09:00-10:00',
    '10:00-11:00',
    '11:00-12:00',
    '12:00-01:00', // Lunch
    '01:00-02:00',
    '02:00-03:00',
    '03:00-04:00',
  ];

  Future<void> _loadTimetable() async {
    if (_selectedDepartment == null ||
        _selectedSemester == null ||
        _selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select department, semester, and section'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await _firestoreService.getTimetable(
        department: _selectedDepartment!,
        semester: _selectedSemester!,
        section: _selectedSection!,
      );

      setState(() {
        _timetableData = data;
        _isLoading = false;
      });

      if (data == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No timetable found for this selection'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading timetable: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Timetable'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Selection Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[50],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(dept),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                            _timetableData = null; // Reset timetable
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSemester,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _semesters.map((sem) {
                          return DropdownMenuItem(
                            value: sem,
                            child: Text('Sem $sem'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSemester = value;
                            _timetableData = null; // Reset timetable
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSection,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _sections.map((section) {
                          return DropdownMenuItem(
                            value: section,
                            child: Text('Sec $section'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSection = value;
                            _timetableData = null; // Reset timetable
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadTimetable,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Load Timetable'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timetable Display
          Expanded(
            child: _timetableData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select filters and load timetable',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildTimetableTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableTable() {
    final routine = _timetableData!['routine'] as Map<String, dynamic>? ?? {};

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
                      'Timetable: $_selectedDepartment - Semester $_selectedSemester - Section $_selectedSection',
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
                    i: const FixedColumnWidth(150), // Time slot columns
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
                    return TableRow(
                      decoration: BoxDecoration(
                        color: _days.indexOf(day) % 2 == 0
                            ? Colors.grey[50]
                            : Colors.white,
                      ),
                      children: [
                        _buildDayCell(day),
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
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDayCell(String day) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        day,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildClassCell(
    String day,
    String slot,
    Map<String, dynamic> routine,
  ) {
    // Get classes for this day
    final dayClasses = routine[day] as List<dynamic>?;
    if (dayClasses == null || dayClasses.isEmpty) {
      return _buildEmptyCell(slot);
    }

    // Find class for this time slot
    final classData = dayClasses.firstWhere(
      (c) => c['time'] == slot,
      orElse: () => null,
    );

    if (classData == null) {
      return _buildEmptyCell(slot);
    }

    final subject = classData['subject'] ?? '';
    final teacher = classData['teacher'] ?? '';
    final room = classData['room'] ?? '';

    // Check if lunch break
    final isLunch = slot == '12:00-01:00';

    return Container(
      padding: const EdgeInsets.all(8),
      color: isLunch ? Colors.orange[50] : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subject.isNotEmpty) ...[
            Text(
              subject,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (teacher.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      teacher,
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (room.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.room, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      room,
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCell(String slot) {
    final isLunch = slot == '12:00-01:00';

    return Container(
      padding: const EdgeInsets.all(8),
      color: isLunch ? Colors.orange[50] : null,
      child: Center(
        child: Text(
          isLunch ? '🍽️ Lunch' : '-',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontStyle: isLunch ? FontStyle.normal : FontStyle.italic,
          ),
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                color: Colors.orange[50],
                margin: const EdgeInsets.only(right: 8),
              ),
              const Text('Lunch Break', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 24),
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              const Text('Teacher', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.room, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              const Text('Room', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
