import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

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
        Uri.parse('http://159.65.116.13:3000/process-query'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Column(
        children: [
          // New message input field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                  color: Colors.black,
                ), // Add black text color
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  suffixIcon:
                      _isLoading
                          ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                          : IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              _createNewChat(_messageController.text);
                            },
                          ),
                ),
                onSubmitted: (text) {
                  _createNewChat(text);
                },
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
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chats yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a new conversation above!',
                          style: TextStyle(color: Colors.grey.shade500),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          chatTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          timeAgo,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                        onTap: () {
                          _navigateToChatDetail(context, chatDoc.id, chatTitle);
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
        Uri.parse('${dotenv.env['API_BASE_URL']}process-query'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'nameUser': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          'userInfo': '',
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chatTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: Column(
        children: [
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
                    child: CircularProgressIndicator(color: theme.primaryColor),
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
                          color:
                              isDarkMode
                                  ? Colors.white24
                                  : Colors.grey.shade300,
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
                    var messageData = messageDoc.data() as Map<String, dynamic>;
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
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
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
                                      ? theme.primaryColor
                                      : isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
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
                            child: Text(
                              messageText,
                              style: TextStyle(
                                color:
                                    isUser
                                        ? Colors.white
                                        : Colors
                                            .black, // Changed to always be black for assistant
                                fontSize: 16,
                              ),
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
                                  color:
                                      isDarkMode
                                          ? Colors.white54
                                          : Colors.black54,
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
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.white30 : Colors.grey.shade300,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                        color: Colors.black, // Changed to always be black
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode
                                  ? Colors.white54
                                  : Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (text) {
                        if (!_isLoading) _sendMessage(text);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Material(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(24.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24.0),
                    onTap:
                        _isLoading
                            ? null
                            : () => _sendMessage(_messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
