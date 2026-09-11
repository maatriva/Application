import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/providers.dart';
import '../../../../shared/models/vitals_telemetry.dart';
import '../../../../shared/models/user_session.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../onboarding/providers/onboarding_provider.dart';
import '../../../monitoring/presentation/widgets/camera_card.dart';
import '../../../../shared/widgets/bottom_navigation.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/wellness_section.dart';
import '../widgets/smart_cradle_card.dart';
import '../widgets/caregiver_status_card.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingState = ref.read(onboardingProvider);
      if (!onboardingState.isCompleted) {
        context.go('/onboarding');
      }
    });
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

    final perms = ref.watch(caregiverPermissionsProvider);
    final bool permsHealth = !isCaregiver || (perms['health_data'] == true);
    final bool permsAi = !isCaregiver || (perms['ai_assistant'] == true);

    final isLiveMonitorOnly = (isCaregiver && !permsHealth) || baby?.accessLevel == 'LIVE_MONITOR_ONLY';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DashboardHeader(),
      drawer: const AppDrawer(),
      body: _buildHomeBody(isLiveMonitorOnly, isCaregiver),
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
      bottomNavigationBar: const BottomNavigation(currentIndex: 0),
    );
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
      if (isCaregiver) {
        return _buildEmptyState(
          title: 'Join Shared Baby',
          icon: Icons.qr_code_scanner_rounded,
          message: 'No active baby monitoring session assigned. Scan the QR code generated on the parent\'s device to monitor.',
          actionLabel: 'Scan Parent\'s QR Code',
          onActionPressed: () {
            context.push('/join-shared-baby');
          },
        );
      }
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

    final perms = ref.watch(caregiverPermissionsProvider);
    final bool permsMusic = !isCaregiver || (perms['custom_parent_folder'] == true || perms['custom_music'] == true);
    final bool permsHealth = !isCaregiver || (perms['health'] == true || perms['health_data'] == true);
    final bool permsCradle = true;

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
                
                final reactiveExpiry = ref.watch(caregiverSessionExpiryProvider);
                final cacheService = ref.watch(cacheServiceProvider);
                final caregiverSession = cacheService.getCaregiverGrantedSession();
                DateTime? expiresAt = reactiveExpiry;
                if (expiresAt == null && caregiverSession != null && caregiverSession['expiresAt'] != null) {
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

            // 2. Primary Live Camera Video Section (Replaces the Nobita Baby Status Hero card)
            const CameraCard(),
            SizedBox(height: 24.h),

            // 3. Caregiver Access Banner / Timer (only shown if caregiver active or caregiver user)
            Consumer(
              builder: (context, ref, child) {
                final reactiveExpiry = ref.watch(caregiverSessionExpiryProvider);
                final cacheService = ref.watch(cacheServiceProvider);
                final caregiverSession = cacheService.getCaregiverGrantedSession();
                DateTime? expiresAt = reactiveExpiry;
                if (expiresAt == null && caregiverSession != null && caregiverSession['expiresAt'] != null) {
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

                final authState = ref.watch(authNotifierProvider);
                final isCaregiverUser = isCaregiver || authState.session?.role == UserRole.caregiver;

                if (isCaregiverUser || activeCaregiverName == null || activeCaregiverName.trim().isEmpty) {
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
                    showViewAll: true,
                    onViewAllTap: () => context.go('/predictive-health'),
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

            // 6. Quick Action Shortcuts Section Header
            Text(
              'Quick Actions',
              style: AppTypography.sectionTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            // Quick Actions Grid Layout
            GridView.count(
              crossAxisCount: actionsCrossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: actionsChildAspectRatio,
              children: [
                QuickActionButton(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Health',
                  onTap: () {
                    if (isCaregiver && !permsHealth) {
                      _showRestrictedAccessDialog(context, 'Health');
                    } else {
                      context.go('/predictive-health');
                    }
                  },
                ),
                QuickActionButton(
                  icon: Icons.music_note_outlined,
                  label: 'Music Library',
                  onTap: () {
                    if (isCaregiver && !permsMusic) {
                      _showRestrictedAccessDialog(context, 'Music Library');
                    } else {
                      context.go('/music');
                    }
                  },
                ),
                QuickActionButton(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Shop Essentials',
                  onTap: () {
                    if (isCaregiver) {
                      _showRestrictedAccessDialog(context, 'Shop Essentials');
                    } else {
                      context.go('/shop');
                    }
                  },
                ),
                QuickActionButton(
                  icon: Icons.notifications_none_rounded,
                  label: 'Alerts',
                  onTap: () => context.push('/notifications'),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        children: [
          Container(
            height: 60.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            height: 230.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28.r),
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            height: 150.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
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
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72.r, color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: onActionPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64.r, color: Colors.redAccent),
            SizedBox(height: 16.h),
            Text(
              'Something went wrong',
              style: AppTypography.sectionTitle.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
