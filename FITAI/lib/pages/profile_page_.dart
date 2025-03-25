import 'package:hk11/pages/view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hk11/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
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

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Change Profile Picture',

                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(
                    'Choose from gallery',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(
                    'Take a photo',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _isUploadingImage = true;
        });
        
        // Get the file path from XFile
        String imagePath = pickedFile.path;
        
        // Update user profile with local path directly
        User? user = _auth.currentUser;
        if (user != null) {
          // Save the image path in Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'localImagePath': imagePath,
          });
          
          // Update local userData 
          setState(() {
            if (userData != null) {
              userData!['localImagePath'] = imagePath;
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Image selection error: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    var isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true, // Allows content to extend to the top
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [
                      Color.fromARGB(255, 0, 177, 0),    // Dark green
                      Color.fromARGB(255, 0, 171, 0),    // Dark green
                      Color.fromARGB(255, 0, 132, 0),    // Medium dark green
                      Color.fromARGB(255, 0, 42, 0),     // Black
                      Color.fromARGB(255, 0, 1, 0),     // Black
                      Color.fromARGB(255, 0, 0, 0),     // Black
                      Color.fromARGB(255, 0, 0, 0),     // Black
                      Color.fromARGB(255, 0, 0, 0),     // Black
                      Color.fromARGB(255, 0, 0, 0),     // Black
                      Color.fromARGB(255, 0, 0, 0),
                      Color.fromARGB(255, 0, 0, 0),
                      Color.fromARGB(255, 0, 0, 0), // Black 
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
                      Color(0xFFcacaca), // Light gray
                    ],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: theme.primaryColor),
                        SizedBox(height: 16),
                        Text(
                          'Loading your profile...',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16, 60, 16, 16), // Extra top padding for the theme button
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title text to replace AppBar title
                          
                          
                          // Rest of the content remains the same
                          // Profile picture with enhanced styling
                          Stack(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                                  // Use photoURL from Firestore, then from user account, then default icon
                                  backgroundImage: userData != null && userData!['localImagePath'] != null
                                    ? FileImage(File(userData!['localImagePath']))
                                    : (user?.photoURL != null 
                                      ? NetworkImage(user!.photoURL!) 
                                      : null),
                                  child: (userData == null || userData!['localImagePath'] == null) && user?.photoURL == null 
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: theme.primaryColor,
                                      ) 
                                    : null,
                                ),
                              ),
                              
                              // Change photo button overlay
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () => _showImageSourceActionSheet(),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: _isUploadingImage 
                                      ? SizedBox(
                                          height: 20, 
                                          width: 20, 
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ))
                                      : Icon(
                                          Icons.camera_alt,
                                          color: theme.colorScheme.primary,
                                          size: 20,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),

                          // User name with enhanced styling
                          Text(
                            user?.displayName ?? 'User',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 16),

                          // Email with enhanced card styling
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    Icons.email,
                                    color: theme.primaryColor,
                                  ),
                                  title: Text(
                                    'Email',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    user?.email ?? 'Not provided',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Profile data section with enhanced styling
                          Container(
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
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
                                        style: theme.textTheme.headlineLarge
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      if (!_isEditing)
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _isEditing = true;
                                            });
                                          },
                                          icon: Icon(
                                            Icons.edit,
                                            color: theme.primaryColor,
                                          ),
                                          label: Text(
                                            'Edit',
                                            style: TextStyle(
                                              color: theme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: theme.dividerColor,
                                ),

                                // Either display editable form or read-only info
                                _isEditing ? _buildEditForm() : _buildProfileInfo(),

                                // Edit/Save buttons with improved styling
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
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: theme.primaryColor,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed:
                                                _isSaving ? null : _saveUserData,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: theme.primaryColor,
                                              foregroundColor:
                                                  theme.colorScheme.onPrimary,
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                            ),
                                            child:
                                                _isSaving
                                                    ? SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                theme
                                                                    .colorScheme
                                                                    .onPrimary,
                                                          ),
                                                    )
                                                    : Text(
                                                      'Save',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
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

                          // Sign out button with improved styling
                          ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginOrSignupPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error.withOpacity(
                                0.1,
                              ),
                              foregroundColor: theme.colorScheme.error,
                              elevation: 0,
                              side: BorderSide(
                                color: theme.colorScheme.error.withOpacity(0.5),
                              ),
                            ),
                            icon: Icon(Icons.logout),
                            label: Text(
                              'Sign Out',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          // Theme toggle button positioned where the AppBar action would be
          Positioned(
            top: 40, // Adjust as needed
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.2),
              ),
              child: IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              ),
            ),
          ),
        ],
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
          // Enhanced profile info items with consistent spacing and dividers
          _buildInfoItem('Goal', userData!['goal'] ?? 'Not specified'),
          _buildDivider(),

          _buildInfoItem(
            'Current Weight',
            '${userData!['current_weight'] ?? '--'} ${userData!['weight_unit'] ?? 'kg'}',
          ),
          _buildDivider(),

          _buildInfoItem(
            'Target Weight',
            '${userData!['desired_weight'] ?? '--'} ${userData!['weight_unit'] ?? 'kg'}',
          ),
          _buildDivider(),

          _buildInfoItem(
            'Height',
            '${userData!['height'] ?? '--'} ${userData!['height_unit'] ?? 'cm'}',
          ),
          _buildDivider(),

          _buildInfoItem('Age', '${userData!['age'] ?? '--'} years'),
          _buildDivider(),

          _buildInfoItem('Gender', userData!['gender'] ?? 'Not specified'),
          _buildDivider(),

          _buildInfoItem(
            'Activity Level',
            userData!['activity_level'] ?? 'Not specified',
          ),
          _buildDivider(),

          _buildInfoItem(
            'Weekly Workout Time',
            '${userData!['workout_time_weekly'] ?? '--'} hours',
          ),
          _buildDivider(),

          _buildInfoItem(
            'Monthly Budget',
            '\$${userData!['monthly_budget'] ?? '--'}',
          ),
          _buildDivider(),

          SizedBox(height: 8),
          Text(
            'Dietary Preferences:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (userData!['dietary_preferences'] != null)
            ...(_getDietaryPreferencesText()),
        ],
      ),
    );
  }

  // Helper to create consistent dividers between info items
  Widget _buildDivider() {
    return Divider(
      height: 20,
      thickness: 1,
      indent: 10,
      endIndent: 10,
      color: Theme.of(context).dividerColor.withOpacity(0.3),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label + ':',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    final theme = Theme.of(context);

    // Enhanced dropdown decoration
    final dropdownDecoration = InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: theme.scaffoldBackgroundColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
    );

    // Enhanced text field decoration
    final textFieldDecoration = InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: theme.scaffoldBackgroundColor,
      hintStyle: TextStyle(
        color: theme.textTheme.bodySmall?.color,
        fontSize: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
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
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
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

          // Current Weight with improved UI
          Text(
            'Current Weight',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _currentWeightController,
                  keyboardType: TextInputType.number,
                  decoration: textFieldDecoration.copyWith(
                    hintText: '50-300',
                    labelText: 'Current Weight',
                  ),
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

          // Desired Weight with improved UI
          Text(
            'Desired Weight',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _desiredWeightController,
                  keyboardType: TextInputType.number,
                  decoration: textFieldDecoration.copyWith(
                    hintText: '50-300',
                    labelText: 'Desired Weight',
                  ),
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

          // Height with improved UI
          Text(
            'Height',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: textFieldDecoration.copyWith(
                    hintText: '100-250',
                    labelText: 'Height',
                  ),
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

          // Age with improved UI
          Text(
            'Age',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: textFieldDecoration.copyWith(
              hintText: '5-110',
              labelText: 'Age',
            ),
          ),

          SizedBox(height: 16),

          // Gender with improved UI
          Text(
            'Gender',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
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

          // Activity Level with improved UI
          Text(
            'Activity Level',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
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

          // Weekly Workout Time with improved UI
          Text(
            'Weekly Workout Time (hours)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _workoutTimeController,
            keyboardType: TextInputType.number,
            decoration: textFieldDecoration.copyWith(
              hintText: '1-40',
              labelText: 'Weekly Workout Time',
            ),
          ),

          SizedBox(height: 16),

          // Monthly Fitness Budget with improved UI
          Text(
            'Monthly Fitness Budget (\$)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: textFieldDecoration.copyWith(
              hintText: '0-5000',
              labelText: 'Monthly Fitness Budget',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),

          SizedBox(height: 16),

          // Improved checkbox styling for dietary preferences
          Text(
            'Dietary Preferences',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),

          // Add Card wrapper for checkboxes
          Card(
            elevation: 0,
            color: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                _buildCheckboxTile('No dietary restrictions', 'none', (value) {
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
                }),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withOpacity(0.3),
                ),

                _buildCheckboxTile('Vegetarian', 'vegetarian', (value) {
                  setState(() {
                    if (value == true) {
                      _dietaryPreferences['none'] = false;
                      _dietaryPreferences['vegan'] = false;
                    }
                    _dietaryPreferences['vegetarian'] = value ?? false;
                  });
                }),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withOpacity(0.3),
                ),

                _buildCheckboxTile('Vegan', 'vegan', (value) {
                  setState(() {
                    if (value == true) {
                      _dietaryPreferences['none'] = false;
                      _dietaryPreferences['vegetarian'] = false;
                    }
                    _dietaryPreferences['vegan'] = value ?? false;
                  });
                }),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withOpacity(0.3),
                ),

                _buildCheckboxTile('Gluten-Free', 'glutenFree', (value) {
                  setState(() {
                    if (value == true) _dietaryPreferences['none'] = false;
                    _dietaryPreferences['glutenFree'] = value ?? false;
                  });
                }),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withOpacity(0.3),
                ),

                _buildCheckboxTile('Keto', 'keto', (value) {
                  setState(() {
                    if (value == true) _dietaryPreferences['none'] = false;
                    _dietaryPreferences['keto'] = value ?? false;
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for creating consistent checkbox tiles
  Widget _buildCheckboxTile(
    String title,
    String key,
    Function(bool?) onChanged,
  ) {
    final theme = Theme.of(context);

    return CheckboxListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
      ),
      value: _dietaryPreferences[key] ?? false,
      activeColor: theme.primaryColor,
      checkColor: theme.colorScheme.onPrimary,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
      controlAffinity: ListTileControlAffinity.trailing,
      onChanged: onChanged,
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
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: DropdownButton<String>(
        value: currentValue,
        icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
        underline: Container(height: 0),
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        dropdownColor: theme.scaffoldBackgroundColor,
        isDense: true,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: theme.primaryColor,
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
