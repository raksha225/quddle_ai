import 'chat_message.dart';

class ChatSession {
  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime? endedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    this.title,
    required this.createdAt,
    this.endedAt,
    required this.messages,
  });

  // Get message count
  int get messageCount => messages.length;

  // Check if session is active
  bool get isActive => endedAt == null;

  // Auto-generate title from first user message
  String? get autoTitle {
    if (messages.isEmpty) return null;
    
    final firstUserMessage = messages.firstWhere(
      (msg) => msg.isUser && !msg.isLoading,
      orElse: () => messages.first,
    );
    
    if (firstUserMessage.text.length > 50) {
      return '${firstUserMessage.text.substring(0, 50)}...';
    }
    return firstUserMessage.text;
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title ?? autoTitle,
      'createdAt': createdAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }

  // Create from JSON
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      messages: (json['messages'] as List)
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList(),
    );
  }

  // Create a copy with updated fields
  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? endedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
      messages: messages ?? this.messages,
    );
  }

  // Add a message to the session
  ChatSession addMessage(ChatMessage message) {
    return copyWith(
      messages: [...messages, message],
    );
  }

  // End the session
  ChatSession endSession() {
    return copyWith(
      endedAt: DateTime.now(),
    );
  }
}

