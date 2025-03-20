import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hk11/pages/profile_page.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // Add current step tracking
  int _currentStep = 0;
  final int _totalSteps = 9; // Increased from 8 to 9 steps

  // Changed late variables to nullable types with default values to prevent null issues
  String selectedGoal = 'Lose Weight'; // Initialize with a default value
  String selectedUnitWeight = 'kg';
  String selectedUnitHeight = 'cm';
  String selectedGender = 'Male'; // Initialize with a default value
  String selectedActivityLevel =
      'Lightly Active'; // Initialize with a default value
  int? currentWeight;
  int? desiredWeight;
  int? height;
  int? age;
  int? workoutTime;
  // Changed from String to Map to support multiple selections
  Map<String, bool> dietaryPreferences = {
    'vegetarian': false,
    'vegan': false,
    'glutenFree': false,
    'keto': false,
    'none': true, // Default to "No restrictions"
  };
  int? monthlyBudget; // Added new variable for financial input

  // Add Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSaving = false; // Track when we're saving data

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        return selectedGoal.isNotEmpty;
      case 1:
        return currentWeight != null && desiredWeight != null;
      case 2:
        return height != null;
      case 3:
        return age != null;
      case 4:
        return selectedGender.isNotEmpty;
      case 5:
        return selectedActivityLevel.isNotEmpty;
      case 6:
        return workoutTime != null;
      case 7:
        // Check if at least one dietary preference is selected
        return dietaryPreferences.values.contains(true);
      case 8:
        return monthlyBudget != null; // Validation for new financial step
      default:
        return false;
    }
  }

  // Get appropriate error message for the current step
  String _getErrorMessageForStep(int step) {
    switch (step) {
      case 0:
        return '* Please select a goal';
      case 1:
        if (currentWeight == null && desiredWeight == null)
          return '* Please enter both your current and desired weight';
        else if (currentWeight == null)
          return '* Please enter your current weight';
        else
          return '* Please enter your desired weight';
      case 2:
        return '* Please enter your height';
      case 3:
        return '* Please enter your age';
      case 4:
        return '* Please select your gender';
      case 5:
        return '* Please select your activity level';
      case 6:
        return '* Please enter your available workout time';
      case 7:
        return '* Please enter your dietary preferences';
      case 8:
        return '* Please enter your monthly fitness budget';
      default:
        return '* Please complete this step';
    }
  }

  // Show error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Add method to save data to Firebase
  Future<void> _saveUserDataToFirebase() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Get current user ID or create an anonymous one if not logged in
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';

      // Create user data map
      Map<String, dynamic> userData = {
        'goal': selectedGoal,
        'current_weight': currentWeight,
        'desired_weight': desiredWeight,
        'weight_unit': selectedUnitWeight,
        'height': height,
        'height_unit': selectedUnitHeight,
        'age': age,
        'gender': selectedGender,
        'activity_level': selectedActivityLevel,
        'workout_time_weekly': workoutTime,
        'dietary_preferences': dietaryPreferences, // Now saving as a Map
        'monthly_budget': monthlyBudget, // Added financial data
        'created_at': FieldValue.serverTimestamp(),
        'onboardingComplete':
            true, // Add this field to mark onboarding as complete
      };

      // Save to Firestore
      await _firestore.collection('users').doc(userId).set(userData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to the next page or home
      // You should replace this with your actual navigation logic
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Validation methods
  int? validateAge(String value) {
    if (value.isEmpty) return null;

    final parsedValue = int.tryParse(value);
    if (parsedValue == null) return null;

    // Age must be between 5 and 110
    if (parsedValue < 5 || parsedValue > 110) return null;

    return parsedValue;
  }

  int? validateWeight(String value) {
    if (value.isEmpty) return null;

    final parsedValue = int.tryParse(value);
    if (parsedValue == null) return null;

    // Weight must be between 20 and 300 kg or 44 and 660 lbs
    final minWeight = selectedUnitWeight == 'kg' ? 20 : 44;
    final maxWeight = selectedUnitWeight == 'kg' ? 300 : 660;

    if (parsedValue < minWeight || parsedValue > maxWeight) return null;

    return parsedValue;
  }

  int? validateHeight(String value) {
    if (value.isEmpty) return null;

    final parsedValue = int.tryParse(value);
    if (parsedValue == null) return null;

    // Height must be between 50 and 250 cm or 20 and 98 inches
    final minHeight = selectedUnitHeight == 'cm' ? 50 : 20;
    final maxHeight = selectedUnitHeight == 'cm' ? 250 : 98;

    if (parsedValue < minHeight || parsedValue > maxHeight) return null;

    return parsedValue;
  }

  int? validateWorkoutTime(String value) {
    if (value.isEmpty) return null;

    final parsedValue = int.tryParse(value);
    if (parsedValue == null) return null;

    // Workout time must be between 1 and 40 hours per week
    if (parsedValue < 1 || parsedValue > 40) return null;

    return parsedValue;
  }

  int? validateBudget(String value) {
    if (value.isEmpty) return null;

    final parsedValue = int.tryParse(value);
    if (parsedValue == null) return null;

    // Budget must be between 0 and 5000
    if (parsedValue < 0 || parsedValue > 5000) return null;

    return parsedValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              minHeight: 10,
            ),
            SizedBox(height: 10),
            // Step indicator text
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 20),

            // Current step content
            Expanded(child: SingleChildScrollView(child: _buildCurrentStep())),

            // Fixed navigation buttons - wrap in a container with fixed size constraints
            Container(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment:
                      _currentStep > 0
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                  children: [
                    if (_currentStep > 0)
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentStep--;
                            });
                          },
                          child: Text('Back'),
                        ),
                      ),
                    SizedBox(
                      width: 110,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isCurrentStepValid()) {
                            if (_currentStep < _totalSteps - 1) {
                              setState(() {
                                _currentStep++;
                              });
                            } else {
                              // Handle form submission - save to Firebase
                              _saveUserDataToFirebase();
                            }
                          } else {
                            // Show error message with star (*) indicator
                            _showErrorSnackbar(
                              _getErrorMessageForStep(_currentStep),
                            );
                          }
                        },
                        child:
                            _isSaving
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: theme.primaryColorLight,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  _currentStep < _totalSteps - 1
                                      ? 'Next'
                                      : 'Submit',
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to return the current step widget
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildGoalSelection();
      case 1:
        return _buildWeightInput();
      case 2:
        return _buildHeightInput();
      case 3:
        return _buildAgeInput();
      case 4:
        return _buildGenderSelection();
      case 5:
        return _buildActivityLevelSelection();
      case 6:
        return _buildWorkoutTimeInput();
      case 7:
        return _buildDietaryPreferencesInput();
      case 8:
        return _buildFinancialInput(); // Added new case for financial step
      default:
        return Container(); // Should never reach here
    }
  }

  Widget _buildGoalSelection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Goal',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildGoalOption(
          'Lose Weight',
          'I want to shed some extra kilos and focus on fat loss.',
          Icons.fitness_center,
        ),
        _buildGoalOption(
          'Get Lean & Toned',
          'I want to define my muscles and improve overall body composition.',
          Icons.accessibility_new,
        ),
        _buildGoalOption(
          'Build Muscle',
          'I want to gain strength and increase muscle mass.',
          Icons.fitness_center,
        ),
        _buildGoalOption(
          'Be More Active',
          'I want to move more, feel better, and improve my overall fitness.',
          Icons.directions_walk,
        ),
      ],
    );
  }

  Widget _buildGoalOption(String title, String description, IconData icon) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.listTileTheme.iconColor),
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(description, style: theme.textTheme.bodySmall),
      trailing: Radio<String>(
        value: title,
        groupValue: selectedGoal,
        activeColor: theme.primaryColor,
        onChanged: (value) {
          setState(() {
            selectedGoal = value!; // Non-nullable since value won't be null
          });
        },
      ),
    );
  }

  Widget _buildWeightInput() {
    final theme = Theme.of(context);

    // Define min/max values based on unit
    final minWeight = selectedUnitWeight == 'kg' ? 20 : 44;
    final maxWeight = selectedUnitWeight == 'kg' ? 300 : 660;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Weight',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            // Use fraction of screen width instead of Expanded
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.65,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Weight',
                  hintText: '$minWeight-$maxWeight',
                  hintStyle: TextStyle(
                    color: theme.hintColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    currentWeight = validateWeight(value);
                  });
                },
              ),
            ),
            SizedBox(width: 10),
            // Improved container for dropdown
            Container(
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                // Eliminate any border
                border: Border.all(color: Colors.transparent),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildUnitToggle(['kg', 'lbs'], selectedUnitWeight, (
                value,
              ) {
                setState(() {
                  selectedUnitWeight = value!;
                  if (currentWeight != null) {
                    final currentValue = currentWeight.toString();
                    currentWeight = validateWeight(currentValue);
                  }
                  if (desiredWeight != null) {
                    final desiredValue = desiredWeight.toString();
                    desiredWeight = validateWeight(desiredValue);
                  }
                });
              }),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Desired Weight',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.65,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Desired Weight',
                  hintText: '$minWeight-$maxWeight',
                  hintStyle: TextStyle(
                    color: theme.hintColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    desiredWeight = validateWeight(value);
                  });
                },
              ),
            ),
            SizedBox(width: 10),
            // Use the same improved container style
            Container(
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                // Eliminate any border
                border: Border.all(color: Colors.transparent),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildUnitToggle(['kg', 'lbs'], selectedUnitWeight, (
                value,
              ) {
                setState(() {
                  selectedUnitWeight = value!;
                });
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeightInput() {
    final theme = Theme.of(context);

    // Define min/max values based on unit
    final minHeight = selectedUnitHeight == 'cm' ? 50 : 20;
    final maxHeight = selectedUnitHeight == 'cm' ? 250 : 98;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Height',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.65,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Height',
                  hintText: '$minHeight-$maxHeight',
                  hintStyle: TextStyle(
                    color: theme.hintColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    height = validateHeight(value);
                  });
                },
              ),
            ),
            SizedBox(width: 10),
            // Apply the same container style here too
            Container(
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                // Eliminate any border
                border: Border.all(color: Colors.transparent),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildUnitToggle(['cm', 'inches'], selectedUnitHeight, (
                value,
              ) {
                setState(() {
                  selectedUnitHeight = value!;
                  if (height != null) {
                    final heightValue = height.toString();
                    height = validateHeight(heightValue);
                  }
                });
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeInput() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Age',
            hintText: 'Range: 5-110',
            errorText:
                age == null
                    ? null
                    : (age! < 5 || age! > 110 ? 'Age must be 5-110' : null),
          ),
          onChanged: (value) {
            setState(() {
              age = validateAge(value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        ListTile(
          leading: Icon(Icons.male, color: Colors.blue),
          title: Text('Male', style: theme.textTheme.bodyMedium),
          trailing: Radio<String>(
            value: 'Male',
            groupValue: selectedGender,
            activeColor: theme.primaryColor,
            onChanged: (value) {
              setState(() {
                selectedGender =
                    value!; // Non-nullable since value won't be null
              });
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.female, color: Colors.pink),
          title: Text('Female', style: theme.textTheme.bodyMedium),
          trailing: Radio<String>(
            value: 'Female',
            groupValue: selectedGender,
            activeColor: theme.primaryColor,
            onChanged: (value) {
              setState(() {
                selectedGender =
                    value!; // Non-nullable since value won't be null
              });
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.transgender, color: theme.colorScheme.secondary),
          title: Text('Other', style: theme.textTheme.bodyMedium),
          trailing: Radio<String>(
            value: 'Other',
            groupValue: selectedGender,
            activeColor: theme.primaryColor,
            onChanged: (value) {
              setState(() {
                selectedGender =
                    value!; // Non-nullable since value won't be null
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLevelSelection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Level',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildActivityLevelOption(
          'Lightly Active',
          'I move when needed—occasional walks, errands, but nothing too demanding.',
          Icons.directions_walk,
        ),
        _buildActivityLevelOption(
          'Moderately Active',
          'I stay on my feet often—regular walks, light workouts, or an active job.',
          Icons.directions_run,
        ),
        _buildActivityLevelOption(
          'Highly Active',
          'I train hard—frequent workouts, intense sports, or physically demanding work.',
          Icons.fitness_center,
        ),
      ],
    );
  }

  Widget _buildActivityLevelOption(
    String title,
    String description,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.listTileTheme.iconColor),
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(description, style: theme.textTheme.bodySmall),
      trailing: Radio<String>(
        value: title,
        groupValue: selectedActivityLevel,
        activeColor: theme.primaryColor,
        onChanged: (value) {
          setState(() {
            selectedActivityLevel =
                value!; // Non-nullable since value won't be null
          });
        },
      ),
    );
  }

  Widget _buildWorkoutTimeInput() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Workout Time per Week',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Hours per Week',
            hintText: '1-40 hours',
            hintStyle: TextStyle(
              color: theme.hintColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          onChanged: (value) {
            setState(() {
              workoutTime = validateWorkoutTime(value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildDietaryPreferencesInput() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dietary Preferences',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Select any dietary restrictions that apply to you:',
          style: theme.textTheme.bodySmall,
        ),
        SizedBox(height: 20),

        // No dietary restrictions option
        CheckboxListTile(
          title: Text(
            'No dietary restrictions',
            style: theme.textTheme.bodyMedium,
          ),
          value: dietaryPreferences['none'] ?? false,
          activeColor: theme.primaryColor,
          onChanged: (bool? value) {
            setState(() {
              // If selecting "none", unselect all other options
              if (value == true) {
                dietaryPreferences.forEach((key, _) {
                  dietaryPreferences[key] = false;
                });
                dietaryPreferences['none'] = true;
              } else {
                dietaryPreferences['none'] = false;
              }
            });
          },
          secondary: Icon(
            Icons.remove_circle_outline,
            color: theme.listTileTheme.iconColor,
          ),
        ),

        // Vegetarian option - Restored original color
        CheckboxListTile(
          title: Text('Vegetarian', style: theme.textTheme.bodyMedium),
          subtitle: Text(
            'No meat, but may include dairy and eggs',
            style: theme.textTheme.bodySmall,
          ),
          value: dietaryPreferences['vegetarian'] ?? false,
          activeColor: theme.primaryColor,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                // If selecting vegetarian, unselect "none"
                dietaryPreferences['none'] = false;

                // If selecting vegetarian, unselect vegan (mutual exclusivity)
                dietaryPreferences['vegan'] = false;
                dietaryPreferences['vegetarian'] = true;
              } else {
                dietaryPreferences['vegetarian'] = false;
              }
            });
          },
          secondary: Icon(
            Icons.spa,
            color: Colors.green,
          ), // Restored original color
        ),

        // Vegan option - Restored original color
        CheckboxListTile(
          title: Text('Vegan', style: theme.textTheme.bodyMedium),
          subtitle: Text(
            'No animal products including meat, dairy, eggs, and honey',
            style: theme.textTheme.bodySmall,
          ),
          value: dietaryPreferences['vegan'] ?? false,
          activeColor: theme.primaryColor,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                // If selecting vegan, unselect "none"
                dietaryPreferences['none'] = false;

                // If selecting vegan, unselect vegetarian (mutual exclusivity)
                dietaryPreferences['vegetarian'] = false;
                dietaryPreferences['vegan'] = true;
              } else {
                dietaryPreferences['vegan'] = false;
              }
            });
          },
          secondary: Icon(
            Icons.eco,
            color: Colors.green[700],
          ), // Restored original color
        ),

        // Gluten-free option - Restored original color
        CheckboxListTile(
          title: Text('Gluten-Free', style: theme.textTheme.bodyMedium),
          subtitle: Text(
            'No wheat, barley, rye, or their derivatives',
            style: theme.textTheme.bodySmall,
          ),
          value: dietaryPreferences['glutenFree'] ?? false,
          activeColor: theme.primaryColor,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                // If selecting any option, unselect "none"
                dietaryPreferences['none'] = false;
              }
              dietaryPreferences['glutenFree'] = value ?? false;
            });
          },
          secondary: Icon(
            Icons.grain_outlined,
            color: Colors.amber,
          ), // Restored original color
        ),

        // Keto option - Restored original color
        CheckboxListTile(
          title: Text('Keto', style: theme.textTheme.bodyMedium),
          subtitle: Text(
            'Low carb, high fat diet',
            style: theme.textTheme.bodySmall,
          ),
          value: dietaryPreferences['keto'] ?? false,
          activeColor: theme.primaryColor,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                // If selecting any option, unselect "none"
                dietaryPreferences['none'] = false;
              }
              dietaryPreferences['keto'] = value ?? false;
            });
          },
          secondary: Icon(
            Icons.local_dining,
            color: Colors.red,
          ), // Restored original color
        ),
      ],
    );
  }

  Widget _buildFinancialInput() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Availability',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'How much are you willing to spend monthly on fitness-related expenses like gym memberships, classes, or equipment?',
          style: theme.textTheme.bodySmall,
        ),
        SizedBox(height: 20),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Monthly Budget (\$)',
            hintText: '\$0-\$5000',
            hintStyle: TextStyle(
              color: theme.hintColor.withOpacity(0.6),
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.attach_money),
          ),
          onChanged: (value) {
            setState(() {
              monthlyBudget = validateBudget(value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildUnitToggle(
    List<String> units,
    String selectedUnit,
    ValueChanged<String?> onChanged,
  ) {
    final theme = Theme.of(context);

    return DropdownButton<String>(
      value: selectedUnit,
      icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
      underline: Container(height: 0), // Remove the default underline
      elevation: 0, // Remove shadow
      borderRadius: BorderRadius.circular(8),
      dropdownColor: theme.scaffoldBackgroundColor,
      isDense: true, // Makes the dropdown more compact
      style: TextStyle(
        color: theme.textTheme.bodyMedium?.color ?? theme.primaryColor,
        fontWeight: FontWeight.w500,
      ),
      items:
          units.map((unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 16,
                  // Use the exact same color as the text theme to ensure consistency
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            );
          }).toList(),
      onChanged: onChanged,
    );
  }
}
