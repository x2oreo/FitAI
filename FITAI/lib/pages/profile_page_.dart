import 'package:hk11/pages/view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hk11/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color:
                theme.appBarTheme.backgroundColor == Colors.white
                    ? Colors.black
                    : Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            color:
                theme.appBarTheme.backgroundColor == Colors.white
                    ? Colors.black
                    : Colors.white,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Profile picture
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.dividerColor,
              child: Icon(Icons.person, size: 60, color: theme.primaryColor),
            ),

            const SizedBox(height: 24),

            // User name
            Text(
              user?.displayName ?? 'User',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // User info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.email,
                      color: theme.listTileTheme.iconColor,
                    ),
                    title: Text('Email', style: theme.textTheme.bodyMedium),
                    subtitle: Text(
                      user?.email ?? 'Not provided',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginOrSignupPage(),
                    ),
                  );
                },
                style: theme.elevatedButtonTheme.style,
                child: Text('Sign Out', style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
