import 'package:flutter/material.dart';

enum VideoLoadingState {
  unloaded,
  loading,
  ready,
  error,
}

class VideoLoadingIndicator extends StatelessWidget {
  final VideoLoadingState state;
  final String? errorMessage;
  final double size;
  final Color color;

  const VideoLoadingIndicator({
    super.key,
    required this.state,
    this.errorMessage,
    this.size = 50.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case VideoLoadingState.unloaded:
        return const SizedBox.shrink();
        
      case VideoLoadingState.loading:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 3.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
        
      case VideoLoadingState.ready:
        return const SizedBox.shrink();
        
      case VideoLoadingState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: color,
                size: size,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Failed to load video',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: Implement retry functionality
                },
                child: Text(
                  'Retry',
                  style: TextStyle(color: color),
                ),
              ),
            ],
          ),
        );
    }
  }
}
