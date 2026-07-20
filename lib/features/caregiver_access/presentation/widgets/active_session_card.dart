import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../domain/caregiver.dart';

class ActiveSessionCard extends StatelessWidget {
  final ActiveSession session;
  final VoidCallback onRevoke;

  const ActiveSessionCard({
    super.key,
    required this.session,
    required this.onRevoke,
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
      child: Row(
        children: [
          // Profile Avatar with colored ring representing status
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
              onBackgroundImageError: (exception, stackTrace) {
                // Fail-safe placeholder
              },
              child: session.imageUrl.isEmpty
                  ? const Icon(Icons.person, color: AppColors.primary)
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // Caregiver Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Dot status indicator
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
                        'Revoke',
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
    );
  }
}
