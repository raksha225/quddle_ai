import 'package:flutter/material.dart';

class CameraViewWidget extends StatelessWidget {
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onEffectsTap;
  final bool showPlaceholder;

  const CameraViewWidget({
    super.key,
    this.onCameraTap,
    this.onGalleryTap,
    this.onEffectsTap,
    this.showPlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: showPlaceholder
          ? const Center(
              child: Text(
                'Camera View',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            )
          : const Center(
              child: Icon(
                Icons.videocam,
                color: Colors.white,
                size: 48,
              ),
            ),
    );
  }
}
