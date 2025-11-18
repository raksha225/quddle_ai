import 'package:flutter/material.dart';

class DurationSelector extends StatefulWidget {
  final String selectedDuration;
  final Function(String) onDurationChanged;
  final List<String> availableDurations;

  const DurationSelector({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
    this.availableDurations = const ['15s', '30s'],
  });

  @override
  State<DurationSelector> createState() => _DurationSelectorState();
}

class _DurationSelectorState extends State<DurationSelector> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.availableDurations.map((duration) {
        final isSelected = duration == widget.selectedDuration;
        return GestureDetector(
          onTap: () => widget.onDurationChanged(duration),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF800080) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF800080) 
                    : Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              duration,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
