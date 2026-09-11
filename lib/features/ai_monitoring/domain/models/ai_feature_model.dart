import 'package:flutter/material.dart';

enum AiFeaturePriority { high, medium, low }

class AiFeatureModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String emoji;
  final String status;
  final Color statusColor;
  final AiFeaturePriority priority;
  final String category;
  final String analysis;
  final String detailedInsight;
  final Map<String, String> metrics;

  const AiFeatureModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.emoji,
    required this.status,
    required this.statusColor,
    required this.priority,
    required this.category,
    required this.analysis,
    required this.detailedInsight,
    required this.metrics,
  });

  String get priorityLabel {
    switch (priority) {
      case AiFeaturePriority.high:
        return 'High Priority';
      case AiFeaturePriority.medium:
        return 'Medium Priority';
      case AiFeaturePriority.low:
        return 'Low Priority';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case AiFeaturePriority.high:
        return const Color(0xFFE53935);
      case AiFeaturePriority.medium:
        return const Color(0xFFFB8C00);
      case AiFeaturePriority.low:
        return const Color(0xFF43A047);
    }
  }
}
