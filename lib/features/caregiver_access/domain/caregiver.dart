import 'package:flutter/material.dart';

class CaregiverPermission {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const CaregiverPermission({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class CaregiverDuration {
  final String label;
  final Duration duration;
  final bool isCustom;

  const CaregiverDuration({
    required this.label,
    required this.duration,
    this.isCustom = false,
  });
}

enum SessionStatus { active, expiring, expired }

class ActiveSession {
  final String id;
  final String name;
  final String relationship;
  final String imageUrl;
  final DateTime expiresAt;
  final SessionStatus status;

  ActiveSession({
    required this.id,
    required this.name,
    required this.relationship,
    required this.imageUrl,
    required this.expiresAt,
    required this.status,
  });

  ActiveSession copyWith({
    String? id,
    String? name,
    String? relationship,
    String? imageUrl,
    DateTime? expiresAt,
    SessionStatus? status,
  }) {
    return ActiveSession(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      imageUrl: imageUrl ?? this.imageUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
    );
  }
}

class AccessHistory {
  final String id;
  final String name;
  final String relationship;
  final String date;
  final String timeRange;
  final String durationText;
  final bool isExpired;

  const AccessHistory({
    required this.id,
    required this.name,
    required this.relationship,
    required this.date,
    required this.timeRange,
    required this.durationText,
    this.isExpired = true,
  });
}
