import 'package:flutter/material.dart';

class ReelDescription extends StatelessWidget {
  final String? description;
  final List<String>? hashtags;
  final VoidCallback? onTap;
  final int maxLines;
  final TextStyle? textStyle;

  const ReelDescription({
    super.key,
    this.description,
    this.hashtags,
    this.onTap,
    this.maxLines = 3,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
    );

    final style = textStyle ?? defaultStyle;

    if (description == null && (hashtags == null || hashtags!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (description != null && description!.isNotEmpty)
            Text(
              description!,
              style: style,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          
          // Hashtags
          if (hashtags != null && hashtags!.isNotEmpty) ...[
            if (description != null && description!.isNotEmpty)
              const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: hashtags!.map((hashtag) {
                return Text(
                  '#$hashtag',
                  style: style.copyWith(
                    color: Colors.blue[300],
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
