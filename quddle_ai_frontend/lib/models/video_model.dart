class VideoModel {
  final String id;
  final String userId;
  final String s3Key;
  final String s3Url;
  final int? durationSec;
  final int? sizeBytes;
  final DateTime createdAt;
  final String? description;
  final String? userName;
  final String? userAvatar;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final bool isBookmarked;

  VideoModel({
    required this.id,
    required this.userId,
    required this.s3Key,
    required this.s3Url,
    this.durationSec,
    this.sizeBytes,
    required this.createdAt,
    this.description,
    this.userName,
    this.userAvatar,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      s3Key: json['s3_key']?.toString() ?? '',
      s3Url: json['s3_url']?.toString() ?? '',
      durationSec: json['duration_sec'] as int?,
      sizeBytes: json['size_bytes'] as int?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      description: json['description'] as String?,
      userName: json['user_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      sharesCount: json['shares_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      's3_key': s3Key,
      's3_url': s3Url,
      'duration_sec': durationSec,
      'size_bytes': sizeBytes,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'user_name': userName,
      'user_avatar': userAvatar,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'shares_count': sharesCount,
      'is_liked': isLiked,
      'is_bookmarked': isBookmarked,
    };
  }

  VideoModel copyWith({
    String? id,
    String? userId,
    String? s3Key,
    String? s3Url,
    int? durationSec,
    int? sizeBytes,
    DateTime? createdAt,
    String? description,
    String? userName,
    String? userAvatar,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    bool? isBookmarked,
  }) {
    return VideoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      s3Key: s3Key ?? this.s3Key,
      s3Url: s3Url ?? this.s3Url,
      durationSec: durationSec ?? this.durationSec,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, userId: $userId, s3Url: $s3Url, duration: ${durationSec}s)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
