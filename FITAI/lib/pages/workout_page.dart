import 'package:flutter/material.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Page'),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Workout Page!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}