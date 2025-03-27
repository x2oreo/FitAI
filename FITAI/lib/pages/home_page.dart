import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/quotes_service.dart';
import 'workout_page.dart';
import 'meal_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final QuotesService _quotesService = QuotesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _currentQuote = 'Loading quote...';
  String _userGoal = 'Loading goal...';
  int _currentDayNum = 1;
  bool _isLoading = true;
  bool _isLoadingGoal = true;

  @override
  void initState() {
    super.initState();
    _loadQuote();
    _fetchUserData();
  }

  Future<void> _loadQuote() async {
    try {
      final quote = await _quotesService.getRandomQuote();
      setState(() {
        _currentQuote = quote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentQuote = 'Failed to load quote';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoadingGoal = true;
    });

    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String goal = userData['goal'] ?? '10.000 steps';
        Timestamp? createdAtTimestamp = userData['createdAt'] as Timestamp?;
        int storedDayNum = userData['dayNum'] ?? 1;

        int calculatedDayNum = 1;
        if (createdAtTimestamp != null) {
          DateTime createdAt = createdAtTimestamp.toDate();
          DateTime now = DateTime.now();
          int daysDifference = now.difference(createdAt).inDays;
          calculatedDayNum = (daysDifference % 7) + 1;
        }

        if (calculatedDayNum != storedDayNum) {
          await _firestore.collection('users').doc(userId).update({
            'dayNum': calculatedDayNum,
          });
        }

        setState(() {
          _userGoal = goal;
          _currentDayNum = calculatedDayNum;
        });
      } else {
        setState(() {
          _userGoal = '10.000 steps';
          _currentDayNum = 1;
        });
      }
    } catch (e) {
      setState(() {
        _userGoal = '10.000 steps';
        _currentDayNum = 1;
      });
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoadingGoal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [
                      Color(0xFF250050), // Dark purple
                      Color(0xFF24004e), // Dark purple
                      Color(0xFF210047), // Dark purple
                      Color(0xFF1d0040), // Medium dark purple
                      Color(0xFF1b003d), // Medium dark purple
                      Color(0xFF190039), // Dark purple
                      Color(0xFF170036), // Medium dark purple
                      Color(0xFF160132), // Medium dark purple
                      Color(0xFF14022d), // Dark purple/indigo
                      Color(0xFF120327), // Very dark purple with hint of blue
                      Color(0xFF110325), // Very dark purple
                      Color(0xFF0e021d), // Very dark purple
                      Color(0xFF090213), // Almost black with hint of purple
                      Color(0xFF040109), // Almost black
                      Color(0xFF000000), // Black 
                    ]
                    : [
                      Color(0xFF4bff60), // Bright green
                      Color(0xFF4eff64), // Bright green
                      Color(0xFF60ff7f), // Light green
                      Color(0xFF8fffb1), // Pastel green
                      Color(0xFFaeffcc), // Very light green
                      Color(0xFFb7ffd2), // Very light green
                      Color(0xFFb7ffd2), // Very light green
                      Color(0xFFb9fbd1), // Very light green/gray
                      Color(0xFFc0ebcf), // Light green/gray
                      Color(0xFFc7d4cc), // Green/gray
                      Color(0xFFcacbca), // Light gray
                      Color(0xFFcacaca),
                    ],
                  stops: isDarkMode
                    ? [0.0, 0.07, 0.14, 0.21, 0.28, 0.35, 0.42, 0.49, 0.56, 0.63, 0.7, 0.77, 0.84, 0.92, 1.0]
                    : null,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 70),

                // Quote container (replaced BlurTheme)
                Container(
                  decoration: BoxDecoration(
                    
                    borderRadius: BorderRadius.circular(16),
                    
                    color: theme.colorScheme.primary.withOpacity(0.9),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    height: 270,
                    width: double.infinity,
                    
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(
                            Icons.format_quote,
                            color: Colors.deepPurpleAccent,
                            size: 30,
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Icon(
                            Icons.format_quote,
                            color: Colors.deepPurple,
                            size: 30,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            
                            child: Row(
                              children: [
                                
                                SizedBox(width: 4),
                                Text(
                                  'Quote',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              30.0,
                              48.0,
                              30.0,
                              30.0,
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator()
                                : Container(
                                  constraints: BoxConstraints(
                                    minHeight: 120,
                                  ),
                                  child: Center(
                                    child: Text(
                                    _currentQuote,
                                    style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.visible,
                                    ),
                                  ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.primary.withOpacity(0.9),
                    
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    
                    child: Stack(
                      children: [
                        Positioned(
                          right: 15,
                          bottom: 15,
                          child: Icon(
                            Icons.star,
                            color: Colors.orangeAccent.withOpacity(0.5),
                            size: 40,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Goal',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              40.0,
                              16.0,
                              8.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _isLoadingGoal
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _userGoal,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              
                                            ),
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutPage(),
                      ),
                    );
                  },
                  
                  
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    
                    decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.primary.withOpacity(0.9),
                    
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: theme.hintColor,
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Workout',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: Text(
                            'Workout Routine',
                            style: theme.textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,                                          
                              ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MealPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    
                    decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.primary.withOpacity(0.9),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Row(
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: Colors.greenAccent,
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Meal',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: Text(
                            'Meal Plan',
                            style: theme.textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,                                          
                              ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
