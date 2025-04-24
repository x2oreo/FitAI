import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hk11/theme/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
      List<String> userInfoList = [
        "Activity Level - ${userData['activity_level'] ?? 'N/A'}",
        "Age - ${userData['age'] ?? 'N/A'}",
        "Dietary Preferences - ${selectedDiets.join(', ')}",
        "Gender - ${userData['gender'] ?? 'N/A'}",
        "Goal - ${userData['goal'] ?? 'N/A'}",
        "Height - ${userData['height'] ?? 'N/A'} ${userData['height_unit'] ?? 'cm'}",
        "Monthly Budget - ${userData['monthly_budget'] ?? 'N/A'}",
      ];

      
      // Fetch recent journal entries (last 3 days)
      try {
        print('Fetching recent journal entries...');
        final now = DateTime.now();
        final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
        
        final journalSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('journal_entries')
            .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(threeDaysAgo))
            .orderBy('date', descending: true)
            .limit(3)
            .get();
            
        if (journalSnapshot.docs.isNotEmpty) {
          userInfoList.add("\nRecent Journal Entries:");
          for (var entry in journalSnapshot.docs) {
            final data = entry.data();
            final date = data['date'] as String? ?? 'Unknown date';
            final content = data['content'] as String? ?? '';
            
            if (content.isNotEmpty) {
              // Add a summary of the journal entry (first 100 characters)
              final summary = content.length > 100 
                  ? '${content.substring(0, 100)}...' 
                  : content;
              userInfoList.add("[$date] $summary");
            }
          }
        } else {
          userInfoList.add("\nNo recent journal entries found.");
        }
      } catch (e) {
        print('Error fetching journal entries: $e');
        userInfoList.add("\nCould not retrieve journal entries.");
      }
      

      String userInfo = userInfoList.join('\n');

      // Make API request with detailed logging
      print('Making API request to generate diet plan...');
      var response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/generatePlanV2'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'variant': 'diet',
          'userInfo': userInfo,
          'pastExperiences': "the user has no past experiences",
        }),
      );

      print('API response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Successfully generated plan
        try {
          // Parse the JSON response
          Map<String, dynamic> dietPlanResponse = jsonDecode(response.body);
          print('Successfully parsed API response to JSON');

          // Check if the response contains a "plan" key
          if (dietPlanResponse.containsKey('plan')) {
            // Extract the diet plan from the "plan" key
            dietPlanResponse = dietPlanResponse['plan'];
            print('Diet plan extracted from "plan" key');
          }

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
    var isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // Define more visible accent colors
    final accentColor = Color(0xFF8A85FF);
    // Deeper blue for light mode to ensure contrast with white text

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Weekly Meal Plan'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDarkMode
                    ? [Color(0xFF250050), Color.fromARGB(255, 0, 0, 0)]
                    : [Colors.white, const Color(0xFF6f6f6f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top),

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
                                  ? (theme.colorScheme.onSecondary)
                                  : isDarkMode
                                  ? Color(0xFF35354A)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(16),

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
                    color: theme.colorScheme.primary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
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
                                  style: theme.textTheme.titleLarge
                                  
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
                                      color: theme.colorScheme.onSecondary,
                                      borderRadius: BorderRadius.circular(12),
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
                                      color: theme.colorScheme.secondary,
                                          
                                    ), // Always white regardless of theme
                                    
                                  ),
                                ],
                              ),
                              Divider(
                                height: 32,
                                color: theme.colorScheme.secondary.withOpacity(0.5),
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
                                        h1: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        h2: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        h3: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        p: theme.textTheme.bodyMedium,
                                        strong: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        em: theme.textTheme.bodyMedium?.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                        blockquote: theme.textTheme.bodyMedium?.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                        code: theme.textTheme.bodyMedium?.copyWith(
                                          backgroundColor: Colors.black38,
                                          fontFamily: 'monospace',
                                        ),
                                        a: theme.textTheme.bodyMedium?.copyWith(
                                          decoration: TextDecoration.underline,
                                        ),
                                        listBullet: theme.textTheme.bodyMedium,
                                        checkbox: theme.textTheme.bodyMedium,
                                        tableHead: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        tableBody: theme.textTheme.bodyMedium,
                                        textAlign: WrapAlignment.start,
                                      ),
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
                                Icon(
                                  Icons.restaurant_menu,
                                  size: 22,
                                  color: theme.colorScheme.secondary,
                                ),

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
