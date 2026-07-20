import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/status_chip.dart';
import '../widgets/live_camera_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/app_drawer.dart';
import '../../../live_monitoring/presentation/screens/live_monitoring_screen.dart';
import '../../../onboarding/providers/onboarding_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentNavIndex;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingState = ref.read(onboardingProvider);
      if (!onboardingState.isCompleted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentNavIndex == 0 ? const DashboardHeader() : null,
      drawer: const AppDrawer(),
      body: _buildBody(metrics),

      // Soft Glow Floating Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            context.push('/ai-assistant');
          },
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 0,
          child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 28),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 2) {
            context.push('/predictive-health');
          } else if (index == 3) {
            context.push('/shop');
          } else {
            setState(() {
              _currentNavIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildBody(BabyMetrics metrics) {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeBody(metrics);
      case 1:
        return const LiveMonitoringScreen();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _currentNavIndex == 2
                    ? Icons.shopping_bag_outlined
                    : Icons.person_outline_rounded,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                _currentNavIndex == 2
                    ? 'Shop Coming Soon'
                    : 'Profile Coming Soon',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildHomeBody(BabyMetrics metrics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mother Welcome Section
          GreetingSection(
            motherName: metrics.motherName,
            babyStatus: metrics.babyStatus,
          ),
          const SizedBox(height: 20),

          // Horizontal Status Pill Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                StatusChip.sleeping(
                  onTap: () {
                    // Actionable Status: Tap sleeping chip to toggle/simulate baby alert
                    final nextStatus = metrics.babyStatus == 'Sleeping'
                        ? 'Awake'
                        : 'Sleeping';
                    ref
                        .read(dashboardProvider.notifier)
                        .updateBabyStatus(nextStatus);
                    ref.read(dashboardProvider.notifier).refreshAIInsight();
                  },
                ),
                const SizedBox(width: 8),
                StatusChip.healthy(),
                const SizedBox(width: 8),
                StatusChip.connected(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Baby Status Widescreen Stream
          Text('Baby Status', style: AppTypography.sectionTitle),
          const SizedBox(height: 12),
          const LiveCameraCard(),
          const SizedBox(height: 28),

          // Section 2: Today's Summary Biometrics Grid
          Text("Today's Summary", style: AppTypography.sectionTitle),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              SummaryCard(
                label: 'Temperature',
                value: '${metrics.temperature.toInt()}',
                unit: '°C',
                icon: Icons.thermostat_outlined,
                iconBgColor: AppColors.tempBg,
                iconColor: AppColors.tempIcon,
              ),
              SummaryCard(
                label: 'Heart Rate',
                value: '${metrics.heartRate}',
                unit: 'bpm',
                icon: Icons.favorite_border_rounded,
                iconBgColor: AppColors.heartBg,
                iconColor: AppColors.heartIcon,
              ),
              SummaryCard(
                label: 'Sleep',
                value: '${metrics.sleepHours}',
                unit: 'hrs',
                icon: Icons.nights_stay_outlined,
                iconBgColor: AppColors.sleepProgressBg,
                iconColor: AppColors.sleepProgressIcon,
              ),
              SummaryCard(
                label: 'Cry Count',
                value: '${metrics.cryCount}',
                unit: '',
                icon: Icons.face_retouching_natural_outlined,
                iconBgColor: AppColors.cryBg,
                iconColor: AppColors.cryIcon,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Section 3: Smart AI Insights summary
          AIInsightCard(
            insight: metrics.aiInsight,
            isLoading: metrics.isLoadingInsight,
            onRefresh: () {
              ref.read(dashboardProvider.notifier).refreshAIInsight();
            },
          ),
          const SizedBox(height: 28),

          // Section 4: Quick Actions Grid (3-column layout)
          Text('Quick Actions', style: AppTypography.sectionTitle),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: [
              QuickActionButton(
                icon: Icons.videocam_outlined,
                label: 'Live',
                onTap: () {
                  setState(() {
                    _currentNavIndex = 1;
                  });
                },
              ),
              QuickActionButton(
                icon: Icons.smart_toy_outlined,
                label: 'AI Assistant',
                onTap: () {
                  context.push('/ai-assistant');
                },
              ),
              QuickActionButton(
                icon: Icons.favorite_border_rounded,
                label: 'Predictive Health',
                onTap: () {
                  context.push('/predictive-health');
                },
              ),
              QuickActionButton(
                icon: Icons.medical_services_outlined,
                label: 'Doctor',
                onTap: () {},
              ),
              QuickActionButton(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: () {
                  context.push('/caregiver-access');
                },
              ),
              QuickActionButton(
                icon: Icons.music_note_outlined,
                label: 'Music',
                onTap: () {
                  context.push('/music');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
