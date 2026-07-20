import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../provider/health_reports_provider.dart';

class ReportFilterTabs extends ConsumerWidget {
  const ReportFilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(healthReportsProvider).selectedFilter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FB), // Soft background for the filter pill
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTab(
                context,
                ref,
                label: 'Today',
                filterValue: ReportFilter.today,
                isActive: activeFilter == ReportFilter.today,
              ),
            ),
            Expanded(
              child: _buildTab(
                context,
                ref,
                label: 'Yesterday',
                filterValue: ReportFilter.yesterday,
                isActive: activeFilter == ReportFilter.yesterday,
              ),
            ),
            Expanded(
              child: _buildTab(
                context,
                ref,
                label: 'Last 7 Days',
                filterValue: ReportFilter.last7Days,
                isActive: activeFilter == ReportFilter.last7Days,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required ReportFilter filterValue,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          ref.read(healthReportsProvider.notifier).changeFilter(filterValue);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
