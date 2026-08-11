import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../../../shared/models/caregiver.dart';

class ActiveSessionCard extends StatelessWidget {
  final ActiveSession session;
  final VoidCallback onRevoke;
  final VoidCallback? onExtend;

  const ActiveSessionCard({
    super.key,
    required this.session,
    required this.onRevoke,
    this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    // Determine live remaining string and colors
    final now = DateTime.now();
    final remaining = session.expiresAt.difference(now);

    Color statusColor;
    String statusText;

    if (remaining.isNegative) {
      statusColor = const Color(0xFFE53935); // Red for Expired
      statusText = 'Expired';
    } else if (remaining.inMinutes <= 15) {
      statusColor = const Color(0xFFF57C00); // Orange for Expiring Soon
      statusText = 'Active Now • ${remaining.inMinutes}m left';
    } else if (remaining.inHours >= 18) {
      statusColor = const Color(0xFF2E7D32); // Green for Active
      statusText = 'Expires tomorrow';
    } else {
      statusColor = const Color(0xFF2E7D32); // Green for Active
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      statusText = 'Expiring in ${hours}h ${minutes}m';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.005),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.02),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Avatar with colored ring representing status
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.05),
                      backgroundImage: NetworkImage(session.imageUrl),
                      onBackgroundImageError: (exception, stackTrace) {},
                      child: session.imageUrl.isEmpty
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: session.isOnline ? const Color(0xFF4CAF50) : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Caregiver Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          session.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: session.isOnline
                                ? const Color(0xFFE8F5E9)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            session.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: session.isOnline ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Revoke Access Cross Button
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Revoke Caregiver Access?'),
                      content: Text(
                        'Are you sure you want to instantly revoke access for ${session.name}? Their secure token will be invalidated immediately.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onRevoke();
                          },
                          child: const Text(
                            'Revoke Access',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
                    color: const Color(0xFFFFEBEE),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFE53935),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          if (onExtend != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: onExtend,
                  icon: const Icon(Icons.more_time_rounded, size: 14),
                  label: const Text('Extend Access', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
