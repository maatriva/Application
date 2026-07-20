import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../domain/health_report_data.dart';

class TimelineWidget extends StatelessWidget {
  final List<TimelineEvent> events;

  const TimelineWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No timeline events logged today.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isFirst = index == 0;
        final isLast = index == events.length - 1;

        return TimelineTile(
          time: event.time,
          activity: event.activity,
          isFirst: isFirst,
          isLast: isLast,
        );
      }),
    );
  }
}

class TimelineTile extends StatelessWidget {
  final String time;
  final String activity;
  final bool isFirst;
  final bool isLast;

  const TimelineTile({
    super.key,
    required this.time,
    required this.activity,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Node Indicator Column (Line & Circle)
          Column(
            children: [
              // Top line segment
              Container(
                width: 2.5,
                height: 12,
                color: isFirst ? Colors.transparent : const Color(0xFFC7B1F7),
              ),
              // Circle Node
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFirst
                      ? const Color(0xFF8855EC)
                      : const Color(0xFFBCA5FB),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // Bottom line segment
              Expanded(
                child: Container(
                  width: 2.5,
                  color: isLast ? Colors.transparent : const Color(0xFFC7B1F7),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Content Details on the right
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
