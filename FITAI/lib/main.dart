import 'package:flutter/material.dart';
import 'package:hk11/pages/home_page.dart';
import 'package:hk11/pages/onboarding.dart';
import 'package:hk11/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:hk11/pages/view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:hk11/navigation/app_shell.dart'; // Add this import

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      theme: themeProvider.theme,
      home: LoginOrSignupPage(), // Changed from MyHomePage to AppShell
      debugShowCheckedModeBanner: false,
    );
  }
}


