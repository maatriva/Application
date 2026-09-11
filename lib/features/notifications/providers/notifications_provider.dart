import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/providers.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final String
  selectedCategory; // 'All', 'Critical', 'Health', 'Sleep', 'Activity', 'Caregiver', 'Reports'
  final String searchQuery;
  final bool isLoading;

  const NotificationsState({
    required this.notifications,
    required this.selectedCategory,
    required this.searchQuery,
    required this.isLoading,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    String? selectedCategory,
    String? searchQuery,
    bool? isLoading,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Helper getter to retrieve filtered and searched notifications
  List<NotificationModel> get filteredNotifications {
    var list = notifications;

    // Filter by Category
    if (selectedCategory != 'All') {
      final String targetCat = selectedCategory.toLowerCase();
      list = list.where((n) => n.category.toLowerCase() == targetCat).toList();
    }

    // Filter by Search Query
    if (searchQuery.isNotEmpty) {
      final String query = searchQuery.toLowerCase();
      list = list
          .where(
            (n) =>
                n.title.toLowerCase().contains(query) ||
                n.description.toLowerCase().contains(query),
          )
          .toList();
    }

    // Sort by timestamp descending (newest first)
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // Get total unread count
  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final WebSocketService _wsService;
  StreamSubscription? _alertSubscription;

  NotificationsNotifier({required WebSocketService wsService})
    : _wsService = wsService,
      super(
        const NotificationsState(
          notifications: [],
          selectedCategory: 'All',
          searchQuery: '',
          isLoading: false,
        ),
      ) {
    _subscribeToAlerts();
  }

  void _subscribeToAlerts() {
    _alertSubscription = _wsService.alertStream.listen((alertData) {
      final alert = alertData['alert'] as Map<String, dynamic>? ?? alertData;

      final id = alert['id'] ?? alert['alertId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      final severity = alert['severity'] as String? ?? 'warning';
      final type = alert['type'] as String? ?? 'general';
      final message = alert['message'] as String? ?? 'Safety warning triggered.';
      final value = alert['value'] as num?;
      final thresholdLimit = alert['thresholdLimit'] as num?;
      final deviceId = alert['deviceId'] as String? ?? '';

      final notification = NotificationModel(
        id: id,
        title: type.toUpperCase() == 'CRY_DETECTED'
            ? 'Baby Cry Detected'
            : 'Alert: ${type.toUpperCase().replaceAll('_', ' ')}',
        description: message,
        timestamp: DateTime.now(),
        category: _mapTypeToCategory(type),
        priority: _mapSeverityToPriority(severity),
        deviceResponsible: deviceId,
        sensorResponsible: type,
        detailedExplanation: message,
        recommendedAction: 'Please check the cradle and baby immediately.',
        aiInsight: value != null && thresholdLimit != null
            ? 'This critical alert was generated because the parsed metric for $type reached $value, breaching the safe threshold configuration of $thresholdLimit.'
            : 'Immediate action is required as safety thresholds have been exceeded.',
      );

      // 1. Add alert to local list
      state = state.copyWith(
        notifications: [notification, ...state.notifications],
      );

      // 2. Show in-app notification banner
      _showInAppNotificationBanner(severity, message);
    });
  }

  String _mapTypeToCategory(String type) {
    type = type.toLowerCase();
    if (type.contains('heart') || type.contains('breath') || type.contains('temp')) return 'health';
    if (type.contains('sleep')) return 'sleep';
    if (type.contains('motion') || type.contains('movement')) return 'activity';
    if (type.contains('cry')) return 'critical';
    return 'health';
  }

  String _mapSeverityToPriority(String severity) {
    severity = severity.toLowerCase();
    if (severity == 'emergency' || severity == 'danger' || severity == 'high') return 'high';
    if (severity == 'warning') return 'medium';
    return 'low';
  }

  void _showInAppNotificationBanner(String severity, String message) {
    final sev = severity.toLowerCase();
    final bgColor = (sev == 'emergency' || sev == 'high')
        ? const Color(0xFFFFEBEE)
        : sev == 'danger'
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFE8F5E9);
    final borderColor = (sev == 'emergency' || sev == 'high')
        ? const Color(0xFFEF5350)
        : sev == 'danger'
            ? const Color(0xFFFFB74D)
            : const Color(0xFF81C784);
    final textColor = (sev == 'emergency' || sev == 'high')
        ? const Color(0xFFC62828)
        : sev == 'danger'
            ? const Color(0xFFE65100)
            : const Color(0xFF2E7D32);
    final icon = (sev == 'emergency' || sev == 'high')
        ? Icons.emergency_share_rounded
        : sev == 'danger'
            ? Icons.warning_amber_rounded
            : Icons.info_outline_rounded;

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sev.toUpperCase()} ALERT',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        color: textColor.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void markAsRead(String id) {
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList(),
    );
  }

  void markAsUnread(String id) {
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: false);
        }
        return n;
      }).toList(),
    );
  }

  void markAllAsRead() {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(),
    );
  }

  void deleteNotification(String id) {
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetNotifications() {
    state = state.copyWith(notifications: []);
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      final wsService = ref.watch(webSocketServiceProvider);
      return NotificationsNotifier(wsService: wsService);
    });
