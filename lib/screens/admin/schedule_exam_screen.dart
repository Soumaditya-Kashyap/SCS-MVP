import 'package:flutter/material.dart';

class ScheduleExamScreen extends StatelessWidget {
  const ScheduleExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Exam'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Schedule Exam - Coming Soon')),
    );
  }
}
