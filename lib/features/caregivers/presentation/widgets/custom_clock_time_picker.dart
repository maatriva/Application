import 'package:flutter/material.dart';
import 'flip_clock_duration_selector.dart';

/// Legacy Time Picker bridge redirecting callers to the new Premium Flip Clock Duration Selector Modal.
class CustomClockTimePicker extends StatelessWidget {
  final String initialDurationLabel;
  final ValueChanged<String> onTimeSelected;

  const CustomClockTimePicker({
    super.key,
    required this.initialDurationLabel,
    required this.onTimeSelected,
  });

  static Future<String?> show(
    BuildContext context, {
    required String initialLabel,
    required ValueChanged<String> onTimeSelected,
  }) {
    return FlipClockDurationSelectorModal.show(
      context,
      initialLabel: initialLabel,
      title: 'SELECT ACCESS DURATION',
      onDurationSelected: onTimeSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlipClockDurationSelector(
      initialDurationLabel: initialDurationLabel,
      onDurationChanged: onTimeSelected,
      showConfirmButton: true,
    );
  }
}
