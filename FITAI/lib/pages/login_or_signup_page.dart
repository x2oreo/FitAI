import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hk11/navigation/app_shell.dart';
import 'package:hk11/pages/profile_page_.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view.dart';
import 'package:hk11/pages/onboarding.dart'; // Import the onboarding screen

class LoginOrSignupPage extends StatefulWidget {
  const LoginOrSignupPage({super.key});

  @override
  State<LoginOrSignupPage> createState() => _LoginOrSignupPageState();
}

class _LoginOrSignupPageState extends State<LoginOrSignupPage> {
  final _auth = AuthService();

  // Check if onboarding is complete
  Future<bool> _isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboardingComplete') ?? false;
  }

  // Add this function to your _LoginOrSignupPageState class
  Future<void> checkOnboardingAndNavigate(String userId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Check if the user has completed onboarding
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      // Close the loading dialog
      Navigator.pop(context);

      // Check if onboardingComplete exists and is true
      final bool onboardingComplete =
          userDoc.exists &&
          userDoc.data()?.containsKey('onboardingComplete') == true &&
          userDoc.data()?['onboardingComplete'] == true;

      if (onboardingComplete) {
        // User has completed onboarding, navigate to AppShell
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => AppShell()));
      } else {
        // User has not completed onboarding, navigate to OnboardingPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingPage()),
        );
      }
    } catch (e) {
      // Handle errors
      Navigator.pop(context); // Ensure dialog is closed in case of error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking onboarding status: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      // Default to onboarding in case of error
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Container(
          height: size.height - MediaQuery.of(context).padding.top,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 10,
                        width: 10,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Welcome!', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in to continue',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Sign in options
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Google Sign In
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Try to authenticate with Google
                      final user = await _auth.loginWithGoogle();

                      // If sign-in was cancelled or failed, just return
                      if (user == null) return;

                      // Always navigate to onboarding page
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => OnboardingPage(),
                        ),
                      );
                    },
                    icon: Container(
                      height: 20,
                      width: 23,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),

                      child: Image.asset(
                        'assets/icon-google.png',
                        height: 10,
                        width: 10,
                      ),
                    ),
                    label: Text(
                      'Continue with Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Email login
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Navigate to login page first
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );

                      // If login was successful and returned a user
                      if (result != null) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => OnboardingPage(),
                          ),
                        );
                      }
                    },

                    label: Text('Log In', style: theme.textTheme.bodyMedium),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.white24, thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Don't have an account?",
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.white24, thickness: 1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sign up
                  ElevatedButton(
                    onPressed: () async {
                      // Navigate to signup page first
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => SignupPage()),
                      );

                      // If signup was successful and returned a user
                      if (result != null) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => OnboardingPage(),
                          ),
                        );
                      }
                    },

                    child: Text(
                      'Create Account',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
