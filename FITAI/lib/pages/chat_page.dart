import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:hk11/theme/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart' as provider;

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Assume the current user ID is available
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? 'none';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Generate a chat title from the first message
  String _generateChatTitle(String message) {
    // Use the current date as the chat title instead of message content
    return DateFormat('MMMM d, yyyy').format(DateTime.now());
  }

  // Create a new chat with the initial message
  Future<void> _createNewChat(String initialMessage) async {
    if (initialMessage.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new chat document with auto-generated ID
      final chatRef =
          _firestore
              .collection('chats')
              .doc(currentUserId)
              .collection('chats')
              .doc();

      // Generate a chat title from the initial message
      final chatTitle = _generateChatTitle(initialMessage);

      // Create chat document
      await chatRef.set({
        'chatTitle': chatTitle,
        'lastVisited': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add initial user message to messages collection
      await chatRef.collection('messages').add({
        'role': 'user',
        'text': initialMessage,
        'dateSent': FieldValue.serverTimestamp(),
      });

      // Send the message to the server and get a response
      final assistantResponse = await _getAssistantResponse(initialMessage);

      // Add assistant's response to messages collection
      await chatRef.collection('messages').add({
        'role': 'assistant',
        'text': assistantResponse,
        'dateSent': FieldValue.serverTimestamp(),
      });

      // Update last visited timestamp
      await chatRef.update({'lastVisited': FieldValue.serverTimestamp()});

      // Clear the message input
      _messageController.clear();

      // Navigate to the chat detail page with the newly created chat
      _navigateToChatDetail(context, chatRef.id, chatTitle);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating chat: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getAssistantResponse(String query) async {
    try {
      // Get user profile data from Firestore
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data() ?? {};

      // Extract dietary preferences that are true
      final dietaryPreferences =
          userData['dietary_preferences'] as Map<String, dynamic>? ?? {};
      final selectedDiets =
          dietaryPreferences.entries
              .where((e) => e.value == true)
              .map((e) => e.key)
              .toList();

      // Format user info as string
      final userInfo = [
        "Activity Level - ${userData['activity_level'] ?? 'N/A'}",
        "Age - ${userData['age'] ?? 'N/A'}",
        "Dietary Preferences - ${selectedDiets.join(', ')}",
        "Gender - ${userData['gender'] ?? 'N/A'}",
        "Goal - ${userData['goal'] ?? 'N/A'}",
        "Height - ${userData['height'] ?? 'N/A'} ${userData['height_unit'] ?? 'cm'}",
        "Monthly Budget - ${userData['monthly_budget'] ?? 'N/A'}",
      ].join('\n');

      // Make the API request
      final response = await http.post(
        Uri.parse('http://46.10.181.183:20300/process-query'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          'userInfo': userInfo,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? 'Sorry, I couldn\'t process your request.';
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        return 'Sorry, there was an error processing your request.';
      }
    } catch (e) {
      print('Exception in _getAssistantResponse: ${e.toString()}');
      return 'Network error: Unable to connect to the assistant service.';
    }
  }

  // Navigate to chat detail screen
  void _navigateToChatDetail(
    BuildContext context,
    String chatId,
    String chatTitle,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatDetailPage(chatId: chatId, chatTitle: chatTitle),
      ),
    );
  }

  // Add a new method to create an empty chat (no initial message)
  Future<void> _createEmptyChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new chat document with auto-generated ID
      final chatRef =
          _firestore
              .collection('chats')
              .doc(currentUserId)
              .collection('chats')
              .doc();

      // Generate a chat title based on current date
      final chatTitle = _generateChatTitle('');

      // Create empty chat document
      await chatRef.set({
        'chatTitle': chatTitle,
        'lastVisited': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to the chat detail page with the newly created chat
      _navigateToChatDetail(context, chatRef.id, chatTitle);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating chat: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var isDarkMode = provider.Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar:
          true, // This allows the gradient to extend behind the app bar

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [
                      Color(0xFF250050), // Dark purple
                      Color(0xFF24004e), // Dark purple
                      Color(0xFF210047), // Dark purple
                      Color(0xFF1d0040), // Medium dark purple
                      Color(0xFF1b003d), // Medium dark purple
                      Color(0xFF190039), // Dark purple
                      Color(0xFF170036), // Medium dark purple
                      Color(0xFF160132), // Medium dark purple
                      Color(0xFF14022d), // Dark purple/indigo
                      Color(0xFF120327), // Very dark purple with hint of blue
                      Color(0xFF110325), // Very dark purple
                      Color(0xFF0e021d), // Very dark purple
                      Color(0xFF090213), // Almost black with hint of purple
                      Color(0xFF040109), // Almost black
                      Color(0xFF000000), // Black
                    ]
                    : [
                      Color.fromARGB(255, 143, 143, 143), // Dark gray
                    Color(0xFF868686), // Darker medium gray
                    Color(0xFF9e9e9e), // Medium gray
                    Color(0xFFb6b6b6), // Medium gray
                    Color(0xFFcbcbcb), // Light/medium gray
                    Color(0xFFdcdcdc), // Light gray
                    Color(0xFFeeeeee), // Very light gray
                    Color(0xFFffffff),
                    ],
            
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            // Replace button action to create empty chat directly
            Padding(
              padding: const EdgeInsets.all(22.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createEmptyChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.8),

                  minimumSize: const Size(460, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.secondary,
                          ),
                        )
                        : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Start a new chat',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
              ),
            ),

            // Chat history
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('chats')
                        .doc(currentUserId)
                        .collection('chats')
                        .orderBy('lastVisited', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No chats yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a new conversation above!',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      var chatDoc = snapshot.data!.docs[index];
                      var chatData = chatDoc.data() as Map<String, dynamic>;
                      var chatTitle = chatData['chatTitle'] ?? 'Untitled Chat';

                      // Format timestamp if available
                      String timeAgo = '';
                      if (chatData['lastVisited'] != null) {
                        var timestamp = chatData['lastVisited'] as Timestamp;
                        var date = timestamp.toDate();
                        timeAgo = DateFormat.yMMMd().add_jm().format(date);
                      }

                      return Card(
                        elevation: 0,

                        color: theme.colorScheme.primary.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          title: Text(
                            chatTitle,
                            style: theme.textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            timeAgo,
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          onTap: () {
                            _navigateToChatDetail(
                              context,
                              chatDoc.id,
                              chatTitle,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method to show a dialog for creating a new chat
  void _showNewChatDialog(BuildContext context) {
    _messageController.clear();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Start a new chat'),
            content: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_messageController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    _createNewChat(_messageController.text);
                  }
                },
                child: Text('Start Chat'),
              ),
            ],
          ),
    );
  }
}

// ChatDetailPage class for viewing individual chats
class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String chatTitle;

  const ChatDetailPage({
    Key? key,
    required this.chatId,
    required this.chatTitle,
  }) : super(key: key);

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'test_user';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get reference to the chat document
      final chatRef = _firestore
          .collection('chats')
          .doc(currentUserId)
          .collection('chats')
          .doc(widget.chatId);

      // Add user message
      await chatRef.collection('messages').add({
        'role': 'user',
        'text': message,
        'dateSent': FieldValue.serverTimestamp(),
      });

      // Update the last visited timestamp
      await chatRef.update({'lastVisited': FieldValue.serverTimestamp()});

      // Clear the input field
      _messageController.clear();

      // Get assistant's response
      final assistantResponse = await _getAssistantResponse(message);

      // Add assistant's response
      await chatRef.collection('messages').add({
        'role': 'assistant',
        'text': assistantResponse,
        'dateSent': FieldValue.serverTimestamp(),
      });

      // Scroll to bottom to show the latest messages
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getAssistantResponse(String query) async {
    try {
      // Call the processQuery function through the API endpoint we set up
      var response = await http.post(
        Uri.parse('http://46.10.181.183:20300/process-query'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'nameUser':
              FirebaseAuth.instance.currentUser?.displayName ?? "friend",
          'userInfo': "none",
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['answer'] ?? 'Sorry, I couldn\'t process your request.';
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        return 'Sorry, there was an error processing your request.';
      }
    } catch (e) {
      print('Exception in _getAssistantResponse: ${e.toString()}');
      return 'Network error: Unable to connect to the assistant service.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var isDarkMode = provider.Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.chatTitle, style: theme.textTheme.headlineLarge),
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [
                      Color(0xFF250050), // Dark purple
                      Color(0xFF24004e), // Dark purple
                      Color(0xFF210047), // Dark purple
                      Color(0xFF1d0040), // Medium dark purple
                      Color(0xFF1b003d), // Medium dark purple
                      Color(0xFF190039), // Dark purple
                      Color(0xFF170036), // Medium dark purple
                      Color(0xFF160132), // Medium dark purple
                      Color(0xFF14022d), // Dark purple/indigo
                      Color(0xFF120327), // Very dark purple with hint of blue
                      Color(0xFF110325), // Very dark purple
                      Color(0xFF0e021d), // Very dark purple
                      Color(0xFF090213), // Almost black with hint of purple
                      Color(0xFF040109), // Almost black
                      Color(0xFF000000),  // Black
                    ]
                    : [
                      Color.fromARGB(255, 143, 143, 143), // Dark gray
                    Color(0xFF868686), // Darker medium gray
                    Color(0xFF9e9e9e), // Medium gray
                    Color(0xFFb6b6b6), // Medium gray
                    Color(0xFFcbcbcb), // Light/medium gray
                    Color(0xFFdcdcdc), // Light gray
                    Color(0xFFeeeeee), // Very light gray
                    Color(0xFFffffff),
                    ],
            
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top),

            // Messages list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('chats')
                        .doc(currentUserId)
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .orderBy('dateSent', descending: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a new conversation below!',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  // Update scroll position after build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var messageDoc = snapshot.data!.docs[index];
                      var messageData =
                          messageDoc.data() as Map<String, dynamic>;
                      var isUser = messageData['role'] == 'user';
                      var messageText = messageData['text'] ?? '';

                      // Get timestamp if available
                      String time = '';
                      if (messageData['dateSent'] != null) {
                        var timestamp = messageData['dateSent'] as Timestamp;
                        var date = timestamp.toDate();
                        time = DateFormat.jm().format(date);
                      }

                      return Align(
                        alignment:
                            isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment:
                              isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(
                                top: 4.0,
                                bottom: 2.0,
                                left: isUser ? 64.0 : 0.0,
                                right: isUser ? 0.0 : 64.0,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isUser
                                        ? theme.colorScheme.onSecondary
                                        : theme.colorScheme.onPrimary,

                                borderRadius: BorderRadius.circular(
                                  20.0,
                                ).copyWith(
                                  bottomRight:
                                      isUser ? const Radius.circular(0) : null,
                                  bottomLeft:
                                      !isUser ? const Radius.circular(0) : null,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child:
                                  isUser
                                      ? Text(
                                        messageText,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.white),
                                      )
                                      : MarkdownBody(
                                        data: messageText,
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                          ),
                                          strong: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          em: TextStyle(
                                            color: Colors.black,
                                            fontStyle: FontStyle.italic,
                                            fontSize: 16,
                                          ),
                                          h1: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                          ),
                                          h2: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                          h3: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                          listBullet: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                          ),
                                        ),
                                        softLineBreak: true,
                                      ),
                            ),
                            if (time.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isUser ? 0 : 8.0,
                                  right: isUser ? 8.0 : 0,
                                  bottom: 8.0,
                                ),
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Message input
            Container(
              padding: const EdgeInsets.all(16.0),

              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      
                      controller: _messageController,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(42),
                          borderSide: BorderSide(
                            color: theme.colorScheme.secondary,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(42),
                          borderSide: BorderSide(
                            color: theme.colorScheme.secondary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ), // Make transparent since container has color
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: const Color.fromARGB(255, 97, 97, 97),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0, // Increased padding
                          vertical: 14.0, // Increased padding
                        ),
                        suffixIcon:
                            _isLoading
                                ? Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: theme.colorScheme.onSecondary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                                : Container(
                                  margin: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,

                                    color: theme.colorScheme.onSecondary,
                                  ),

                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      
                                      Icons.arrow_upward_rounded,
                                      color: Colors.white,
                                      weight: 1000,
                                      size: 26,
                                    ),
                                    onPressed: () {
                                      if (!_isLoading)
                                        _sendMessage(_messageController.text);
                                    },
                                  ),
                                ),
                      ),
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (text) {
                        if (!_isLoading) _sendMessage(text);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
