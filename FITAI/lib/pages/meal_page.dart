import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../config/api_config.dart';

class MealPage extends StatefulWidget {
  const MealPage({Key? key}) : super(key: key);

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  int _selectedDay = 1; // Default to day 1 instead of 0
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Diet plan data
  Map<String, dynamic> _dietPlan = {};
  bool _isLoading = true;
  bool _isGeneratingPlan = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDietPlan();
  }

  // Fetch diet plan from Firestore
  Future<void> _fetchDietPlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      print('Fetching diet plan for user: $userId');

      DocumentSnapshot doc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('plans')
              .doc('diet')
              .get();

      if (doc.exists) {
        print('Diet plan document exists');
        var data = doc.data();
        print('Raw data: $data');

        if (data != null && data is Map<String, dynamic>) {
          setState(() {
            _dietPlan = data;
            _isLoading = false;
          });

          // Log the keys to debug
          print('Diet plan keys: ${_dietPlan.keys.join(', ')}');
          // Check for day1, day2, etc.
          for (int i = 1; i <= 7; i++) {
            String dayKey = 'day$i';
            print('$dayKey exists: ${_dietPlan.containsKey(dayKey)}');
            if (_dietPlan.containsKey(dayKey)) {
              // Check if value is a string or another data type
              var value = _dietPlan[dayKey];
              print('$dayKey value type: ${value.runtimeType}');
            }
          }
        } else {
          setState(() {
            _errorMessage = 'Diet plan has invalid format';
            _isLoading = false;
          });
          print('Data is null or not a Map: $data');
        }
      } else {
        setState(() {
          _errorMessage =
              'No diet plan found. Generate one from the home page.';
          _isLoading = false;
        });
        print('Diet plan document does not exist');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading diet plan: ${e.toString()}';
        _isLoading = false;
      });
      print('Error fetching diet plan: $e');
    }
  }

  Future<void> _generateDietPlan() async {
    setState(() {
      _isGeneratingPlan = true;
    });

    try {
      // Get the current user ID
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';

      // Fetch user data from Firestore
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please complete your profile first')),
        );
        setState(() {
          _isGeneratingPlan = false;
        });
        return;
      }

      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

      // Gather dietary preferences if they exist
      List<String> selectedDiets = [];
      if (userData['dietary_preferences'] != null) {
        if (userData['dietary_preferences'] is List) {
          selectedDiets = List<String>.from(userData['dietary_preferences']);
        } else if (userData['dietary_preferences'] is String) {
          selectedDiets = [userData['dietary_preferences']];
        }
      }

      // Prepare user info for the API request
      List<String> userInfo = [
        "Activity Level - ${userData['activity_level'] ?? 'N/A'}",
        "Age - ${userData['age'] ?? 'N/A'}",
        "Dietary Preferences - ${selectedDiets.join(', ')}",
        "Gender - ${userData['gender'] ?? 'N/A'}",
        "Goal - ${userData['goal'] ?? 'N/A'}",
        "Height - ${userData['height'] ?? 'N/A'} ${userData['height_unit'] ?? 'cm'}",
        "Monthly Budget - ${userData['monthly_budget'] ?? 'N/A'}",
      ];

      // Make API request with detailed logging
      print('Making API request to generate diet plan...');
      var response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}generate-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'variant': 'diet',
          'userInfo': userInfo,
          'pastExperiences': userData['lastWeekExperience'] ?? '',
        }),
      );

      print('API response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Successfully generated plan
        try {
          // Parse the JSON response
          Map<String, dynamic> dietPlanResponse = jsonDecode(response.body);
          print('Successfully parsed API response to JSON');

          // Log the structure
          print('Diet plan keys: ${dietPlanResponse.keys.join(', ')}');

          // Check if we have the expected structure (day1, day2, etc.)
          if (dietPlanResponse.containsKey('day1')) {
            // Save the data directly to maintain the structure
            Map<String, dynamic> firestoreData = {
              'createdAt': FieldValue.serverTimestamp(),
            };

            // Add each day's plan to the data
            for (String key in dietPlanResponse.keys) {
              firestoreData[key] = dietPlanResponse[key];
            }

            print(
              'Prepared diet plan data for Firestore: ${firestoreData.keys.join(', ')}',
            );

            // Store in Firestore
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('plans')
                .doc('diet')
                .set(firestoreData);

            print('Successfully stored diet plan in Firestore');

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Diet plan generated successfully!')),
            );

            // Refresh the diet plan display
            _fetchDietPlan();
          } else {
            print('Unexpected diet plan structure. Missing day entries.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Generated plan has invalid structure. Please try again.',
                ),
              ),
            );
          }
        } catch (parseError) {
          print('Error parsing API response: $parseError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to process diet plan. Error: $parseError'),
            ),
          );
        }
      } else {
        print('API returned error status code: ${response.statusCode}');
        print('Error response body: ${response.body}');
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to generate diet plan. Status: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error generating diet plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred: ${e.toString().substring(0, min(50, e.toString().length))}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isGeneratingPlan = false;
      });
    }
  }

  // Get meal info for the selected day
  String getMealInfo(int day) {
    String dayKey = 'day$day';
    if (_dietPlan.containsKey(dayKey)) {
      var dayData = _dietPlan[dayKey];
      if (dayData is String) {
        return dayData; // Already in text format, assume it's markdown
      } else if (dayData is Map) {
        // Convert map to markdown format
        StringBuffer markdown = StringBuffer();

        dayData.forEach((mealType, mealDetails) {
          markdown.writeln('');

          if (mealDetails is String) {
            markdown.writeln(mealDetails);
          } else if (mealDetails is Map) {
            mealDetails.forEach((key, value) {
              markdown.writeln('');
              markdown.writeln('');
            });
          } else if (mealDetails is List) {
            for (var item in mealDetails) {
              markdown.writeln('- $item');
            }
          } else {
            markdown.writeln(mealDetails.toString());
          }

          markdown.writeln('');
        });

        return markdown.toString();
      } else {
        return '**Day $day data has unexpected format**\n\n${dayData.toString()}';
      }
    } else {
      return 'No information available for Day $day';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define better colors for dark mode
    final backgroundColor =
        isDarkMode
            ? Color(0xFF1E1E2C) // Dark blue-gray for dark mode
            : theme.colorScheme.primary.withOpacity(0.05);

    final cardColor =
        isDarkMode
            ? Color.fromARGB(
              255,
              120,
              120,
              172,
            ) // Matching the workout page card color
            : Color.fromARGB(
              255,
              0,
              0,
              63,
            ); // Matching the workout page card color

    // Define more visible accent colors
    final accentColor =
        isDarkMode
            ? Color(0xFF8A85FF) // Vibrant purple for dark mode
            : Color(
              0xFF3D63B6,
            ); // Deeper blue for light mode to ensure contrast with white text

    final textColor = Colors.white; // Always white to match workout page

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Plan'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode
                  ? Color(0xFF222237) // Deep blue-purple for dark mode
                  : theme.colorScheme.primary.withOpacity(0.15),
              backgroundColor,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day selector cards
              Container(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isSelected = _selectedDay == day;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: 70,
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? (isDarkMode
                                      ? accentColor
                                      : Color(
                                        0xFF3D63B6,
                                      )) // Darker blue for light mode
                                  : isDarkMode
                                  ? Color(
                                    0xFF35354A,
                                  ) // Lighter shade for dark mode
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: (isDarkMode
                                              ? accentColor
                                              : Color(0xFF3D63B6))
                                          .withOpacity(0.6),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                  : isDarkMode
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                  : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                          border:
                              !isSelected && !isDarkMode
                                  ? Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1.5,
                                  )
                                  : null,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDay = day;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'DAY',
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : isDarkMode
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$day',
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Display selected meal information
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        isDarkMode
                            ? Border.all(
                              color: accentColor.withOpacity(0.3),
                              width: 1.0,
                            )
                            : null,
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                        blurRadius: isDarkMode ? 15 : 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child:
                      _isLoading
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: accentColor),
                                SizedBox(height: 16),
                                Text(
                                  'Loading your meal plan...',
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.white.withOpacity(0.8)
                                            : theme.hintColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : _errorMessage.isNotEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.no_meals_outlined,
                                  color:
                                      isDarkMode
                                          ? Colors.redAccent.shade200
                                          : theme.colorScheme.error,
                                  size: 64,
                                ),
                                SizedBox(height: 24),
                                Text(
                                  _errorMessage,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color:
                                        isDarkMode
                                            ? Colors.redAccent.shade200
                                            : theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Use the button below to create a new meal plan',
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.white.withOpacity(0.8)
                                            : theme.textTheme.bodyMedium?.color,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDarkMode
                                              ? accentColor
                                              : Color(0xFF3D63B6),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow:
                                          isDarkMode
                                              ? [
                                                BoxShadow(
                                                  color: accentColor
                                                      .withOpacity(0.4),
                                                  blurRadius: 6,
                                                  offset: Offset(0, 3),
                                                ),
                                              ]
                                              : [
                                                BoxShadow(
                                                  color: Color(
                                                    0xFF3D63B6,
                                                  ).withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                    ),
                                    child: Text(
                                      'DAY ${_selectedDay}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Meal Plan',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Colors
                                              .white, // Always white regardless of theme
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                height: 32,
                                color:
                                    isDarkMode
                                        ? Colors.white.withOpacity(0.15)
                                        : theme.dividerColor,
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Markdown(
                                      data: getMealInfo(_selectedDay),
                                      selectable: true,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      styleSheet: MarkdownStyleSheet(
                                        h1: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        h2: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        h3: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                        p: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        strong: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        em: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white,
                                        ),
                                        blockquote: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        code: TextStyle(
                                          color: Colors.white,
                                          backgroundColor: Colors.black38,
                                          fontSize: 16,
                                          fontFamily: 'monospace',
                                        ),
                                        a: TextStyle(
                                          color: Colors.lightBlueAccent,
                                          decoration: TextDecoration.underline,
                                        ),
                                        listBullet: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        checkbox: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        tableHead: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        tableBody: TextStyle(
                                          color: Colors.white,
                                        ),
                                        textAlign: WrapAlignment.start,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                ),
              ),

              // Add a refresh button at the bottom
              if (!_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: ElevatedButton(
                    onPressed: _isGeneratingPlan ? null : _generateDietPlan,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 56),
                      backgroundColor:
                          isDarkMode
                              ? Color(0xFF6EE7B7) // Vibrant teal for dark mode
                              : Colors.greenAccent.shade400,
                      foregroundColor: Colors.black87,
                      elevation: 4,
                      shadowColor:
                          isDarkMode
                              ? Color(0xFF6EE7B7).withOpacity(0.6)
                              : Colors.greenAccent.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        _isGeneratingPlan
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black54,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Generating meal plan...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant_menu, size: 22),
                                SizedBox(width: 12),
                                Text(
                                  'Generate Personalized Diet Plan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
