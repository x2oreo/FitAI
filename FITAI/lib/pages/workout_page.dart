import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../config/api_config.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _selectedDay = 0; // 0 means no day selected
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Workout information for each day
  Map<String, dynamic> _workoutPlan = {};
  bool _isLoading = true;
  bool _isGeneratingWorkoutPlan = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWorkoutPlan();
  }

  // Fetch workout plan from Firestore
  Future<void> _fetchWorkoutPlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      print('Fetching workout plan for user: $userId');

      DocumentSnapshot doc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('plans')
              .doc('workout')
              .get();

      if (doc.exists) {
        print('Workout plan document exists');
        var data = doc.data();
        print('Raw data: $data');

        if (data != null && data is Map<String, dynamic>) {
          setState(() {
            _workoutPlan = data;
            _isLoading = false;
          });

          // Log the keys to debug
          print('Workout plan keys: ${_workoutPlan.keys.join(', ')}');
          // Check for day1, day2, etc.
          for (int i = 1; i <= 7; i++) {
            String dayKey = 'day$i';
            print('$dayKey exists: ${_workoutPlan.containsKey(dayKey)}');
            if (_workoutPlan.containsKey(dayKey)) {
              // Check if value is a string or another data type
              var value = _workoutPlan[dayKey];
              print('$dayKey value type: ${value.runtimeType}');
            }
          }
        } else {
          setState(() {
            _errorMessage = 'Workout plan has invalid format';
            _isLoading = false;
          });
          print('Data is null or not a Map: $data');
        }
      } else {
        setState(() {
          _errorMessage =
              'No workout plan found. Generate one from the home page.';
          _isLoading = false;
        });
        print('Workout plan document does not exist');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading workout plan: ${e.toString()}';
        _isLoading = false;
      });
      print('Error fetching workout plan: $e');
    }
  }

  // Get workout info for the selected day
  String getWorkoutInfo(int day) {
    if (day == 0) {
      return 'Select a day to view workout details';
    }

    String dayKey = 'day$day';
    if (_workoutPlan.containsKey(dayKey)) {
      var dayData = _workoutPlan[dayKey];
      if (dayData is String) {
        return dayData; // Already in text format
      } else if (dayData is Map) {
        // Convert map to string format
        StringBuffer workoutDetails = StringBuffer();
        dayData.forEach((exercise, details) {
          workoutDetails.writeln('**$exercise:**');
          if (details is String) {
            workoutDetails.writeln(details);
          } else if (details is Map) {
            details.forEach((key, value) {
              workoutDetails.writeln('- $key: $value');
            });
          } else if (details is List) {
            for (var item in details) {
              workoutDetails.writeln('- $item');
            }
          }
          workoutDetails.writeln(''); // Add a newline after each exercise
        });
        return workoutDetails.toString();
      } else {
        return 'Day $day: No specific workout details provided.';
      }
    } else {
      return 'No information available for Day $day';
    }
  }

  Future<void> _generateWorkoutPlan() async {
    setState(() {
      _isGeneratingWorkoutPlan = true;
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
          _isGeneratingWorkoutPlan = false;
        });
        return;
      }

      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

      // Prepare user info for the API request
      List<String> userInfo = [
        "Activity Level - ${userData['activity_level'] ?? 'N/A'}",
        "Age - ${userData['age'] ?? 'N/A'}",
        "Gender - ${userData['gender'] ?? 'N/A'}",
        "Goal - ${userData['goal'] ?? 'N/A'}",
        "Workout Time - ${userData['workout_time_weekly'] ?? 'N/A'}",
      ];

      // Make API request with detailed logging
      print('Making API request to generate workout plan...');
      var response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}generate-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'variant': 'workout',
          'userInfo': userInfo,
          'pastExperiences': userData['lastWeekExperience'] ?? '',
        }),
      );

      print('API response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Successfully generated plan
        try {
          // Parse the JSON response
          Map<String, dynamic> workoutPlanResponse = jsonDecode(response.body);
          print('Successfully parsed API response to JSON');

          // Log the structure
          print('Workout plan keys: ${workoutPlanResponse.keys.join(', ')}');

          // Check if we have the expected structure (day1, day2, etc.)
          if (workoutPlanResponse.containsKey('day1')) {
            // Save the data directly to maintain the structure
            Map<String, dynamic> firestoreData = {
              'createdAt': FieldValue.serverTimestamp(),
            };

            // Add each day's plan to the data
            for (String key in workoutPlanResponse.keys) {
              firestoreData[key] = workoutPlanResponse[key];
            }

            print(
              'Prepared workout plan data for Firestore: ${firestoreData.keys.join(', ')}',
            );

            // Store in Firestore
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('plans')
                .doc('workout')
                .set(firestoreData);

            print('Successfully stored workout plan in Firestore');

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Workout plan generated successfully!')),
            );

            // Refresh the workout plan display
            _fetchWorkoutPlan();
          } else {
            print('Unexpected workout plan structure. Missing day entries.');
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
              content: Text(
                'Failed to process workout plan. Error: $parseError',
              ),
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
              'Failed to generate workout plan. Status: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error generating workout plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred: ${e.toString().substring(0, min(50, e.toString().length))}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isGeneratingWorkoutPlan = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Workout Plan')),
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

            // Display selected workout information below buttons
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
                          child: Markdown(
                            data: getWorkoutInfo(_selectedDay),
                            selectable: true,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            styleSheet: MarkdownStyleSheet(
                              h1: theme.textTheme.headlineMedium,
                              h2: TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed:
                      _isGeneratingWorkoutPlan ? null : _generateWorkoutPlan,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: theme.hintColor.withOpacity(0.7),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isGeneratingWorkoutPlan
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
                              Text('Generating workout plan...'),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fitness_center),
                              SizedBox(width: 8),
                              Text('Generate Personalized Workout'),
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
