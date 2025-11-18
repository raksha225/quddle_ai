import 'package:flutter/material.dart';
import '../../services/chatbot_service.dart';
import '../../services/chat_session_storage.dart';
import 'models/chat_message.dart';
import 'models/chat_session.dart';
import 'models/chat_session_metadata.dart';

class ChatbotController {
  final ScrollController scrollController = ScrollController();
  final ChatSessionStorage _storage = ChatSessionStorage();
  final String welcomeMessage = 'Menu';
  
  // Current active session
  ChatSession? _currentSession;

  // Get current session
  ChatSession? get currentSession => _currentSession;

  // Check if there's an active session
  bool get hasActiveSession => _currentSession != null && _currentSession!.isActive;
  
  // Clickable prompts for welcome message
  final List<String> welcomePrompts = [
    'What can you help me with?',
    'Tell me about Quddle',
    'How do I upload a reel?',
    'How do I like a reel?',
  ];

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Load active session (doesn't create new if none exists)
  Future<ChatSession?> loadActiveSession() async {
    try {
      final activeSession = await _storage.loadActiveSession();
      // debugPrint('📂 Loaded active session: ${activeSession?.id}, messages: ${activeSession?.messages.length ?? 0}');
      if (activeSession != null && activeSession.isActive) {
        _currentSession = activeSession;
        debugPrint('✅ Active session loaded with ${activeSession.messages.length} messages');
      } else {
        // debugPrint('⚠️ No active session found');
      }
      return _currentSession;
    } catch (e) {
      debugPrint('❌ Error loading active session: $e');
      return null;
    }
  }

  // Initialize session - load active session or create new
  Future<ChatSession> initializeSession() async {
    try {
      // Try to load active session
      final activeSession = await _storage.loadActiveSession();
      
      if (activeSession != null && activeSession.isActive) {
        _currentSession = activeSession;
        return activeSession;
      }
      
      // Create new session if no active session
      _currentSession = await _storage.createNewSession();
      return _currentSession!;
    } catch (e) {
      // Fallback: create new session on error
      _currentSession = await _storage.createNewSession();
      return _currentSession!;
    }
  }

  // Update current session
  Future<void> updateSession(ChatSession session) async {
    _currentSession = session;
  }

  // Save current session to storage
  Future<bool> saveCurrentSession() async {
    if (_currentSession == null) return false;
    
    try {
      final saved = await _storage.saveSession(_currentSession!);
      // debugPrint('💾 Session saved: ${_currentSession!.id}, messages: ${_currentSession!.messages.length}');
      return saved;
    } catch (e) {
      debugPrint('Error saving current session: $e');
      return false;
    }
  }

  // End current session
  Future<bool> endCurrentSession() async {
    if (_currentSession == null) return false;
    
    try {
      final ended = await _storage.endSession(_currentSession!.id);
      if (ended) {
        _currentSession = _currentSession!.endSession();
      }
      return ended;
    } catch (e) {
      debugPrint('Error ending current session: $e');
      return false;
    }
  }

  // Delete a session
  Future<bool> deleteSession(String sessionId) async {
    try {
      final deleted = await _storage.deleteSession(sessionId);
      
      // Clear current session if it was deleted
      if (deleted && _currentSession?.id == sessionId) {
        _currentSession = null;
      }
      
      return deleted;
    } catch (e) {
      debugPrint('Error deleting session: $e');
      return false;
    }
  }

  // Load session history (metadata only)
  Future<List<ChatSessionMetadata>> loadSessionHistory() async {
    try {
      return await _storage.loadSessionMetadata();
    } catch (e) {
      debugPrint('Error loading session history: $e');
      return [];
    }
  }

  // Resume an old session
  Future<ChatSession?> resumeSession(String sessionId) async {
    try {
      final session = await _storage.loadSession(sessionId);
      if (session != null) {
        // If session is ended, create a new one instead
        if (session.endedAt != null) {
          _currentSession = await _storage.createNewSession();
        } else {
          _currentSession = session;
          await _storage.setActiveSessionId(sessionId);
        }
        return _currentSession;
      }
      return null;
    } catch (e) {
      debugPrint('Error resuming session: $e');
      return null;
    }
  }

  List<Map<String, String>> buildConversationHistory(List<ChatMessage> messages) {
    final conversationHistory = <Map<String, String>>[];
    for (var msg in messages) {
      // Skip loading messages and the initial welcome message
      if (!msg.isLoading &&
          msg.text != '...' &&
          msg.text != welcomeMessage) {
        conversationHistory.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }
    }
    return conversationHistory;
  }

  // Get specific answer for predefined questions
  String? getSpecificAnswer(String messageText) {
    final lowerMessage = messageText.toLowerCase().trim();
    
    // Check for specific questions and return predefined answers
    if (lowerMessage.contains('what can you help me with') || 
        lowerMessage == 'what can you help me with?') {
      return 'I can help you with:\n\n'
          '• Learning about Quddle and its features\n'
          '• Uploading and managing your reels\n'
          '• Understanding how to interact with content (likes, shares, comments)\n'
          '• Navigating the app and finding features\n'
          '• Answering general questions about the platform\n\n'
          'Just ask me anything, and I\'ll do my best to help!';
    }
    
    if (lowerMessage.contains('tell me about quddle') || 
        lowerMessage == 'tell me about quddle') {
      return 'Quddle is a social media platform where you can:\n\n'
          '• Create and share short video reels\n'
          '• Discover trending content\n'
          '• Engage with posts through likes, comments, and shares\n'
          '• Build your profile and showcase your content\n'
          '• Connect with other creators\n\n'
          'Think of it as a space for creative expression and community engagement through video content!';
    }
    
    if (lowerMessage.contains('how do i upload a reel') || 
        lowerMessage.contains('upload a reel') ||
        lowerMessage == 'how do i upload a reel?') {
      return 'To upload a reel on Quddle:\n\n'
          '1. Tap on the "Upload" button (usually a + icon or camera icon)\n'
          '2. Select a video from your gallery or record a new one\n'
          '3. Add any filters, captions, or edits you want\n'
          '4. Add a description and hashtags if desired\n'
          '5. Tap "Post" or "Upload" to share your reel\n\n'
          'Your reel will then appear in your profile and in the feed for others to discover!';
    }
    
    if (lowerMessage.contains('how do i like a reel') || 
        lowerMessage.contains('like a reel') ||
        lowerMessage == 'how do i like a reel?') {
      return 'To like a reel on Quddle:\n\n'
          '1. While watching a reel, tap the heart icon ❤️ on the right side\n'
          '2. The heart will turn red, indicating you\'ve liked it\n'
          '3. Tap again to unlike if you change your mind\n\n'
          'Liking helps creators know their content is appreciated and can help popular reels reach more people!';
    }
    
    return null; // No specific answer, use LLM
  }

  // Check if question is vague or unrelated to Quddle
  bool isVagueOrUnrelated(String messageText) {
    final lowerMessage = messageText.toLowerCase().trim();
    
    // Greetings that should get normal replies
    final greetingPatterns = [
      r'^(hi|hello|hey|greetings|hey there|hi there)\s*$',
      r'^(hi|hello|hey|greetings|hey there|hi there)\s+[!.]*$',
    ];
    
    // Check if message is a greeting
    final isGreeting = greetingPatterns.any((pattern) {
      final regex = RegExp(pattern, caseSensitive: false);
      return regex.hasMatch(lowerMessage);
    });
    
    // If it's a greeting, allow normal reply
    if (isGreeting) {
      return false;
    }
    
    // Quddle-related keywords
    final quddleKeywords = [
      'quddle',
      'reel',
      'reels',
      'video',
      'videos',
      'upload',
      'like',
      'likes',
      'profile',
      'creator',
      'creators',
      'feed',
      'share',
      'sharing',
      'comment',
      'comments',
      'hashtag',
      'hashtags',
      'post',
      'posts',
      'content',
      'social media',
      'platform',
      'app',
    ];
    
    // Check if message contains Quddle-related keywords
    final containsQuddleKeyword = quddleKeywords.any((keyword) => 
      lowerMessage.contains(keyword)
    );
    
    // If it contains Quddle-related keywords, it's not vague
    if (containsQuddleKeyword) {
      return false;
    }
    
    // Check if it's one of the predefined questions (these are not vague)
    if (getSpecificAnswer(messageText) != null) {
      return false;
    }
    
    // Vague/general questions that don't relate to Quddle
    final vaguePatterns = [
      r'^(what|who|where|when|why|how)\s+(is|are|was|were|do|does|did|can|could|will|would|should)\s+',
      r'^(tell me|explain|describe|define)\s+',
      r'^(what|who)\s+(is|are)\s+',
      r'^(help|help me|assist|support)\s*',
      r'^(thanks|thank you|thx)\s*',
      r'^(bye|goodbye|see you|farewell)\s*',
    ];
    
    // Check if message matches vague patterns
    final isVaguePattern = vaguePatterns.any((pattern) {
      final regex = RegExp(pattern, caseSensitive: false);
      return regex.hasMatch(lowerMessage);
    });
    
    // If it's a vague pattern and doesn't contain Quddle keywords, it's vague
    return isVaguePattern;
  }

  Future<List<ChatMessage>> sendMessage(
    String messageText,
    List<ChatMessage> currentMessages,
    bool Function() isMounted,
  ) async {
    if (messageText.trim().isEmpty) return currentMessages;

    // Ensure we have a current session
    if (_currentSession == null) {
      await initializeSession();
    }

    // Check if this is a predefined question with a specific answer
    final specificAnswer = getSpecificAnswer(messageText);
    if (specificAnswer != null) {
      // Remove loading message if it exists
      final updatedMessages = List<ChatMessage>.from(currentMessages);
      if (updatedMessages.isNotEmpty && updatedMessages.last.isLoading) {
        updatedMessages.removeLast();
      }

      // Check if user message is already added (from optimistic update)
      final lastMessage = updatedMessages.isNotEmpty ? updatedMessages.last : null;
      final userMessageAlreadyAdded = lastMessage != null && 
          lastMessage.isUser && 
          lastMessage.text.trim() == messageText.trim();

      // Only add user message if it's not already there
      if (!userMessageAlreadyAdded) {
        updatedMessages.add(ChatMessage(
          text: messageText.trim(),
          isUser: true,
          timestamp: DateTime.now(),
        ));
      }

      // Add bot response
      updatedMessages.add(ChatMessage(
        text: specificAnswer,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      // Update session with new messages
      if (_currentSession != null) {
        final messagesToSave = updatedMessages.where((msg) => 
          !msg.isLoading && 
          msg.text != '...'
        ).toList();
        
        _currentSession = _currentSession!.copyWith(
          messages: messagesToSave,
        );

        // Save session asynchronously (non-blocking)
        saveCurrentSession().catchError((e) {
          debugPrint('❌ Error saving session after message: $e');
          return false;
        });
      }

      scrollToBottom();
      return updatedMessages;
    }

    // Check if question is vague or unrelated to Quddle
    if (isVagueOrUnrelated(messageText)) {
      // Remove loading message if it exists
      final updatedMessages = List<ChatMessage>.from(currentMessages);
      if (updatedMessages.isNotEmpty && updatedMessages.last.isLoading) {
        updatedMessages.removeLast();
      }

      // Check if user message is already added (from optimistic update)
      final lastMessage = updatedMessages.isNotEmpty ? updatedMessages.last : null;
      final userMessageAlreadyAdded = lastMessage != null && 
          lastMessage.isUser && 
          lastMessage.text.trim() == messageText.trim();

      // Only add user message if it's not already there
      if (!userMessageAlreadyAdded) {
        updatedMessages.add(ChatMessage(
          text: messageText.trim(),
          isUser: true,
          timestamp: DateTime.now(),
        ));
      }

      // Add bot response with contact email
      updatedMessages.add(ChatMessage(
        text: 'For queries not related to Quddle, please contact us at info@quddle.ai',
        isUser: false,
        timestamp: DateTime.now(),
      ));

      // Update session with new messages
      if (_currentSession != null) {
        final messagesToSave = updatedMessages.where((msg) => 
          !msg.isLoading && 
          msg.text != '...'
        ).toList();

        _currentSession = _currentSession!.copyWith(
          messages: messagesToSave,
        );

        // Save session asynchronously (non-blocking)
        saveCurrentSession().catchError((e) {
          debugPrint('❌ Error saving session after message: $e');
          return false;
        });
      }

      scrollToBottom();
      return updatedMessages;
    }

    // Build conversation history for API (excluding loading message)
    final conversationHistory = buildConversationHistory(currentMessages);

    // Call OpenAI API
    try {
      final result = await ChatbotService.sendMessage(
        messageText.trim(),
        conversationHistory,
      );

      if (isMounted()) {
        // Remove loading message if it exists
        final updatedMessages = List<ChatMessage>.from(currentMessages);
        if (updatedMessages.isNotEmpty && updatedMessages.last.isLoading) {
          updatedMessages.removeLast();
        }

        ChatMessage? botMessage;
        if (result['success'] == true) {
          // Add bot response
          final botMessageText = result['message'] as String? ?? 'No response received.';
          botMessage = ChatMessage(
            text: botMessageText,
            isUser: false,
            timestamp: DateTime.now(),
          );
          updatedMessages.add(botMessage);
        } else {
          // Add error message
          final errorMessage = result['message'] as String? ??
              'Failed to get response. Please try again.';
          botMessage = ChatMessage(
            text: errorMessage,
            isUser: false,
            timestamp: DateTime.now(),
          );
          updatedMessages.add(botMessage);
        }

        // Update current session with new messages
        if (_currentSession != null) {
          // Filter out loading messages
          final messagesToSave = updatedMessages.where((msg) => 
            !msg.isLoading && 
            msg.text != '...'
          ).toList();
          
          debugPrint('💾 Updating session with ${messagesToSave.length} messages (excluding loading)');
          debugPrint('📋 Messages to save:');
          for (var i = 0; i < messagesToSave.length; i++) {
            final msg = messagesToSave[i];
            debugPrint('   [$i] ${msg.isUser ? "User" : "Bot"}: "${msg.text.substring(0, msg.text.length > 50 ? 50 : msg.text.length)}${msg.text.length > 50 ? "..." : ""}"');
          }
          
          // Update session with all messages (excluding loading messages only)
          // Keep welcome message and all user/bot messages
          _currentSession = _currentSession!.copyWith(
            messages: messagesToSave,
          );

          // Save session asynchronously (non-blocking)
          saveCurrentSession().catchError((e) {
            debugPrint('❌ Error saving session after message: $e');
            return false;
          });
        } else {
          debugPrint('⚠️ No current session - cannot save messages');
        }

        scrollToBottom();
        return updatedMessages;
      }
      return currentMessages;
    } catch (e) {
      if (isMounted()) {
        // Remove loading message if it exists
        final updatedMessages = List<ChatMessage>.from(currentMessages);
        if (updatedMessages.isNotEmpty && updatedMessages.last.isLoading) {
          updatedMessages.removeLast();
        }
        // Add error message
        final errorMessage = ChatMessage(
          text: 'An unexpected error occurred. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        );
        updatedMessages.add(errorMessage);

        // Update session with error message
        if (_currentSession != null) {
          _currentSession = _currentSession!.copyWith(
            messages: updatedMessages.where((msg) => 
              !msg.isLoading && 
              msg.text != '...'
            ).toList(),
          );
          saveCurrentSession().catchError((e) {
            debugPrint('Error saving session after error: $e');
            return false;
          });
        }

        scrollToBottom();
        return updatedMessages;
      }
      return currentMessages;
    }
  }

  void dispose() {
    scrollController.dispose();
  }
}

