import 'package:hk11/pages/login_page/view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hk11/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  Map<String, dynamic>? userData;

  // Form controllers
  final TextEditingController _currentWeightController =
      TextEditingController();
  final TextEditingController _desiredWeightController =
      TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _workoutTimeController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  // Form values
  String _selectedGoal = 'Lose Weight';
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  String _selectedGender = 'Male';
  String _selectedActivityLevel = 'Lightly Active';
  Map<String, bool> _dietaryPreferences = {
    'vegetarian': false,
    'vegan': false,
    'glutenFree': false,
    'keto': false,
    'none': true,
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _currentWeightController.dispose();
    _desiredWeightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _workoutTimeController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>;
          _populateFormFields();
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile data'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormFields() {
    if (userData != null) {
      _currentWeightController.text =
          userData!['current_weight']?.toString() ?? '';
      _desiredWeightController.text =
          userData!['desired_weight']?.toString() ?? '';
      _heightController.text = userData!['height']?.toString() ?? '';
      _ageController.text = userData!['age']?.toString() ?? '';
      _workoutTimeController.text =
          userData!['workout_time_weekly']?.toString() ?? '';
      _budgetController.text = userData!['monthly_budget']?.toString() ?? '';

      _selectedGoal = userData!['goal'] ?? 'Lose Weight';
      _selectedWeightUnit = userData!['weight_unit'] ?? 'kg';
      _selectedHeightUnit = userData!['height_unit'] ?? 'cm';
      _selectedGender = userData!['gender'] ?? 'Male';
      _selectedActivityLevel = userData!['activity_level'] ?? 'Lightly Active';

      if (userData!['dietary_preferences'] != null) {
        // Clear default values
        _dietaryPreferences.forEach((key, value) {
          _dietaryPreferences[key] = false;
        });

        // Copy from userData
        Map<String, dynamic> prefs = userData!['dietary_preferences'];
        prefs.forEach((key, value) {
          _dietaryPreferences[key] = value;
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    setState(() {
      _isSaving = true;
    });

    try {
      String userId = _auth.currentUser?.uid ?? 'anonymous_user';

      Map<String, dynamic> updatedData = {
        'goal': _selectedGoal,
        'current_weight': int.tryParse(_currentWeightController.text) ?? 0,
        'desired_weight': int.tryParse(_desiredWeightController.text) ?? 0,
        'weight_unit': _selectedWeightUnit,
        'height': int.tryParse(_heightController.text) ?? 0,
        'height_unit': _selectedHeightUnit,
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _selectedGender,
        'activity_level': _selectedActivityLevel,
        'workout_time_weekly': int.tryParse(_workoutTimeController.text) ?? 0,
        'dietary_preferences': _dietaryPreferences,
        'monthly_budget': int.tryParse(_budgetController.text) ?? 0,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isEditing = false;
        userData = {...userData!, ...updatedData};
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.dividerColor,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 24),

                      // User name
                      Text(
                        user?.displayName ?? 'User',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 16),

                      // Email
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.email,
                                color: theme.listTileTheme.iconColor,
                              ),
                              title: Text(
                                'Email',
                                style: theme.textTheme.bodyMedium,
                              ),
                              subtitle: Text(
                                user?.email ?? 'Not provided',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Profile data section
                      Container(
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Fitness Profile',
                                    style: theme.textTheme.headlineLarge,
                                  ),
                                  if (!_isEditing)
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = true;
                                        });
                                      },
                                      icon: Icon(Icons.edit),
                                      label: Text('Edit'),
                                    ),
                                ],
                              ),
                            ),
                            Divider(height: 1),

                            // Either display editable form or read-only info
                            _isEditing ? _buildEditForm() : _buildProfileInfo(),

                            // Edit/Save buttons
                            if (_isEditing)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed:
                                            _isSaving
                                                ? null
                                                : () {
                                                  setState(() {
                                                    _isEditing = false;
                                                    _populateFormFields();
                                                  });
                                                },
                                        child: Text('Cancel'),
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed:
                                            _isSaving ? null : _saveUserData,
                                        child:
                                            _isSaving
                                                ? SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : Text('Save'),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Sign out button
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginOrSignupPage(),
                            ),
                          );
                        },
                        style: theme.elevatedButtonTheme.style,
                        child: Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildProfileInfo() {
    final theme = Theme.of(context);

    if (userData == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No profile data available. Please complete onboarding.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem('Goal', userData!['goal'] ?? 'Not specified'),
          _buildInfoItem(
            'Current Weight',
            '${userData!['current_weight'] ?? '--'} ${userData!['weight_unit'] ?? 'kg'}',
          ),
          _buildInfoItem(
            'Target Weight',
            '${userData!['desired_weight'] ?? '--'} ${userData!['weight_unit'] ?? 'kg'}',
          ),
          _buildInfoItem(
            'Height',
            '${userData!['height'] ?? '--'} ${userData!['height_unit'] ?? 'cm'}',
          ),
          _buildInfoItem('Age', '${userData!['age'] ?? '--'} years'),
          _buildInfoItem('Gender', userData!['gender'] ?? 'Not specified'),
          _buildInfoItem(
            'Activity Level',
            userData!['activity_level'] ?? 'Not specified',
          ),
          _buildInfoItem(
            'Weekly Workout Time',
            '${userData!['workout_time_weekly'] ?? '--'} hours',
          ),
          _buildInfoItem(
            'Monthly Budget',
            '\$${userData!['monthly_budget'] ?? '--'}',
          ),

          SizedBox(height: 8),
          Text(
            'Dietary Preferences:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          if (userData!['dietary_preferences'] != null)
            ...(_getDietaryPreferencesText()),
        ],
      ),
    );
  }

  List<Widget> _getDietaryPreferencesText() {
    final theme = Theme.of(context);
    List<Widget> preferences = [];

    Map<String, dynamic> prefs = userData!['dietary_preferences'];

    if (prefs['none'] == true) {
      preferences.add(
        Text('• No dietary restrictions', style: theme.textTheme.bodySmall),
      );
    } else {
      if (prefs['vegetarian'] == true)
        preferences.add(Text('• Vegetarian', style: theme.textTheme.bodySmall));

      if (prefs['vegan'] == true)
        preferences.add(Text('• Vegan', style: theme.textTheme.bodySmall));

      if (prefs['glutenFree'] == true)
        preferences.add(
          Text('• Gluten-Free', style: theme.textTheme.bodySmall),
        );

      if (prefs['keto'] == true)
        preferences.add(Text('• Keto', style: theme.textTheme.bodySmall));
    }

    if (preferences.isEmpty) {
      preferences.add(Text('Not specified', style: theme.textTheme.bodySmall));
    }

    return preferences;
  }

  Widget _buildInfoItem(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label + ':',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    final theme = Theme.of(context);

    // Updated dropdown decoration to better match theme colors
    final dropdownDecoration = InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      filled: true,
      fillColor:
          theme
              .scaffoldBackgroundColor, // Ensure this matches the page background
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.primaryColor),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal dropdown
          Text(
            'Goal',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButtonFormField<String>(
            value: _selectedGoal,
            decoration: dropdownDecoration,
            dropdownColor: theme.scaffoldBackgroundColor,
            icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            items:
                [
                      'Lose Weight',
                      'Get Lean & Toned',
                      'Build Muscle',
                      'Be More Active',
                    ]
                    .map(
                      (goal) =>
                          DropdownMenuItem(value: goal, child: Text(goal)),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedGoal = value;
                });
              }
            },
          ),
          SizedBox(height: 16),

          // Current Weight
          Text(
            'Current Weight',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _currentWeightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: '50-300'),
                ),
              ),
              SizedBox(width: 8),
              _buildUnitSelector(_selectedWeightUnit, ['kg', 'lbs'], (value) {
                setState(() {
                  _selectedWeightUnit = value!;
                });
              }),
            ],
          ),
          SizedBox(height: 16),

          // Desired Weight
          Text(
            'Desired Weight',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _desiredWeightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: '50-300'),
                ),
              ),
              SizedBox(width: 8),
              _buildUnitSelector(_selectedWeightUnit, ['kg', 'lbs'], (value) {
                setState(() {
                  _selectedWeightUnit = value!;
                });
              }),
            ],
          ),
          SizedBox(height: 16),

          // Height
          Text(
            'Height',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: '100-250'),
                ),
              ),
              SizedBox(width: 8),
              _buildUnitSelector(_selectedHeightUnit, ['cm', 'inches'], (
                value,
              ) {
                setState(() {
                  _selectedHeightUnit = value!;
                });
              }),
            ],
          ),
          SizedBox(height: 16),

          // Age
          Text(
            'Age',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '5-110'),
          ),
          SizedBox(height: 16),

          // Gender
          Text(
            'Gender',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: dropdownDecoration,
            dropdownColor: theme.scaffoldBackgroundColor,
            icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            items:
                ['Male', 'Female', 'Other']
                    .map(
                      (gender) =>
                          DropdownMenuItem(value: gender, child: Text(gender)),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedGender = value;
                });
              }
            },
          ),
          SizedBox(height: 16),

          // Activity Level
          Text(
            'Activity Level',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButtonFormField<String>(
            value: _selectedActivityLevel,
            decoration: dropdownDecoration,
            dropdownColor: theme.scaffoldBackgroundColor,
            icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            items:
                ['Lightly Active', 'Moderately Active', 'Highly Active']
                    .map(
                      (level) =>
                          DropdownMenuItem(value: level, child: Text(level)),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedActivityLevel = value;
                });
              }
            },
          ),
          SizedBox(height: 16),

          // Workout time
          Text(
            'Weekly Workout Time (hours)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextField(
            controller: _workoutTimeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '1-40'),
          ),
          SizedBox(height: 16),

          // Budget
          Text(
            'Monthly Fitness Budget (\$)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0-5000',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          SizedBox(height: 16),

          // Dietary Preferences
          Text(
            'Dietary Preferences',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          CheckboxListTile(
            title: Text(
              'No dietary restrictions',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            value: _dietaryPreferences['none'] ?? false,
            activeColor: theme.primaryColor,
            checkColor: theme.scaffoldBackgroundColor,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _dietaryPreferences.forEach(
                    (key, _) => _dietaryPreferences[key] = false,
                  );
                  _dietaryPreferences['none'] = true;
                } else {
                  _dietaryPreferences['none'] = false;
                }
              });
            },
          ),
          CheckboxListTile(
            title: Text(
              'Vegetarian',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            value: _dietaryPreferences['vegetarian'] ?? false,
            activeColor: theme.primaryColor,
            checkColor: theme.scaffoldBackgroundColor,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _dietaryPreferences['none'] = false;
                  _dietaryPreferences['vegan'] = false;
                }
                _dietaryPreferences['vegetarian'] = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: Text(
              'Vegan',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            value: _dietaryPreferences['vegan'] ?? false,
            activeColor: theme.primaryColor,
            checkColor: theme.scaffoldBackgroundColor,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _dietaryPreferences['none'] = false;
                  _dietaryPreferences['vegetarian'] = false;
                }
                _dietaryPreferences['vegan'] = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: Text(
              'Gluten-Free',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            value: _dietaryPreferences['glutenFree'] ?? false,
            activeColor: theme.primaryColor,
            checkColor: theme.scaffoldBackgroundColor,
            onChanged: (value) {
              setState(() {
                if (value == true) _dietaryPreferences['none'] = false;
                _dietaryPreferences['glutenFree'] = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: Text(
              'Keto',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            value: _dietaryPreferences['keto'] ?? false,
            activeColor: theme.primaryColor,
            checkColor: theme.scaffoldBackgroundColor,
            onChanged: (value) {
              setState(() {
                if (value == true) _dietaryPreferences['none'] = false;
                _dietaryPreferences['keto'] = value ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector(
    String currentValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        // Make this match the surrounding theme more consistently
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DropdownButton<String>(
        value: currentValue,
        icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
        underline: Container(height: 0),
        elevation: 0,
        borderRadius: BorderRadius.circular(8),
        dropdownColor: theme.scaffoldBackgroundColor,
        isDense: true,
        // Ensure the text color matches the theme text color
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        items:
            options.map((unit) {
              return DropdownMenuItem<String>(
                value: unit,
                child: Text(
                  unit,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
