import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/routes.dart';
import '../../services/reels_service.dart';
import '../../widgets/upload/video_preview_widget.dart';
import '../../widgets/upload/upload_progress_widget.dart';
import '../../widgets/upload/duration_selector.dart';
import '../../widgets/upload/camera_view_widget.dart';

class UploadReelScreen extends StatefulWidget {
  const UploadReelScreen({super.key});

  @override
  State<UploadReelScreen> createState() => _UploadReelScreenState();
}

class _UploadReelScreenState extends State<UploadReelScreen> {
  String selectedDuration = '30s';
  File? _selectedVideo;
  double _progress = 0;
  bool _uploading = false;
  String _uploadStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Back button (top-left)
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  onTap: () => AppRoutes.goBack(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),

          // Main content area
          Positioned(
            top: 60,
            left: MediaQuery.of(context).size.width * 0.05, // 5% of screen width
            right: MediaQuery.of(context).size.width * 0.05, // 5% of screen width
            bottom: MediaQuery.of(context).size.height * 0.2, // 20% of screen height
            child: _selectedVideo != null
                ? VideoPreviewWidget(
                    videoFile: _selectedVideo!,
                    onConfirm: _confirmVideo,
                    onDiscard: _discardVideo,
                  )
                : CameraViewWidget(),
          ),

          // Duration selector
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2 + 5, // 20% + 5px
            left: 0,
            right: 0,
            child: DurationSelector(
              selectedDuration: selectedDuration,
              onDurationChanged: (duration) {
                setState(() {
                  selectedDuration = duration;
                });
              },
            ),
          ),

          // Bottom control bar
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1, // 10% of screen height
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.08, // 8% of screen height
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Effects button
                  _buildControlButton(
                    icon: Icons.auto_fix_high,
                    label: 'Effects',
                    onTap: _showEffects,
                  ),

                  // Record button
                  GestureDetector(
                    onTap: _captureFromCamera,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.15, // 15% of screen width
                      height: MediaQuery.of(context).size.width * 0.15, // 15% of screen width
                      decoration: BoxDecoration(
                        color: const Color(0xFF800080),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  // Upload button
                  _buildControlButton(
                    icon: Icons.upload,
                    label: 'Upload',
                    onTap: _showUploadDialog,
                  ),
                ],
              ),
            ),
          ),

          // POST button (only show when video is selected)
          if (_selectedVideo != null)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: GestureDetector(
                    onTap: _showPostDialog,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Upload progress overlay
          if (_uploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: UploadProgressWidget(
                    progress: _progress,
                    status: _uploadStatus,
                    isUploading: _uploading,
                    onCancel: _cancelUpload,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.12, // 12% of screen width
            height: MediaQuery.of(context).size.width * 0.12, // 12% of screen width
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: Duration(seconds: selectedDuration == '30s' ? 30 : 15),
    );
    if (picked != null) {
      setState(() {
        _selectedVideo = File(picked.path);
      });
    }
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Select Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: const Icon(Icons.video_library, color: Colors.white, size: 28),
                title: const Text(
                  'Choose from Gallery', 
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final picked = await picker.pickVideo(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() {
                      _selectedVideo = File(picked.path);
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            // Add safe area padding for smaller screens
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  void _confirmVideo(File videoFile) {
    setState(() {
      _selectedVideo = videoFile;
    });
  }

  void _discardVideo() {
    setState(() {
      _selectedVideo = null;
    });
  }

  void _showPostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Post Reel', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to post this reel?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadVideo();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800080)),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) return;

    setState(() {
      _uploading = true;
      _progress = 0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      // Get file info
      final fileSize = await _selectedVideo!.length();
      final contentType = 'video/mp4'; // Default for mobile videos

      // Step 1: Get presigned URL
      _updateStatus('Getting upload URL...', 0.1);
      final presignResult = await ReelsService.requestPresign(
        contentType: contentType,
        sizeBytes: fileSize,
      );
      if (!presignResult['success']) {
        throw Exception('Failed to get upload URL');
      }

      // Step 2: Upload to S3
      _updateStatus('Uploading video...', 0.2);
      await ReelsService.uploadToS3(
        uploadUrl: presignResult['uploadUrl'],
        file: _selectedVideo!,
        contentType: contentType,
        contentLength: fileSize,
        onProgress: (sent, total) {
          final progress = sent / total;
          _updateStatus('Uploading video...', 0.2 + (progress * 0.7));
        },
      );

      // Step 3: Finalize upload
      _updateStatus('Finalizing...', 0.9);
      await ReelsService.finalize(
        reelId: presignResult['reelId'],
        key: presignResult['key'],
        sizeBytes: fileSize,
      );

      // Success
      _updateStatus('Upload complete!', 1.0);
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/reel-home', arguments: {'showReelTab': false, 'myReels': [], 'videos': []});
      }
    } catch (e) {
      setState(() {
        _uploading = false;
        _uploadStatus = 'Upload failed: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    }
  }

  void _updateStatus(String status, double progress) {
    if (mounted) {
      setState(() {
        _uploadStatus = status;
        _progress = progress;
      });
    }
  }

  void _cancelUpload() {
    setState(() {
      _uploading = false;
      _progress = 0;
      _uploadStatus = '';
    });
  }

  void _showEffects() {
    // TODO: Implement effects
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Effects not implemented yet')),
    );
  }
}
