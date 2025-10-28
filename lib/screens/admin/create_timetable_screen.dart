import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class CreateTimetableScreen extends StatefulWidget {
  const CreateTimetableScreen({super.key});

  @override
  State<CreateTimetableScreen> createState() => _CreateTimetableScreenState();
}

class _CreateTimetableScreenState extends State<CreateTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  String? _selectedDepartment;
  String? _selectedSemester;
  String? _selectedSection;
  bool _isLoading = false;

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
    '12:00-01:00', // Lunch break
    '01:00-02:00',
    '02:00-03:00',
    '03:00-04:00',
  ];

  // Store class data: Map<day, Map<timeSlot, ClassPeriod>>
  Map<String, Map<String, ClassPeriod>> _timetableData = {};

  @override
  void initState() {
    super.initState();
    _initializeTimetableData();
  }

  void _initializeTimetableData() {
    for (var day in _days) {
      _timetableData[day] = {};
      for (var slot in _timeSlots) {
        _timetableData[day]![slot] = ClassPeriod(
          subject: '',
          teacher: '',
          room: '',
        );
      }
    }
  }

  Future<void> _loadExistingTimetable() async {
    if (_selectedDepartment == null ||
        _selectedSemester == null ||
        _selectedSection == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existingData = await _firestoreService.getTimetable(
        department: _selectedDepartment!,
        semester: _selectedSemester!,
        section: _selectedSection!,
      );

      if (existingData != null && existingData['routine'] != null) {
        // Clear existing data first
        _initializeTimetableData();

        // Load existing data
        final routine = existingData['routine'] as Map<String, dynamic>;
        routine.forEach((day, classes) {
          if (classes is List) {
            for (var classData in classes) {
              final timeSlot = classData['timeSlot'] ?? classData['time'] ?? '';
              if (timeSlot.isNotEmpty &&
                  _timetableData[day]?[timeSlot] != null) {
                _timetableData[day]![timeSlot] = ClassPeriod(
                  subject: classData['subject'] ?? '',
                  teacher: classData['teacher'] ?? '',
                  room: classData['room'] ?? '',
                );
              }
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Loaded existing timetable for editing'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // No existing timetable
        _initializeTimetableData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No existing timetable. Creating new one.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading timetable: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _initializeTimetableData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTimetable() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartment == null ||
        _selectedSemester == null ||
        _selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select department, semester, and section'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert to Firestore format
      Map<String, dynamic> routine = {};
      _timetableData.forEach((day, slots) {
        List<Map<String, dynamic>> dayClasses = [];
        slots.forEach((time, classData) {
          if (classData.subject.isNotEmpty) {
            dayClasses.add({
              'timeSlot': time,
              'subject': classData.subject,
              'teacher': classData.teacher,
              'room': classData.room,
              'courseCode': '', // Optional field
            });
          }
        });
        if (dayClasses.isNotEmpty) {
          routine[day] = dayClasses;
        }
      });

      await _firestoreService.saveTimetable(
        department: _selectedDepartment!,
        semester: _selectedSemester!,
        section: _selectedSection!,
        routine: routine,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Timetable saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save timetable: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Timetable'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTimetable,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
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
                            });
                            // Load existing timetable if all selections are made
                            if (value != null &&
                                _selectedSemester != null &&
                                _selectedSection != null) {
                              _loadExistingTimetable();
                            }
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
                            });
                            // Load existing timetable if all selections are made
                            if (_selectedDepartment != null &&
                                value != null &&
                                _selectedSection != null) {
                              _loadExistingTimetable();
                            }
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
                            });
                            // Load existing timetable if all selections are made
                            if (_selectedDepartment != null &&
                                _selectedSemester != null &&
                                value != null) {
                              _loadExistingTimetable();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Timetable Grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: _days.map((day) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        ..._timeSlots.map((slot) {
                          return _buildTimeSlotCard(day, slot);
                        }).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveTimetable,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: const Text('Save Timetable'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildTimeSlotCard(String day, String timeSlot) {
    final classData = _timetableData[day]![timeSlot]!;
    final isLunchBreak = timeSlot == '12:00-01:00';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isLunchBreak ? Colors.orange[50] : Colors.white,
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLunchBreak ? Colors.orange : Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                timeSlot,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                classData.subject.isEmpty
                    ? (isLunchBreak ? 'Lunch Break' : 'No Class')
                    : classData.subject,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: classData.subject.isEmpty ? Colors.grey : Colors.black,
                ),
              ),
            ),
          ],
        ),
        children: [
          if (!isLunchBreak)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: classData.subject,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                    onChanged: (value) {
                      classData.subject = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: classData.teacher,
                    decoration: const InputDecoration(
                      labelText: 'Teacher',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (value) {
                      classData.teacher = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: classData.room,
                    decoration: const InputDecoration(
                      labelText: 'Room/Location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.room),
                    ),
                    onChanged: (value) {
                      classData.room = value;
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ClassPeriod {
  String subject;
  String teacher;
  String room;

  ClassPeriod({
    required this.subject,
    required this.teacher,
    required this.room,
  });
}
