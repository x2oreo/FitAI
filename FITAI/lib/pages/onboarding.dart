import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // Add current step tracking
  int _currentStep = 0;
  final int _totalSteps = 8;

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
  String? dietaryPreferences;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 10,
            ),
            SizedBox(height: 10),
            // Step indicator text
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),

            // Current step content
            Expanded(
              child: SingleChildScrollView(
                child: _buildCurrentStep(),
              ),
            ),

            // Fixed navigation buttons - wrap in a container with fixed size constraints
            Container(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: _currentStep > 0
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
                      width: 100,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentStep < _totalSteps - 1) {
                            setState(() {
                              _currentStep++;
                            });
                          } else {
                            // Handle form submission
                            print('Onboarding completed');
                          }
                        },
                        child: Text(
                            _currentStep < _totalSteps - 1 ? 'Next' : 'Submit'),
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
      default:
        return Container(); // Should never reach here
    }
  }

  Widget _buildGoalSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Goal',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: Radio<String>(
        value: title,
        groupValue: selectedGoal,
        onChanged: (value) {
          setState(() {
            selectedGoal = value!; // Non-nullable since value won't be null
          });
        },
      ),
    );
  }

  Widget _buildWeightInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Weight',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Current Weight'),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    currentWeight = int.tryParse(value);
                  }
                },
              ),
            ),
            _buildUnitToggle(['kg', 'lbs'], selectedUnitWeight, (value) {
              setState(() {
                selectedUnitWeight = value!;
              });
            }),
          ],
        ),
        Text(
          'Desired Weight',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Desired Weight'),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    desiredWeight = int.tryParse(value);
                  }
                },
              ),
            ),
            _buildUnitToggle(['kg', 'lbs'], selectedUnitWeight, (value) {
              setState(() {
                selectedUnitWeight = value!;
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildHeightInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Height',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Height'),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    height = int.tryParse(value);
                  }
                },
              ),
            ),
            _buildUnitToggle(['cm', 'inches'], selectedUnitHeight, (value) {
              setState(() {
                selectedUnitHeight = value!;
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Age'),
          onChanged: (value) {
            if (value.isNotEmpty) {
              age = int.tryParse(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ListTile(
          leading: Icon(Icons.male, color: Colors.blue),
          title: Text('Male'),
          trailing: Radio<String>(
            value: 'Male',
            groupValue: selectedGender,
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
          title: Text('Female'),
          trailing: Radio<String>(
            value: 'Female',
            groupValue: selectedGender,
            onChanged: (value) {
              setState(() {
                selectedGender =
                    value!; // Non-nullable since value won't be null
              });
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.transgender, color: Colors.grey),
          title: Text('Other'),
          trailing: Radio<String>(
            value: 'Other',
            groupValue: selectedGender,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Level',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: Radio<String>(
        value: title,
        groupValue: selectedActivityLevel,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Workout Time per Week',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Hours per Week'),
          onChanged: (value) {
            if (value.isNotEmpty) {
              workoutTime = int.tryParse(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDietaryPreferencesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dietary Preferences',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Dietary Preferences'),
          onChanged: (value) {
            dietaryPreferences = value;
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
    return DropdownButton<String>(
      value: selectedUnit,
      items: units.map((unit) {
        return DropdownMenuItem<String>(value: unit, child: Text(unit));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
