import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/reels_service.dart';
import 'package:share_plus/share_plus.dart';

class ReelOverlay extends StatefulWidget {
  final Map<String, dynamic> reelData;
  final Function(String reelId, bool isLiked, int newCount)? onLikeChanged;
  final Function(bool isMuted)? onMuteChanged;
  
  const ReelOverlay({
    super.key,
    required this.reelData,
    this.onLikeChanged,
    this.onMuteChanged,
  });

  @override
  State<ReelOverlay> createState() => _ReelOverlayState();
}

class _ReelOverlayState extends State<ReelOverlay> {
  // Local memory for like state
  bool _isLiked = false;
  int _likeCount = 0;
  
  // Local memory for mute state
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeLikeState();
  }


  void _initializeLikeState() {
    // Debug: Print the reel data to see what we're getting
    // print('ReelOverlay initialized with data: ${widget.reelData}');
    // print('isLikedByMe: ${widget.reelData['isLikedByMe']}');
    // print('likes_count: ${widget.reelData['likes_count']}');
    
    // Get starting values from reel data
    setState(() {
      _isLiked = widget.reelData['isLikedByMe'] ?? false;
      _likeCount = widget.reelData['likes_count'] ?? 0;
      _isMuted = false; // Each overlay starts unmuted
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // A gradient helps text stand out against varied video backgrounds.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.5),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0).copyWith(bottom: 100), // 80px for bottom nav + 20px extra
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Row for the main content (video info and action buttons)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left side: User info, caption, etc. 
                Expanded(
                  child: GestureDetector(
                    onTap: () {
        // Handle text area tap without affecting video playback
        // print('Text area tapped');
                      // Add your text area logic here (e.g., navigate to profile)
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@flutterdev',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: [Shadow(blurRadius: 2)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Streaming a cached HLS video in a Reels UI! #flutter #hls',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            shadows: [Shadow(blurRadius: 2)],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Right side: Action buttons
                Column(
                  children: [
                    _buildLikeButton(),
                    // _buildActionButton(icon: Icons.comment_rounded, label: '1,234'),
                    _buildActionButton(icon: Icons.share, label: 'Share'),
                    _buildMusicButton(),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: () async {
        // HAPTIC FEEDBACK: Provide tactile feedback on tap
        HapticFeedback.lightImpact();
        
        // OPTIMISTIC TAP: Update UI immediately without waiting for server
        setState(() {
          if (_isLiked) {
            // Currently liked -> unlike
            _isLiked = false;
            _likeCount = _likeCount - 1;
          } else {
            // Currently not liked -> like
            _isLiked = true;
            _likeCount = _likeCount + 1;
          }
        });
        
        print('Optimistic update - isLiked: $_isLiked, count: $_likeCount');
        
        // SYNC-TO-SERVER: Call API in background after UI update
        try {
          final reelId = widget.reelData['id'];
          if (reelId != null) {
            print('Syncing like to server...');
            final response = await ReelsService.likeReel(reelId);
            
            // SUCCESS: Update with server response
            setState(() {
              _likeCount = response['reel']['likes_count'] ?? _likeCount;
              _isLiked = response['reel']['isLikedByMe'] ?? _isLiked;
            });
            
            print('Updated state - _likeCount: $_likeCount, _isLiked: $_isLiked');
            
            // Notify parent widget about the like change
            if (widget.onLikeChanged != null) {
              widget.onLikeChanged!(reelId, _isLiked, _likeCount);
            }
            
            print('✅ Server sync completed - Final count: $_likeCount');
          }
        } catch (e) {
          print('Server sync failed: $e');
          
          // FAILURE: Revert optimistic update
          setState(() {
            _isLiked = !_isLiked; // Flip back to original state
            _likeCount = _isLiked ? _likeCount - 1 : _likeCount + 1; // Adjust count back
          });
          
          // Show error snackbar
          // if (mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(
          //       content: Text("Couldn't like post, please try again"),
          //       backgroundColor: Colors.red,
          //       duration: Duration(seconds: 3),
          //     ),
          //   );
          // }
        }
      },
      
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          children: [
            Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.white,
              size: 30,
            ),
            const SizedBox(height: 4),
            Text(
              _formatLikeCount(_likeCount),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label}) {
    return GestureDetector(
      onTap: () {
        // Handle button tap without affecting video playback
        // print('$label button tapped');
        
        // HAPTIC FEEDBACK: Provide tactile feedback on tap
        HapticFeedback.lightImpact();
        
        // Call share function for share button
        if (label == 'Share') {
          _shareReel();
        }
      },

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicButton() {
    return GestureDetector(
      onTap: () {
        // Handle music button tap
        // print('Music button tapped');
        
        // HAPTIC FEEDBACK: Provide tactile feedback on tap
        HapticFeedback.lightImpact();
        
        // Toggle mute state
        _toggleMute();
      },

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          
          children: [
            Icon(
              _isMuted ? Icons.music_off : Icons.music_note,
              color: _isMuted ? Colors.grey : Colors.white,
              size: 30,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 55, 
              height: 55,
              child: Center(
                child:  Text(
              _isMuted ? 'Unmute' : 'Music',
              style: TextStyle(
                color: _isMuted ? Colors.grey : Colors.white,
                fontSize: 12,
              ),
            ), 
              )
              
            ),
          ],
        ),
      ),
    );
  }

  String _formatLikeCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return count.toString();
    }
  }

  // Share function to share reel link
  Future<void> _shareReel() async {
    try {
      final reelId = widget.reelData['id'];
      if (reelId != null) {
        // Create shareable link - you can customize this URL structure
        final shareText = 'Check out this amazing reel on Quddle! 🎬\n\n';
        final shareUrl = 'https://quddle.ai/reel/$reelId'; // Replace with your actual domain
        final shareContent = '$shareText$shareUrl';
        
        // Try share_plus first, fallback to clipboard if it fails
        try {
          await Share.share(
            shareContent,
            subject: 'Amazing Reel on Quddle',
          );
          print('✅ Reel shared successfully: $reelId');
        } catch (shareError) {
          // print('⚠️ Share_plus failed, using clipboard fallback: $shareError');
          // Fallback: Copy to clipboard
          await _copyToClipboard(shareContent);
        }
      } else {
        print('❌ Cannot share: Reel ID not found');
      }
    } catch (e) {
      // print('❌ Share failed: $e');
      // Show error message to user
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text("Couldn't share reel, please try again"),
      //       backgroundColor: Colors.red,
      //       duration: Duration(seconds: 3),
      //     ),
      //   );
      // }
    }
  }

  // Fallback method to copy to clipboard
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Link copied to clipboard!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      print('✅ Link copied to clipboard');
    } catch (e) {
      print('❌ Clipboard failed: $e');
    }
  }


  // Toggle mute state
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    
    // Notify parent about mute state change
    widget.onMuteChanged?.call(_isMuted);
    
    // print('Music muted: $_isMuted');
  }
}
