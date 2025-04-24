import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({Key? key}) : super(key: key);

  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController _journalController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _currentJournalId;

  @override
  void initState() {
    super.initState();
    _loadTodaysJournal();
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _loadTodaysJournal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        // Not logged in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal_entries')
          .where('date', isEqualTo: _currentDate)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        setState(() {
          _journalController.text = doc['content'] ?? '';
          _currentJournalId = doc.id;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading journal: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveJournal() async {
    if (_journalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something in your journal')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        // Not logged in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save your journal')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userRef = _firestore.collection('users').doc(userId);
      final journalRef = userRef.collection('journal_entries');

      if (_currentJournalId != null) {
        // Update existing journal
        await journalRef.doc(_currentJournalId).update({
          'content': _journalController.text,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new journal
        final docRef = await journalRef.add({
          'content': _journalController.text,
          'date': _currentDate,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        _currentJournalId = docRef.id;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving journal: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = themeProvider.isDarkMode;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Journal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
        iconTheme: IconThemeData(
          color: theme.colorScheme.secondary,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _showDatePicker(),
          ),
        ],
      ),
      body: Container(
        constraints: BoxConstraints(
          minHeight: screenHeight,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    Color(0xFF250050), // Dark purple
                    Color(0xFF24004e), // Dark purple
                    Color(0xFF1d0040), // Medium dark purple
                    Color(0xFF190039), // Dark purple
                    Color(0xFF190038), // Dark purple
                    Color(0xFF120621), // Very dark purple/indigo
                    Color(0xFF030203), // Almost black
                    Color(0xFF000000), // Black
                  ]
                : [
                    Color(0xFFffffff), // White
                    Color(0xFFeeeeee), // Very light gray
                    Color(0xFFdcdcdc), // Light gray
                    Color(0xFFcbcbcb), // Light/medium gray
                    Color(0xFFb6b6b6), // Medium gray
                    Color(0xFF9e9e9e), // Medium gray
                    Color(0xFF868686), // Darker medium gray
                    Color(0xFF6f6f6f), // Dark gray
                  ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date display
                      Container(
                        padding: const EdgeInsets.all(12),
                        
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_note,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy')
                                  .format(DateTime.parse(_currentDate)),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Prompt
                      Text(
                        'What did you do today?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      // Journal text field
                      Expanded(
                        child: Container(
                          
                          child: TextField(
                            
                            textAlignVertical: TextAlignVertical.top,
                            controller: _journalController,
                            maxLines: null,
                            expands: true,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black,
                            ),
                            
                            decoration: InputDecoration(
                              fillColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.9),
                              hintText: 'Write about your day...',
                              hintStyle: TextStyle(color: const Color.fromARGB(255, 97, 97, 97)),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveJournal,
                          
                          child: Text(
                            'Save Journal',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_currentDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
        return Theme(
            data: isDarkMode
              ? ThemeData(
                colorScheme: ColorScheme.dark(
                primary: const Color.fromARGB(255, 255, 255, 255),
                ),
              )
              : ThemeData(
                colorScheme: ColorScheme.light(
                primary: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            
          
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _currentDate = DateFormat('yyyy-MM-dd').format(picked);
        _currentJournalId = null;
        _journalController.clear();
      });
      _loadTodaysJournal();
    }
  }
}