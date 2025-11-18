import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';

class TypingIndicator extends StatelessWidget {
  final AnimationController animationController;

  const TypingIndicator({
    super.key,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    if (!animationController.isAnimating) {
      animationController.repeat();
    }

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            try {
              final delay = index * 0.2;
              final animatedValue = ((animationController.value + delay) % 1.0);
              final opacity = animatedValue < 0.5 ? animatedValue * 2 : 2 - (animatedValue * 2);

              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
                child: Opacity(
                  opacity: 0.3 + (opacity * 0.7),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: MyColors.newPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            } catch (e) {
              // Fallback to static dots if animation fails
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: MyColors.newPrimary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
          }),
        );
      },
    );
  }
}

