import 'package:flutter/material.dart';

class ViewTimetableScreen extends StatelessWidget {
  const ViewTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Timetable'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('View Timetable - Coming Soon')),
    );
  }
}
