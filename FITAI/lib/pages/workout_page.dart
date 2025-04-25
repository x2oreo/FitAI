import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hk11/theme/theme_provider.dart';
import 'package:hk11/utils/calendar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math';
import '../config/api_config.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _selectedDay = 1; // Default to day 1 instead of 0
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CalendarClient calendarClient = CalendarClient();

  // Workout information for each day
  Map<String, dynamic> _workoutPlan = {};
  bool _isLoading = true;
  bool _isGeneratingWorkoutPlan = false;
  bool _isGeneratingGoogleCalendar = false;
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
      List<String> userInfoList = [
        "Activity Level - ${userData['activity_level'] ?? 'N/A'}",
        "Age - ${userData['age'] ?? 'N/A'}",
        "Gender - ${userData['gender'] ?? 'N/A'}",
        "Goal - ${userData['goal'] ?? 'N/A'}",
        "Workout Time - ${userData['workout_time_weekly'] ?? 'N/A'}",
      ];
      
      // Fetch recent journal entries (last 7 days)
      try {
        print('Fetching recent journal entries...');
        final now = DateTime.now();
        final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
        
        final journalSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('journal_entries')
            .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(sevenDaysAgo))
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
      print('Making API request to generate workout plan...');
      var response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/generatePlanV2'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'variant': 'workout',
          'userInfo': userInfo,
          'pastExperiences': "the user has no past experiences",
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

          // Extract the workout plan from the nested "plan" object
          if (workoutPlanResponse.containsKey('plan') &&
              workoutPlanResponse['plan'] is Map<String, dynamic>) {
            Map<String, dynamic> plan =
                workoutPlanResponse['plan'] as Map<String, dynamic>;

            // Check if we have the expected structure (day1, day2, etc.)
            if (plan.containsKey('day1')) {
              // Save the data directly to maintain the structure
              Map<String, dynamic> firestoreData = {
                'createdAt': FieldValue.serverTimestamp(),
              };

              // Add each day's plan to the data
              for (String key in plan.keys) {
                firestoreData[key] = plan[key];
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
          } else {
            print('Workout plan does not contain a valid "plan" object.');
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

  Future<void> _generateGoogleCalendar() async {
    setState(() {
      _isGeneratingGoogleCalendar = true;
    });

    for (int i = 1; i <= 7; i++) {
      await calendarClient.insert(
        title: 'Workout - Day $i',
        description: 'Workout planned by FitAI',
        location: '',
        attendeeEmailList: [],
        shouldNotifyAttendees: false,
        startTime: DateTime.now().add(Duration(days: i)),
        endTime: DateTime.now().add(Duration(days: i, hours: 1)),
      );
    }
    setState(() {
      _isGeneratingGoogleCalendar = false;
    });
  }

  // Get workout info for the selected day
  String getWorkoutInfo(int day) {
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
        title: const Text('Weekly Workout Plan'),
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

              // Display selected workout information
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
                                  'Loading your workout plan...',
                                  style: theme.textTheme.titleLarge,
                                  
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
                                  Icons.fitness_center,
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
                                  'Use the button below to create a new workout plan',
                                  style: theme.textTheme.bodyLarge,
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
                                    'Workout Plan',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.secondary,
                                          
                                    ),
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
                                      data: getWorkoutInfo(_selectedDay),
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

              if (!_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: ElevatedButton(
                    onPressed:
                        _isGeneratingWorkoutPlan ? null : _generateWorkoutPlan,

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
                                Text(
                                  'Generating workout plan...',
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
                                  Icons.fitness_center,
                                  size: 22,
                                  color: theme.colorScheme.secondary,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Generate Personalized Workout',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),

              if (!_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 18.0),
                  child: ElevatedButton(
                    onPressed:
                        _isGeneratingWorkoutPlan
                            ? null
                            : _generateGoogleCalendar,

                    child:
                        _isGeneratingGoogleCalendar
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
                                  'Filling calendar...',
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
                                  Icons.calendar_month,
                                  size: 22,
                                  color: theme.colorScheme.secondary,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Fill Google Calendar',
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
