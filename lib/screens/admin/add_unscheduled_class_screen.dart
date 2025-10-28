import 'package:flutter/material.dart';

class AddUnscheduledClassScreen extends StatelessWidget {
  const AddUnscheduledClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Unscheduled Class'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Add Unscheduled Class - Coming Soon')),
    );
  }
}
