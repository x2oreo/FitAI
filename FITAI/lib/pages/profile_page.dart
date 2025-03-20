import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: theme.textTheme.headlineLarge),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Profile Page!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}