import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/services/providers.dart';
import '../../../../shared/models/vitals_telemetry.dart';
import '../../../../shared/models/user_session.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../onboarding/providers/onboarding_provider.dart';
import '../../../monitoring/presentation/screens/live_monitoring_screen.dart';
import '../../../../shared/widgets/bottom_navigation.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/baby_status_hero_card.dart';
import '../widgets/wellness_section.dart';
import '../widgets/smart_cradle_card.dart';
import '../widgets/caregiver_status_card.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/quick_action_button.dart';
import '../../../caregivers/provider/caregiver_access_provider.dart';
import '../../../../shared/models/caregiver.dart';

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
    _currentNavIndex = widget.initialTab == 1 ? 2 : widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingState = ref.read(onboardingProvider);
      if (!onboardingState.isCompleted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      setState(() {
        _currentNavIndex = widget.initialTab == 1 ? 2 : widget.initialTab;
      });
    }
  }

  String calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final months = (difference.inDays / 30.4).floor();
    if (months < 1) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks weeks old';
    }
    if (months >= 12) {
      final years = (months / 12).floor();
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years year${years > 1 ? 's' : ''} old';
      }
      return '$years yr $remainingMonths mo old';
    }
    return '$months months old';
  }

  String formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inSeconds < 60) {
      return 'just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  String formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  String getBabyStatus(Map<String, VitalsTelemetry>? telemetry) {
    if (telemetry == null) return 'Awake';
    final cryVal = telemetry['cry_detection']?.value ?? 0.0;
    if (cryVal > 0) return 'Crying';
    final sleepVal = telemetry['sleep_stage']?.value ?? 0.0;
    if (sleepVal > 0) return 'Sleeping';
    return 'Awake';
  }

  String getAIInsight(DashboardState state) {
    if (state.latestTelemetry == null) {
      return 'Waiting for active telemetry to analyze baby care sleep patterns.';
    }
    final hr = state.latestTelemetry!['heart_rate']?.value.toInt() ?? 0;
    final temp = state.latestTelemetry!['body_temperature']?.value ?? 0.0;
    final cry = state.latestTelemetry!['cry_detection']?.value ?? 0.0;
    final status = cry > 0 ? 'crying' : (state.latestTelemetry!['sleep_stage']?.value ?? 0) > 0 ? 'sleeping' : 'awake';
    
    return 'Your baby is currently $status. Heart rate is $hr bpm and body temperature is ${temp.toStringAsFixed(1)}°C. Ambient nursery parameters are looking optimal for growth.';
  }

  void _showRestrictedAccessDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 24.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You don\'t have permission to access $featureName.\n\nAs a Caregiver, your authorized access includes:\n• Live Video Monitoring\n• Live Sensor Telemetry\n• Alerts & Notifications\n• In-App Online Music',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final baby = ref.watch(dashboardProvider.select((s) => s.baby));
    final isCaregiver = authState.session?.role == UserRole.caregiver;

    final cacheService = ref.watch(cacheServiceProvider);
    final caregiverSession = cacheService.getCaregiverGrantedSession();
    final perms = (caregiverSession?['permissions'] as Map<String, dynamic>?) ?? {};
    final bool permsHealth = !isCaregiver || (perms['health_data'] == true);
    final bool permsAi = !isCaregiver || (perms['ai_assistant'] == true);

    final isLiveMonitorOnly = (isCaregiver && !permsHealth) || baby?.accessLevel == 'LIVE_MONITOR_ONLY';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentNavIndex == 0 ? const DashboardHeader() : null,
      drawer: const AppDrawer(),
      body: _buildBody(isLiveMonitorOnly, isCaregiver),
      floatingActionButton: (!isCaregiver || permsAi)
          ? Container(
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
                onPressed: () => context.push('/ai-assistant'),
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 0,
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() {
              _currentNavIndex = 0;
            });
            context.go('/?tab=0');
          } else if (index == 1) {
            context.go('/predictive-health');
          } else if (index == 2) {
            setState(() {
              _currentNavIndex = 2;
            });
            context.go('/?tab=1');
          } else if (index == 3) {
            setState(() {
              _currentNavIndex = 3;
            });
            context.go('/music');
          } else if (index == 4) {
            setState(() {
              _currentNavIndex = 4;
            });
            context.go('/shop');
          }
        },
      ),
    );
  }

  Widget _buildBody(bool isLiveMonitorOnly, bool isCaregiver) {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeBody(isLiveMonitorOnly, isCaregiver);
      case 2:
        return const LiveMonitoringScreen();
      default:
        return _buildHomeBody(isLiveMonitorOnly, isCaregiver);
    }
  }

  Widget _buildHomeBody(bool isLiveMonitorOnly, bool isCaregiver) {
    final isLoading = ref.watch(dashboardProvider.select((s) => s.isLoading));
    if (isLoading) {
      return _buildSkeletonLoader();
    }

    final baby = ref.watch(dashboardProvider.select((s) => s.baby));
    if (isCaregiver && baby == null) {
      final errorMessage = ref.watch(dashboardProvider.select((s) => s.errorMessage));
      return _buildEmptyState(
        title: 'Join Shared Baby',
        icon: Icons.qr_code_scanner_rounded,
        message: (errorMessage != null && errorMessage.isNotEmpty)
            ? errorMessage
            : 'Caregiver access is currently inactive or revoked. Scan the QR code generated on the parent\'s device to monitor.',
        actionLabel: 'Scan QR Code',
        onActionPressed: () {
          final authState = ref.read(authNotifierProvider);
          if (authState.status != AuthStatus.authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please log in / authorize first to scan QR code.')),
            );
            context.push('/login');
          } else {
            context.push('/join-shared-baby');
          }
        },
      );
    }

    final errorMessage = ref.watch(dashboardProvider.select((s) => s.errorMessage));
    if (errorMessage != null) {
      if (isCaregiver) {
        return _buildEmptyState(
          title: 'Join Shared Baby',
          icon: Icons.qr_code_scanner_rounded,
          message: errorMessage,
          actionLabel: 'Scan QR Code',
          onActionPressed: () {
            final authState = ref.read(authNotifierProvider);
            if (authState.status != AuthStatus.authenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please log in / authorize first to scan QR code.')),
              );
              context.push('/login');
            } else {
              context.push('/join-shared-baby');
            }
          },
        );
      }
      return _buildErrorState(errorMessage);
    }

    if (baby == null) {
      return _buildEmptyState(
        title: 'Register Your Baby',
        icon: Icons.baby_changing_station_rounded,
        message: 'Please add a baby profile to start smart monitoring.',
        actionLabel: 'Register Your Baby',
        onActionPressed: () {
          ref.read(onboardingProvider.notifier).nextStep(OnboardingStep.babyRegister);
          context.go('/onboarding');
        },
      );
    }

    final parentName = ref.watch(dashboardProvider.select((s) => s.profile?.parentName)) ?? 'Parent';

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final actionsCrossAxisCount = isTablet ? 6 : 3;
    final actionsChildAspectRatio = isTablet ? 1.25 : 1.05;

    final cacheService = ref.watch(cacheServiceProvider);
    final caregiverSession = cacheService.getCaregiverGrantedSession();
    final perms = (caregiverSession?['permissions'] as Map<String, dynamic>?) ?? {};
    final bool permsCamera = !isCaregiver || (perms['camera_snapshot'] == true);
    final bool permsMusic = !isCaregiver || (perms['custom_music'] == true || perms['music'] == true);
    final bool permsAi = !isCaregiver || (perms['ai_assistant'] == true);
    final bool permsHealth = !isCaregiver || (perms['health_data'] == true);
    final bool permsCradle = !isCaregiver || (perms['cradle_controls'] == true);

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      color: AppColors.royalBlue,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 12.h, bottom: 110.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Greeting Header Subtitle
            Consumer(
              builder: (context, ref, child) {
                final telemetry = ref.watch(dashboardProvider.select((s) => s.latestTelemetry));
                final babyStatus = getBabyStatus(telemetry);
                final authState = ref.watch(authNotifierProvider);
                final isCaregiverUser = isCaregiver || authState.session?.role == UserRole.caregiver;
                
                final cacheService = ref.watch(cacheServiceProvider);
                final caregiverSession = cacheService.getCaregiverGrantedSession();
                DateTime? expiresAt;
                if (caregiverSession != null && caregiverSession['expiresAt'] != null) {
                  expiresAt = DateTime.tryParse(caregiverSession['expiresAt'] as String);
                }

                return GreetingSection(
                  motherName: parentName,
                  babyStatus: babyStatus,
                  isCaregiver: isCaregiverUser,
                  expiresAt: expiresAt,
                );
              },
            ),
            SizedBox(height: 16.h),

            // 2. Baby Status Hero Card ("Is my baby okay?")
            Consumer(
              builder: (context, ref, child) {
                final telemetry = ref.watch(dashboardProvider.select((s) => s.latestTelemetry));
                return BabyStatusHeroCard(
                  baby: baby,
                  telemetry: telemetry,
                  onTap: isLiveMonitorOnly ? null : () => context.push('/predictive-health'),
                );
              },
            ),
            SizedBox(height: 24.h),

            // 3. Caregiver Access Banner / Timer (only shown if caregiver active or caregiver user)
            Consumer(
              builder: (context, ref, child) {
                final cacheService = ref.watch(cacheServiceProvider);
                final caregiverSession = cacheService.getCaregiverGrantedSession();
                DateTime? expiresAt;
                if (caregiverSession != null && caregiverSession['expiresAt'] != null) {
                  expiresAt = DateTime.tryParse(caregiverSession['expiresAt'] as String);
                }

                final caregiverState = ref.watch(caregiverAccessProvider);
                final now = DateTime.now().add(caregiverState.serverClockOffset);
                final activeSessions = caregiverState.activeSessions
                    .where((s) =>
                        s.status != SessionStatus.expired &&
                        s.expiresAt.isAfter(now))
                    .toList();
                final activeCaregiverName = activeSessions.isNotEmpty ? activeSessions.first.name : null;
                final activeSessionId = activeSessions.isNotEmpty ? activeSessions.first.id : null;

                if (!isCaregiver && (activeCaregiverName == null || activeCaregiverName.trim().isEmpty)) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: CaregiverStatusCard(
                    isCaregiver: isCaregiver,
                    expiresAt: expiresAt,
                    activeCaregiverName: activeCaregiverName,
                    activeSessionId: activeSessionId,
                    onLogoutExpired: () {
                      ref.read(authNotifierProvider.notifier).logout();
                    },
                  ),
                );
              },
            ),

            // 4. Baby's Wellness Section (4 Claymorphic Metric Cards)
            if (!isCaregiver || permsHealth) ...[
              Consumer(
                builder: (context, ref, child) {
                  final telemetry = ref.watch(dashboardProvider.select((s) => s.latestTelemetry));
                  return WellnessSection(
                    telemetry: telemetry,
                    isRestricted: isLiveMonitorOnly,
                  );
                },
              ),
              SizedBox(height: 24.h),
            ],

            // 5. Smart Cradle Card (Status, Rocking switch, Music shortcut, Vector cradle visual)
            if (!isCaregiver || permsCradle) ...[
              Consumer(
                builder: (context, ref, child) {
                  final device = ref.watch(dashboardProvider.select((s) => s.device));
                  return SmartCradleCard(
                    device: device,
                    isRestricted: isLiveMonitorOnly,
                  );
                },
              ),
              SizedBox(height: 24.h),
            ],

            // 6. Maatriva AI Insight Card
            if (!isCaregiver || permsAi) ...[
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(dashboardProvider);
                  return AIInsightCard(
                    insight: getAIInsight(state),
                    isLoading: false,
                    onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
                  );
                },
              ),
              SizedBox(height: 24.h),
            ],

            // 7. Quick Actions Grid
            Text('Quick Actions', style: AppTypography.sectionTitle),
            SizedBox(height: 12.h),
            GridView.count(
              crossAxisCount: actionsCrossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: actionsChildAspectRatio,
              children: [
                if (!isCaregiver || permsCamera)
                  QuickActionButton(
                    icon: Icons.videocam_outlined,
                    label: 'Live Feed',
                    onTap: () {
                      setState(() {
                        _currentNavIndex = 1;
                      });
                    },
                  ),
                if (!isCaregiver || permsAi)
                  QuickActionButton(
                    icon: Icons.smart_toy_outlined,
                    label: 'AI Chat',
                    onTap: () => context.push('/ai-assistant'),
                  ),
                if (!isCaregiver || permsHealth)
                  QuickActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Sensor Reports',
                    onTap: () => context.push('/wellness-monitoring'),
                  ),
                if (!isCaregiver || permsCradle)
                  QuickActionButton(
                    icon: Icons.bedroom_baby_outlined,
                    label: 'Cradle',
                    onTap: () {
                      final device = ref.read(dashboardProvider).device;
                      if (device != null && device.deviceId.isNotEmpty) {
                        context.push('/profile/connected-devices/detail?id=${device.deviceId}');
                      } else {
                        context.push('/profile/connected-devices');
                      }
                    },
                  ),
                if (!isCaregiver)
                  QuickActionButton(
                    icon: Icons.supervisor_account_outlined,
                    label: 'Caretaker Access',
                    onTap: () => context.push(AppRoutes.caregiverAccess),
                  ),
                if (!isCaregiver || permsMusic)
                  QuickActionButton(
                    icon: Icons.music_note_outlined,
                    label: 'Lullabies',
                    onTap: () => context.push('/music'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerPlaceholder(width: 220.w, height: 28.h),
          SizedBox(height: 8.h),
          ShimmerPlaceholder(width: 300.w, height: 16.h),
          SizedBox(height: 24.h),
          ShimmerPlaceholder(width: double.infinity, height: 80.h, borderRadius: 24.r),
          SizedBox(height: 28.h),
          ShimmerPlaceholder(width: 140.w, height: 22.h),
          SizedBox(height: 12.h),
          ShimmerPlaceholder(width: double.infinity, height: 220.h, borderRadius: 28.r),
          SizedBox(height: 28.h),
          ShimmerPlaceholder(width: 160.w, height: 22.h),
          SizedBox(height: 12.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14.w,
            mainAxisSpacing: 14.h,
            childAspectRatio: 1.15,
            children: List.generate(
              6,
              (index) => ShimmerPlaceholder(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 24.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onActionPressed,
  }) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 1.5),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48.r, color: AppColors.primary.withOpacity(0.5)),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: Colors.red.withOpacity(0.12), width: 1.5),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48.r, color: Colors.redAccent),
            SizedBox(height: 16.h),
            Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: () => ref.read(dashboardProvider.notifier).loadDashboard(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.04),
                width: 1.5,
              ),
              boxShadow: AppColors.softShadow,
            ),
          ),
        );
      },
    );
  }
}
