class ChatSessionMetadata {
  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime? endedAt;
  final int messageCount;

  ChatSessionMetadata({
    required this.id,
    this.title,
    required this.createdAt,
    this.endedAt,
    required this.messageCount,
  });

  // Check if session is active
  bool get isActive => endedAt == null;

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'messageCount': messageCount,
    };
  }

  // Create from JSON
  factory ChatSessionMetadata.fromJson(Map<String, dynamic> json) {
    return ChatSessionMetadata(
      id: json['id'] as String,
      title: json['title'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      messageCount: json['messageCount'] as int,
    );
  }

  // Create from ChatSession
  factory ChatSessionMetadata.fromSession(dynamic session) {
    return ChatSessionMetadata(
      id: session.id,
      title: session.title,
      createdAt: session.createdAt,
      endedAt: session.endedAt,
      messageCount: session.messageCount,
    );
  }
}

