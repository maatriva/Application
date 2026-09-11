import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents caregiver permission settings.
class CaregiverPermission extends Equatable {
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

  @override
  List<Object?> get props => [id, title, description, icon, iconColor, iconBgColor];
}

/// Represents caregiver access session durations.
class CaregiverDuration extends Equatable {
  final String label;
  final Duration duration;
  final bool isCustom;

  const CaregiverDuration({
    required this.label,
    required this.duration,
    this.isCustom = false,
  });

  @override
  List<Object?> get props => [label, duration, isCustom];
}

enum SessionStatus { active, expiring, expired }

/// Represents an active caregiver delegation session.
class ActiveSession extends Equatable {
  final String id;
  final String name;
  final String relationship;
  final String imageUrl;
  final DateTime expiresAt;
  final SessionStatus status;
  final Map<String, bool>? permissions;
  final bool isOnline;
  final String? lastSeen;

  const ActiveSession({
    required this.id,
    required this.name,
    required this.relationship,
    required this.imageUrl,
    required this.expiresAt,
    required this.status,
    this.permissions,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now(),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.active,
      ),
      permissions: json['permissions'] != null
          ? Map<String, bool>.from(json['permissions'] as Map)
          : null,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'imageUrl': imageUrl,
      'expiresAt': expiresAt.toIso8601String(),
      'status': status.name,
      'permissions': permissions,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    };
  }

  ActiveSession copyWith({
    String? id,
    String? name,
    String? relationship,
    String? imageUrl,
    DateTime? expiresAt,
    SessionStatus? status,
    Map<String, bool>? permissions,
    bool? isOnline,
    String? lastSeen,
  }) {
    return ActiveSession(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      imageUrl: imageUrl ?? this.imageUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [id, name, relationship, imageUrl, expiresAt, status, permissions, isOnline, lastSeen];
}

/// Represents caregiver access history.
class AccessHistory extends Equatable {
  final String id;
  final String name;
  final String relationship;
  final String date;
  final String timeRange;
  final String durationText;
  final bool isExpired;
  final String status;
  final DateTime? timestamp;

  const AccessHistory({
    required this.id,
    required this.name,
    required this.relationship,
    required this.date,
    required this.timeRange,
    required this.durationText,
    this.isExpired = true,
    this.status = 'Completed',
    this.timestamp,
  });

  factory AccessHistory.fromJson(Map<String, dynamic> json) {
    DateTime? ts;
    if (json['timestamp'] != null) {
      ts = DateTime.tryParse(json['timestamp'] as String);
    } else if (json['grantedAt'] != null) {
      ts = DateTime.tryParse(json['grantedAt'] as String);
    } else if (json['createdAt'] != null) {
      ts = DateTime.tryParse(json['createdAt'] as String);
    }

    return AccessHistory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      date: json['date'] as String? ?? '',
      timeRange: json['timeRange'] as String? ?? '',
      durationText: json['durationText'] as String? ?? '',
      isExpired: json['isExpired'] as bool? ?? true,
      status: json['status'] as String? ?? 'Completed',
      timestamp: ts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'date': date,
      'timeRange': timeRange,
      'durationText': durationText,
      'isExpired': isExpired,
      'status': status,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  AccessHistory copyWith({
    String? id,
    String? name,
    String? relationship,
    String? date,
    String? timeRange,
    String? durationText,
    bool? isExpired,
    String? status,
    DateTime? timestamp,
  }) {
    return AccessHistory(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      date: date ?? this.date,
      timeRange: timeRange ?? this.timeRange,
      durationText: durationText ?? this.durationText,
      isExpired: isExpired ?? this.isExpired,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [id, name, relationship, date, timeRange, durationText, isExpired, status, timestamp];
}

