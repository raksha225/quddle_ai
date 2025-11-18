import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants/colors.dart';
import 'chatbot_controller.dart';
import 'models/chat_message.dart';
import 'widgets/message_bubble.dart';
import 'widgets/input_field.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final ChatbotController _controller = ChatbotController();
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _typingAnimationController;
  final List<ChatMessage> _messages = [];
  bool _isLoadingSession = true;
  DateTime? _lastActiveTime;
  bool _hasShownEndBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize typing animation controller
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Load persisted last active time and then initialize session
    _loadLastActiveTime().then((_) {
      // Initialize session and load messages after loading last active time
      _initializeSession();
    });
  }

  // Load last active time from SharedPreferences
  Future<void> _loadLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActiveTimeString = prefs.getString('chatbot_last_active_time');
      if (lastActiveTimeString != null) {
        _lastActiveTime = DateTime.parse(lastActiveTimeString);
        final now = DateTime.now();
        final timeDifference = now.difference(_lastActiveTime!);
        final twentySeconds = const Duration(seconds: 20);
        
        // If user was away for 20+ seconds, reset _hasShownEndBanner so banner can show again
        if (timeDifference >= twentySeconds) {
          _hasShownEndBanner = false;
        }
      } else {
        _hasShownEndBanner = false;
      }
    } catch (e) {
      // Error loading last active time
    }
  }

  // Save last active time to SharedPreferences
  Future<void> _saveLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastActiveTime != null) {
        await prefs.setString('chatbot_last_active_time', _lastActiveTime!.toIso8601String());
      } else {
        await prefs.remove('chatbot_last_active_time');
      }
    } catch (e) {
      // Error saving last active time
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload session when app comes back to foreground
      _initializeSession();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Track when user navigates away (but don't set time here - only when user presses back)
      // This is handled in the back button onPressed
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingAnimationController.dispose();
    _messageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Initialize session and load messages
  Future<void> _initializeSession() async {
    try {
      // Load active session (don't create new if none exists)
      final activeSession = await _controller.loadActiveSession();

      if (mounted) {
        setState(() {
          // Only load active sessions (ended sessions won't be loaded)
          if (activeSession != null && activeSession.isActive && activeSession.messages.isNotEmpty) {
            // Load messages from active session
            _messages.clear();
            _messages.addAll(activeSession.messages);
            
            // If user was away for 20+ seconds, add banner message immediately with typing indicator
            if (_lastActiveTime != null && !_hasShownEndBanner) {
              final now = DateTime.now();
              final timeDifference = now.difference(_lastActiveTime!);
              final twentySeconds = const Duration(seconds: 20);
              
              if (timeDifference >= twentySeconds) {
                // First add typing indicator (loading message)
                _messages.add(ChatMessage(
                  text: '...',
                  isUser: false,
                  timestamp: DateTime.now(),
                  isLoading: true,
                ));
                _hasShownEndBanner = true;
                
                // Wait a bit to show typing indicator, then replace with banner message
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    setState(() {
                      // Remove loading message
                      _messages.removeWhere((msg) => msg.isLoading && msg.text == '...');
                      
                      // Add banner message
                      _messages.add(ChatMessage(
                        text: 'If you don\'t have any doubt, are you want to end this conversation?',
                        isUser: false,
                        timestamp: DateTime.now(),
                        isEndBanner: true,
                      ));
                    });
                    _scrollToBottom();
                  }
                });
              }
            }
            
            // Ensure first message has prompts if it's the welcome message
            if (_messages.isNotEmpty && _messages.first.text == _controller.welcomeMessage) {
              _messages[0] = ChatMessage(
                text: _controller.welcomeMessage,
                isUser: false,
                timestamp: _messages.first.timestamp,
                prompts: _controller.welcomePrompts,
              );
            }
          } else if (activeSession != null && activeSession.messages.isEmpty) {
            // Session exists but has no messages - add welcome message
            _messages.clear();
            _messages.add(ChatMessage(
              text: _controller.welcomeMessage,
              isUser: false,
              timestamp: activeSession.createdAt,
              prompts: _controller.welcomePrompts,
            ));
          } else {
            // Add welcome message with prompts if no active session
            final welcomeMsg = ChatMessage(
              text: _controller.welcomeMessage,
              isUser: false,
              timestamp: DateTime.now(),
              prompts: _controller.welcomePrompts,
            );
            _messages.add(welcomeMsg);
          }
          _isLoadingSession = false;
        });
        
        // Create new session and save welcome message if no active session
        if (activeSession == null) {
          final newSession = await _controller.initializeSession();
          
          final welcomeMsg = _messages.firstWhere(
            (msg) => msg.text == _controller.welcomeMessage,
            orElse: () => ChatMessage(
              text: _controller.welcomeMessage,
              isUser: false,
              timestamp: DateTime.now(),
              prompts: _controller.welcomePrompts,
            ),
          );
          // Add welcome message to session and save
          final sessionWithWelcome = newSession.addMessage(welcomeMsg);
          await _controller.updateSession(sessionWithWelcome);
          await _controller.saveCurrentSession();
        }

        // Scroll to bottom after loading messages
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Add welcome message on error
          _messages.add(ChatMessage(
            text: _controller.welcomeMessage,
            isUser: false,
            timestamp: DateTime.now(),
            prompts: _controller.welcomePrompts,
          ));
          _isLoadingSession = false;
        });
      }
    }
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.scrollController.hasClients) {
        _controller.scrollController.animateTo(
          _controller.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? promptText]) async {
    final messageText = promptText ?? _messageController.text;
    if (messageText.trim().isEmpty) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    if (promptText == null) {
      _messageController.clear();
    }

    // Check if user was away for 20+ seconds - show banner after message response
    // IMPORTANT: Check BEFORE resetting _lastActiveTime
    final shouldShowBanner = _shouldShowEndBanner();
    
    if (shouldShowBanner) {
      _hasShownEndBanner = true;
    }

    // Reset last active time when user sends message (so timer doesn't persist)
    _lastActiveTime = null;
    await _saveLastActiveTime();

    // Optimistically add user message
    setState(() {
      _messages.add(ChatMessage(
        text: messageText.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messages.add(ChatMessage(
        text: '...',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });
    // Scroll after UI updates
    _scrollToBottom();

    // Get updated messages from controller (saves session automatically)
    final updatedMessages = await _controller.sendMessage(
      messageText,
      _messages,
      () => mounted,
    );

    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(updatedMessages);
        
        // Add end conversation banner message if user was away for 20+ seconds
        if (shouldShowBanner) {
          _messages.add(ChatMessage(
            text: 'If you don\'t have any doubt, are you want to end this conversation?',
            isUser: false,
            timestamp: DateTime.now(),
            isEndBanner: true, // Flag to indicate this is a banner message
          ));
        }
      });
      // Scroll after UI updates with bot response
      _scrollToBottom();
    }
  }

  // Check if user has been away for more than 20 seconds
  bool _shouldShowEndBanner() {
    if (_lastActiveTime == null) {
      return false;
    }
    
    if (_hasShownEndBanner) {
      return false;
    }
    
    final now = DateTime.now();
    final timeSinceLastActive = now.difference(_lastActiveTime!);
    final twentySeconds = const Duration(seconds: 20);
    
    return timeSinceLastActive >= twentySeconds;
  }

  // Handle end conversation button click
  Future<void> _handleEndConversation() async {
    await _controller.endCurrentSession();
    if (mounted) {
      Navigator.pop(context); // Navigate back to home
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: MyColors.navbarGradient,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () async {
            // Track when user navigates away
            _lastActiveTime = DateTime.now();
            await _saveLastActiveTime();
            Navigator.pop(context);
          },
        ),
          title: const Text(
            'Ai Assistant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
      body: _isLoadingSession
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView.builder(
                      controller: _controller.scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return MessageBubble(
                          message: message,
                          typingAnimationController: _typingAnimationController,
                          onPromptSelected: _sendMessage,
                          onEndConversation: _handleEndConversation,
                        );
                      },
                    ),
                  ),
                ),
                // Menu button above input field
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          // Show menu message with prompts
                          setState(() {
                            _messages.add(ChatMessage(
                              text: _controller.welcomeMessage,
                              isUser: false,
                              timestamp: DateTime.now(),
                              prompts: _controller.welcomePrompts,
                            ));
                          });
                          _scrollToBottom();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu,
                                color: Colors.grey[700],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Menu',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Input field
                ChatInputField(
                  messageController: _messageController,
                  onSend: _sendMessage,
                ),
              ],
            ),
      );
  }
}