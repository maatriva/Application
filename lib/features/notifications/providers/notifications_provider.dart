import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../data/mock_notifications.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final String
  selectedCategory; // 'All', 'Critical', 'Health', 'Sleep', 'Activity', 'Caregiver', 'Reports'
  final String searchQuery;
  final bool isLoading;

  NotificationsState({
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
  NotificationsNotifier()
    : super(
        NotificationsState(
          notifications: List.from(initialMockNotifications),
          selectedCategory: 'All',
          searchQuery: '',
          isLoading: false,
        ),
      );

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
    state = state.copyWith(notifications: List.from(initialMockNotifications));
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      return NotificationsNotifier();
    });
