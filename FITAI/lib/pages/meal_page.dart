import 'package:flutter/material.dart';

class MealPage extends StatelessWidget {
  const MealPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Page'),
      ),
      body: const Center(
        child: Text('Welcome to the Meal Page!'),
      ),
    );
  }
}