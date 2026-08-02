import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ControlButtonsWidget extends StatelessWidget {
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final bool isStreaming;

  const ControlButtonsWidget({
    super.key,
    required this.onStart,
    required this.onStop,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Start Streaming Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isStreaming ? null : onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF4A3B5C),
              disabledForegroundColor: const Color(0xFF7B6F8C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isStreaming ? 0 : 4,
              shadowColor: AppColors.primary.withOpacity(0.3),
            ),
            child: const Text(
              'Start Streaming',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Stop Streaming Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: isStreaming ? onStop : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: const Color(0xFF554B64),
              side: BorderSide(
                color: isStreaming ? const Color(0xFFD32F2F) : const Color(0xFF322842),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: isStreaming ? const Color(0xFFD32F2F).withOpacity(0.1) : Colors.transparent,
            ),
            child: Text(
              'Stop Streaming',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isStreaming ? const Color(0xFFFF5252) : const Color(0xFF554B64),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
