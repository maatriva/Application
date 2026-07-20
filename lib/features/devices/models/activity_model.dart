import 'package:flutter/material.dart';

class ActivityModel {
  final String id;
  final String title;
  final String description;
  final String timestamp;
  final IconData icon;
  final Color iconColor;

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
  });
}
