import 'package:flutter/material.dart';
import '../constants/colors.dart';

class NewStyles {
  NewStyles._();

  /// Segmented Control Widget
  /// A reusable segmented control with sliding animation
  static Widget segmentedControl({
    required BuildContext context,
    required String selectedValue,
    required List<String> options,
    required List<String> values,
    required Function(String) onValueChanged,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MyColors.bgscaffold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final containerWidth = constraints.maxWidth;
          final segmentWidth = (containerWidth - 8) / options.length;
          final selectedIndex = values.indexOf(selectedValue);

          return Stack(
            children: [
              // Sliding indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: 4 + (selectedIndex * segmentWidth),
                top: 0,
                bottom: 0,
                child: Container(
                  width: segmentWidth - 4,
                  decoration: BoxDecoration(
                    color: MyColors.whitebox,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Options row
              Row(
                children: List.generate(
                  options.length,
                  (index) => Expanded(
                    child: _buildSegmentOption(
                      context,
                      options[index],
                      values[index],
                      selectedValue,
                      onValueChanged,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildSegmentOption(
    BuildContext context,
    String label,
    String value,
    String selectedValue,
    Function(String) onValueChanged,
  ) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onValueChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? MyColors.primary : Colors.grey[700],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

