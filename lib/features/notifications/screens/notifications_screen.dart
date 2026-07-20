import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_card.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late final TextEditingController _searchController;
  final List<String> _filters = [
    'All',
    'Critical',
    'Health',
    'Sleep',
    'Activity',
    'Caregiver',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<NotificationModel>> _groupNotifications(
    List<NotificationModel> list,
  ) {
    final Map<String, List<NotificationModel>> groups = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    for (final notif in list) {
      if (notif.timestamp.isAfter(todayStart)) {
        groups['Today']!.add(notif);
      } else if (notif.timestamp.isAfter(yesterdayStart)) {
        groups['Yesterday']!.add(notif);
      } else {
        groups['Earlier']!.add(notif);
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final filteredList = state.filteredNotifications;
    final grouped = _groupNotifications(filteredList);

    final showEmptyState = filteredList.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Mark all as read button
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () {
                notifier.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All notifications marked as read'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                'Mark all read',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          // Filter Icon indicator
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: state.selectedCategory != 'All'
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 24,
              ),
              onPressed: () {
                // Quick reset filters helper
                if (state.selectedCategory != 'All') {
                  notifier.setCategory('All');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Use the chips below to filter notification types!',
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Search bar & Chips panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                // Search Input Field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        notifier.setSearchQuery(val);
                      },
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search notifications',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Horizontally Scrollable Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = state.selectedCategory == filter;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            notifier.setCategory(filter);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        Color(0xFF8B5CF6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : AppColors.background,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.divider.withOpacity(0.8),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: showEmptyState
                ? _buildEmptyState(context, state, notifier)
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      // Today's Group
                      if (grouped['Today']!.isNotEmpty) ...[
                        _buildGroupHeader('Today'),
                        ...grouped['Today']!.map(
                          (notif) => _buildCard(notif, notifier),
                        ),
                      ],

                      // Yesterday's Group
                      if (grouped['Yesterday']!.isNotEmpty) ...[
                        _buildGroupHeader('Yesterday'),
                        ...grouped['Yesterday']!.map(
                          (notif) => _buildCard(notif, notifier),
                        ),
                      ],

                      // Earlier Group
                      if (grouped['Earlier']!.isNotEmpty) ...[
                        _buildGroupHeader('Earlier'),
                        ...grouped['Earlier']!.map(
                          (notif) => _buildCard(notif, notifier),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: AppColors.textSecondary.withOpacity(0.8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(NotificationModel notif, NotificationsNotifier notifier) {
    return NotificationCard(
      key: ValueKey(notif.id),
      notification: notif,
      onTap: () {
        // Mark as read immediately on open
        notifier.markAsRead(notif.id);

        // Push details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationDetailScreen(notification: notif),
          ),
        );
      },
      onDelete: (id) {
        notifier.deleteNotification(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                notifier.resetNotifications();
              },
            ),
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onMarkRead: (id) {
        notifier.markAsRead(id);
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    NotificationsState state,
    NotificationsNotifier notifier,
  ) {
    final hasActiveFilter =
        state.selectedCategory != 'All' || state.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Styled illustration / visual icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  hasActiveFilter
                      ? Icons.search_off_rounded
                      : Icons.notifications_none_rounded,
                  color: AppColors.primary.withOpacity(0.4),
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasActiveFilter
                  ? 'No matching notifications'
                  : 'No notifications yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilter
                  ? 'Try modifying your search queries or resetting category chips.'
                  : 'We\'ll notify you whenever Emma needs attention or new health insights are ready.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (hasActiveFilter) {
                  _searchController.clear();
                  notifier.setSearchQuery('');
                  notifier.setCategory('All');
                } else {
                  context.go('/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                hasActiveFilter ? 'Clear Filters' : 'Return Home',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            // Reset simulation button for testing
            if (!hasActiveFilter) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  notifier.resetNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Simulated notifications reset!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Text(
                  'Restore Mock Notifications',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Support extension for Color.fromHex style values used inside linter
extension ColorExtension on Colors {
  static const Color blackDE = Color(0xFF212121);
}
