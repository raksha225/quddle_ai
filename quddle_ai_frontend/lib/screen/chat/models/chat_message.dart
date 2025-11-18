class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final List<String>? prompts;
  final bool isEndBanner;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.prompts,
    this.isEndBanner = false,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
      'prompts': prompts,
      'isEndBanner': isEndBanner,
    };
  }

  // Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isLoading: json['isLoading'] as bool? ?? false,
      prompts: json['prompts'] != null
          ? List<String>.from(json['prompts'] as List)
          : null,
      isEndBanner: json['isEndBanner'] as bool? ?? false,
    );
  }
}

