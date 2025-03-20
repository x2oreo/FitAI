import 'package:hk11/navigation/app_shell.dart';
import 'package:flutter/material.dart';
import 'view.dart';

class LoginOrSignupPage extends StatefulWidget {
  const LoginOrSignupPage({super.key});

  @override
  State<LoginOrSignupPage> createState() => _LoginOrSignupPageState();
}

class _LoginOrSignupPageState extends State<LoginOrSignupPage> {
  final _auth = AuthService();

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
                      child: Icon(
                        Icons.whatshot_rounded,
                        size: 40,
                        color: const Color.fromARGB(255, 0, 110, 255),
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
                      await _auth.loginWithGoogle();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AppShell(),
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
                        'images/icon-google.png',
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    icon: Icon(Icons.email_outlined),

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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => SignupPage()),
                      );
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
