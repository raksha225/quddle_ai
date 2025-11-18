import 'package:flutter/material.dart';

class ReelActionButtons extends StatefulWidget {
  final String reelId;
  final Set<String> likedReels;
  final Function(String) onLike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  const ReelActionButtons({
    super.key,
    required this.reelId,
    required this.likedReels,
    required this.onLike,
    this.onShare,
    this.onMore,
  });

  @override
  State<ReelActionButtons> createState() => _ReelActionButtonsState();
}

class _ReelActionButtonsState extends State<ReelActionButtons> {
  bool get _isLiked => widget.likedReels.contains(widget.reelId);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Like button
        GestureDetector(
          onTap: () => widget.onLike(widget.reelId),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.white,
              size: 28,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Share button
        GestureDetector(
          onTap: widget.onShare,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.share,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // More options button
        GestureDetector(
          onTap: widget.onMore,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
