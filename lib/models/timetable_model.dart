// Model for a single class period
class ClassPeriod {
  final String subject;
  final String teacher;
  final String courseCode;
  final String room;
  final String timeSlot; // e.g., "09:00-10:00"

  ClassPeriod({
    required this.subject,
    required this.teacher,
    required this.courseCode,
    required this.room,
    required this.timeSlot,
  });

  factory ClassPeriod.fromMap(Map<String, dynamic> map) {
    return ClassPeriod(
      subject: map['subject'] ?? '',
      teacher: map['teacher'] ?? '',
      courseCode: map['courseCode'] ?? '',
      room: map['room'] ?? '',
      timeSlot:
          map['timeSlot'] ??
          map['time'] ??
          '', // Support both old and new format
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'teacher': teacher,
      'courseCode': courseCode,
      'room': room,
      'timeSlot': timeSlot,
    };
  }

  // Check if this is a break/lunch period
  bool get isBreak =>
      subject.toLowerCase().contains('break') ||
      subject.toLowerCase().contains('lunch');

  // Check if this is a tutorial/remedial
  bool get isTutorial =>
      subject.toLowerCase().contains('tutorial') ||
      subject.toLowerCase().contains('remedial') ||
      subject.toLowerCase().contains('mentoring');
}

// Model for timetable
class Timetable {
  final String id;
  final String department;
  final String semester;
  final String section;
  final Map<String, List<ClassPeriod>> routine; // Day -> List of classes
  final DateTime? lastUpdated;

  Timetable({
    required this.id,
    required this.department,
    required this.semester,
    required this.section,
    required this.routine,
    this.lastUpdated,
  });

  factory Timetable.fromMap(Map<String, dynamic> map, String id) {
    Map<String, List<ClassPeriod>> routine = {};

    if (map['routine'] != null) {
      final routineMap = map['routine'] as Map<String, dynamic>;
      routineMap.forEach((day, classes) {
        if (classes is List) {
          routine[day] = classes
              .map(
                (classData) =>
                    ClassPeriod.fromMap(classData as Map<String, dynamic>),
              )
              .toList();
        }
      });
    }

    return Timetable(
      id: id,
      department: map['department'] ?? '',
      semester: map['semester'] ?? '',
      section: map['section'] ?? '',
      routine: routine,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> routineMap = {};
    routine.forEach((day, classes) {
      routineMap[day] = classes.map((c) => c.toMap()).toList();
    });

    return {
      'department': department,
      'semester': semester,
      'section': section,
      'routine': routineMap,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // Get classes for a specific day
  List<ClassPeriod> getClassesForDay(String day) {
    return routine[day] ?? [];
  }

  // Get today's classes
  List<ClassPeriod> getTodaysClasses() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final today = days[DateTime.now().weekday - 1];
    return getClassesForDay(today);
  }
}

// Model for unscheduled/extra class
class UnscheduledClass {
  final String id;
  final String department;
  final String? semester;
  final String? section;
  final String subject;
  final String teacher;
  final String date;
  final String time;
  final String? topic;
  final String? room;
  final DateTime? createdAt;

  UnscheduledClass({
    required this.id,
    required this.department,
    this.semester,
    this.section,
    required this.subject,
    required this.teacher,
    required this.date,
    required this.time,
    this.topic,
    this.room,
    this.createdAt,
  });

  factory UnscheduledClass.fromMap(Map<String, dynamic> map, String id) {
    return UnscheduledClass(
      id: id,
      department: map['department'] ?? '',
      semester: map['semester'],
      section: map['section'],
      subject: map['subject'] ?? '',
      teacher: map['teacher'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      topic: map['topic'],
      room: map['room'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'department': department,
      'semester': semester,
      'section': section,
      'subject': subject,
      'teacher': teacher,
      'date': date,
      'time': time,
      'topic': topic,
      'room': room,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Check if this class is today
  bool get isToday {
    final today = DateTime.now();
    final classDate = DateTime.tryParse(date);
    if (classDate == null) return false;
    return classDate.year == today.year &&
        classDate.month == today.month &&
        classDate.day == today.day;
  }

  // Check if this class is upcoming (future date/time)
  bool get isUpcoming {
    final classDate = DateTime.tryParse(date);
    if (classDate == null) return false;
    
    final now = DateTime.now();
    
    // If class date is in the future, it's upcoming
    if (classDate.year > now.year ||
        (classDate.year == now.year && classDate.month > now.month) ||
        (classDate.year == now.year && classDate.month == now.month && classDate.day > now.day)) {
      return true;
    }
    
    // If class date is today, check the time
    if (classDate.year == now.year && 
        classDate.month == now.month && 
        classDate.day == now.day) {
      try {
        // Parse time (format: "HH:MM" or "HH:MM AM/PM")
        final timeParts = time.split(':');
        if (timeParts.length >= 2) {
          int hour = int.parse(timeParts[0].trim());
          final minutePart = timeParts[1].trim().toUpperCase();
          int minute = int.parse(minutePart.replaceAll(RegExp(r'[^0-9]'), ''));
          
          // Handle AM/PM format
          if (minutePart.contains('PM') && hour != 12) {
            hour += 12;
          } else if (minutePart.contains('AM') && hour == 12) {
            hour = 0;
          }
          
          final classTime = DateTime(now.year, now.month, now.day, hour, minute);
          return classTime.isAfter(now);
        }
      } catch (e) {
        // If time parsing fails, show it if it's today
        return true;
      }
    }
    
    return false;
  }
}

// Model for exam
class Exam {
  final String id;
  final String department;
  final String semester;
  final String? section;
  final String subject;
  final String date;
  final String type; // Mid Term, Final, Quiz, etc.
  final String? room;
  final DateTime? createdAt;

  Exam({
    required this.id,
    required this.department,
    required this.semester,
    this.section,
    required this.subject,
    required this.date,
    required this.type,
    this.room,
    this.createdAt,
  });

  factory Exam.fromMap(Map<String, dynamic> map, String id) {
    return Exam(
      id: id,
      department: map['department'] ?? '',
      semester: map['semester'] ?? '',
      section: map['section'],
      subject: map['subject'] ?? '',
      date: map['date'] ?? '',
      type: map['type'] ?? '',
      room: map['room'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'department': department,
      'semester': semester,
      'section': section,
      'subject': subject,
      'date': date,
      'type': type,
      'room': room,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Check if exam is upcoming
  bool get isUpcoming {
    final examDate = DateTime.tryParse(date);
    if (examDate == null) return false;
    return examDate.isAfter(DateTime.now());
  }

  // Check if exam is past
  bool get isPast {
    final examDate = DateTime.tryParse(date);
    if (examDate == null) return false;
    return examDate.isBefore(DateTime.now());
  }
}
