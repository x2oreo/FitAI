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
  int _selectedDay = 0; // 0 means no day selected
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
        Uri.parse('${ApiConfig.baseUrl}/generate-plan'),
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
    if (day == 0) {
      return '## Select a day to view meal plan details';
    }

    String dayKey = 'day$day';
    if (_dietPlan.containsKey(dayKey)) {
      var dayData = _dietPlan[dayKey];
      if (dayData is String) {
        return dayData; // Already in text format, assume it's markdown
      } else if (dayData is Map) {
        // Convert map to markdown format
        StringBuffer markdown = StringBuffer();

        dayData.forEach((mealType, mealDetails) {
          // markdown.writeln('## $mealType');
          markdown.writeln('');

          if (mealDetails is String) {
            markdown.writeln(mealDetails);
          } else if (mealDetails is Map) {
            mealDetails.forEach((key, value) {
              // markdown.writeln('### $key');
              markdown.writeln('');
              // markdown.writeln(value.toString());
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

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Meal Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day buttons in a row
            Container(
              height: 60,
              width: double.infinity,
              child: Row(
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDay == day;

                  return Expanded(
                    flex: 1, // Explicit flex to ensure equal width
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 4.0,
                      ), // Equal margin on all sides
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDay = day;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? theme.hintColor
                                    : theme.colorScheme.primary.withOpacity(
                                      0.3,
                                    ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.hintColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Day',
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : theme.textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '$day',
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : theme.textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // Display selected meal information
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.hintColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child:
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _errorMessage.isNotEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.amber,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        : SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight:
                                  MediaQuery.of(context).size.height * 0.3,
                            ),
                            child: Markdown(
                              data: getMealInfo(_selectedDay),
                              selectable: true,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              styleSheet: MarkdownStyleSheet(
                                h1: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                h2: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                h3: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                p: theme.textTheme.bodyMedium,
                                textAlign: WrapAlignment.start,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
              ),
            ),

            // Add a refresh button at the bottom
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: _isGeneratingPlan ? null : _generateDietPlan,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.greenAccent.withOpacity(0.7),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                              Text('Generating diet plan...'),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu),
                              SizedBox(width: 8),
                              Text('Generate Personalized Diet Plan'),
                            ],
                          ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
