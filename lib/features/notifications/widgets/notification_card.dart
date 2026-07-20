import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/colors.dart';
import '../models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final Function(String) onDelete;
  final Function(String) onMarkRead;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
    required this.onMarkRead,
  });

  Color _getBgColor() {
    switch (notification.category.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFDE8E8); // light red
      case 'health':
        return const Color(0xFFFFF3CD); // light amber
      case 'sleep':
        return const Color(0xFFF3E8FF); // light purple
      case 'activity':
        return const Color(0xFFE1F8F5); // light green/teal
      case 'caregiver':
        return const Color(0xFFEBE3FC); // light lavender
      case 'reports':
        return const Color(0xFFE8F0FE); // light blue
      default:
        return const Color(0xFFF3F4F6); // light grey
    }
  }

  Color _getIconColor() {
    switch (notification.category.toLowerCase()) {
      case 'critical':
        return const Color(0xFFE02424); // dark red
      case 'health':
        return const Color(0xFFD97706); // amber
      case 'sleep':
        return const Color(0xFF7E3AF2); // dark purple
      case 'activity':
        return const Color(0xFF0E9F6E); // dark teal
      case 'caregiver':
        return const Color(0xFF6E3DE0); // brand purple
      case 'reports':
        return const Color(0xFF1A73E8); // dark blue
      default:
        return const Color(0xFF4B5563); // dark grey
    }
  }

  IconData _getIcon() {
    switch (notification.category.toLowerCase()) {
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'health':
        return Icons.thermostat_outlined;
      case 'sleep':
        return Icons.nights_stay_outlined;
      case 'activity':
        return Icons.directions_run_rounded;
      case 'caregiver':
        return Icons.people_outline_rounded;
      case 'reports':
        return Icons.assessment_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _getPriorityBadgeText() {
    switch (notification.priority.toLowerCase()) {
      case 'high':
        return 'CRITICAL';
      case 'medium':
        return 'MEDIUM';
      case 'low':
        return 'LOW';
      default:
        return 'NORMAL';
    }
  }

  Color _getPriorityBadgeColor() {
    switch (notification.priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE02424);
      case 'medium':
        return AppColors.primary;
      case 'low':
        return AppColors.textSecondary.withOpacity(0.6);
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Dismissible(
          key: Key(notification.id),
          // Swipe left (to delete)
          background: Container(
            color: const Color(0xFFFDE8E8),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Delete',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFE02424),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE02424),
                  size: 24,
                ),
              ],
            ),
          ),
          // Swipe right (to mark read)
          secondaryBackground: Container(
            color: const Color(0xFFEBE3FC),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(
                  Icons.mark_chat_read_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mark Read',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              // Swipe right-to-left: delete immediately
              onDelete(notification.id);
              return true;
            } else if (direction == DismissDirection.startToEnd) {
              // Swipe left-to-right: mark as read and bounce back
              onMarkRead(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${notification.title}" marked as read'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppColors.primary,
                ),
              );
              return false; // Slides back beautifully
            }
            return false;
          },
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.white
                    : const Color(0xFFFAF7FF),
                border: Border.all(
                  color: notification.isRead
                      ? AppColors.divider.withOpacity(0.5)
                      : AppColors.primary.withOpacity(0.12),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container with soft colored background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getBgColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(_getIcon(), color: _getIconColor(), size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text fields
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title & Priority Badge
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      notification.title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: notification.isRead
                                            ? FontWeight.bold
                                            : FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Priority Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPriorityBadgeColor()
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _getPriorityBadgeText(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: _getPriorityBadgeColor(),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Unread Indicator dot
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8, top: 4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTimestamp(notification.timestamp),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textSecondary.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Small category tag
                            Text(
                              '#${notification.category.toUpperCase()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppColors.primary.withOpacity(0.6),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
