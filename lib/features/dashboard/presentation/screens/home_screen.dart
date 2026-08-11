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
import '../../../monitoring/presentation/screens/live_monitoring_screen.dart';
import '../../../../shared/widgets/bottom_navigation.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/live_camera_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/quick_action_button.dart';

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
    final isLiveMonitorOnly = isCaregiver || baby?.accessLevel == 'LIVE_MONITOR_ONLY';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentNavIndex == 0 ? const DashboardHeader() : null,
      drawer: const AppDrawer(),
      body: _buildBody(isLiveMonitorOnly, isCaregiver),
      floatingActionButton: isLiveMonitorOnly
          ? null
          : Container(
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
            ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 0 || index == 1) {
            setState(() {
              _currentNavIndex = index;
            });
          } else if (index == 2) {
            if (isLiveMonitorOnly) {
              _showRestrictedAccessDialog(context, 'Health Analytics');
              return;
            }
            context.push('/predictive-health');
          } else if (index == 3) {
            context.push('/music');
          } else if (index == 4) {
            if (isLiveMonitorOnly) {
              _showRestrictedAccessDialog(context, 'Nursery Shop');
              return;
            }
            context.push('/shop');
          }
        },
      ),
    );
  }

  Widget _buildBody(bool isLiveMonitorOnly, bool isCaregiver) {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeBody(isLiveMonitorOnly, isCaregiver);
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
                size: 64.r,
                color: AppColors.textSecondary.withOpacity(0.4),
              ),
              SizedBox(height: 16.h),
              Text(
                _currentNavIndex == 2
                    ? 'Shop Coming Soon'
                    : 'Profile Coming Soon',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
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
    final isSmallPhone = screenWidth < 360;

    final vitalsCrossAxisCount = isTablet ? 3 : 2;
    final vitalsChildAspectRatio = isTablet 
        ? 1.4 
        : (isSmallPhone ? 1.25 : 1.15);

    final actionsCrossAxisCount = isTablet ? 6 : 3;
    final actionsChildAspectRatio = isTablet ? 1.25 : 1.05;

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: 100.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
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

            if (isCaregiver) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.12),
                      AppColors.secondary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18.r),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Caregiver Live Access',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Time-limited live monitoring authorized by parent.',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
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
                      icon: Icon(Icons.sync_rounded, size: 16.r, color: AppColors.primary),
                      label: Text(
                        'Scan QR',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // Unified Baby & Device Summary Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: AppColors.softShadow,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.06),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      baby.gender.toLowerCase() == 'female'
                          ? Icons.child_care_rounded
                          : Icons.face_rounded,
                      color: AppColors.primary,
                      size: 26.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          baby.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${calculateAge(baby.birthDate)} • ${baby.gender}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 40.h,
                    color: AppColors.divider,
                    margin: EdgeInsets.symmetric(horizontal: 14.w),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final device = ref.watch(dashboardProvider.select((s) => s.device));
                        return device != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.deviceName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6.r,
                                        height: 6.r,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: device.status == 'online' || device.status == 'ONLINE' || device.status == 'Connected' || device.status == 'PAIRED' ? AppColors.sleepText : Colors.grey,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Expanded(
                                        child: Text(
                                          device.status == 'online' || device.status == 'ONLINE' || device.status == 'Connected' || device.status == 'PAIRED' ? 'Online' : 'Offline',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.bold,
                                            color: device.status == 'online' || device.status == 'ONLINE' || device.status == 'Connected' || device.status == 'PAIRED' ? AppColors.sleepText : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 2.h),
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 10.r, color: AppColors.textSecondary),
                                      SizedBox(width: 2.w),
                                      Expanded(
                                        child: Text(
                                          'Firmware: ${device.firmwareVersion}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No Cradle Paired',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (!isLiveMonitorOnly) ...[
                                    SizedBox(height: 6.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.push('/profile/connected-devices/pair');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10.r),
                                          ),
                                        ),
                                        child: Text(
                                          'Pair Cradle',
                                          style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Device Offline Warning Card (Conditional)
            Consumer(
              builder: (context, ref, child) {
                final deviceStatus = ref.watch(dashboardProvider.select((s) => s.device?.status));
                final isOffline = deviceStatus == 'offline';
                if (!isOffline) return const SizedBox.shrink();
                return Container(
                  margin: EdgeInsets.only(bottom: 24.h),
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: const Color(0xFFEF5350).withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFC62828),
                        size: 28,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cradle is Offline',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Please check the cradle\'s power supply and Wi-Fi connection.',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFC62828).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Live Camera Card
            Text('Nursery Stream', style: AppTypography.sectionTitle),
            SizedBox(height: 12.h),
            const LiveCameraCard(),
            SizedBox(height: 28.h),

            // Today's Vitals grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Summary", style: AppTypography.sectionTitle),
                Consumer(
                  builder: (context, ref, child) {
                    final telemetryTime = ref.watch(dashboardProvider.select((s) {
                      final telemetry = s.latestTelemetry;
                      return (telemetry != null && telemetry.isNotEmpty) ? telemetry.values.first.timestamp : null;
                    }));
                    return Text(
                      telemetryTime != null
                          ? 'Updated: ${formatTime(telemetryTime)}'
                          : 'Waiting for live sensor data...',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),
            GridView.count(
              crossAxisCount: vitalsCrossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14.w,
              mainAxisSpacing: 14.h,
              childAspectRatio: vitalsChildAspectRatio,
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final heartRate = ref.watch(dashboardProvider.select((s) => s.latestTelemetry?['heart_rate']?.value.toInt().toString() ?? '--'));
                    return SummaryCard(
                      label: 'Heart Rate',
                      value: heartRate,
                      unit: 'bpm',
                      icon: Icons.favorite_border_rounded,
                      iconBgColor: AppColors.heartBg,
                      iconColor: AppColors.heartIcon,
                      onTap: isLiveMonitorOnly ? null : () => context.push('/telemetry-history?type=heart_rate'),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final breathingRate = ref.watch(dashboardProvider.select((s) => s.latestTelemetry?['breathing_rate']?.value.toInt().toString() ?? '--'));
                    return SummaryCard(
                      label: 'Breathing Rate',
                      value: breathingRate,
                      unit: 'rpm',
                      icon: Icons.air_rounded,
                      iconBgColor: AppColors.connectBg,
                      iconColor: AppColors.connectText,
                      onTap: isLiveMonitorOnly ? null : () => context.push('/telemetry-history?type=breathing_rate'),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final bodyTemp = ref.watch(dashboardProvider.select((s) => s.latestTelemetry?['body_temperature']?.value.toStringAsFixed(1) ?? '--'));
                    return SummaryCard(
                      label: 'Body Temp',
                      value: bodyTemp,
                      unit: '°C',
                      icon: Icons.thermostat_outlined,
                      iconBgColor: AppColors.tempBg,
                      iconColor: AppColors.tempIcon,
                      onTap: isLiveMonitorOnly ? null : () => context.push('/telemetry-history?type=body_temperature'),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final roomTemp = ref.watch(dashboardProvider.select((s) => s.latestTelemetry?['room_temperature']?.value.toStringAsFixed(1) ?? '--'));
                    return SummaryCard(
                      label: 'Room Temp',
                      value: roomTemp,
                      unit: '°C',
                      icon: Icons.home_outlined,
                      iconBgColor: AppColors.healthBg,
                      iconColor: AppColors.healthText,
                      onTap: isLiveMonitorOnly ? null : () => context.push('/telemetry-history?type=room_temperature'),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final humidity = ref.watch(dashboardProvider.select((s) => s.latestTelemetry?['humidity']?.value.toInt().toString() ?? '--'));
                    return SummaryCard(
                      label: 'Humidity',
                      value: humidity,
                      unit: '%',
                      icon: Icons.water_drop_outlined,
                      iconBgColor: AppColors.tempBg,
                      iconColor: AppColors.tempIcon,
                      onTap: isLiveMonitorOnly ? null : () => context.push('/telemetry-history?type=humidity'),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final airQuality = ref.watch(dashboardProvider.select((s) => s.latestTelemetry?['air_quality']?.value.toInt().toString() ?? '--'));
                    return SummaryCard(
                      label: 'Air Quality',
                      value: airQuality,
                      unit: 'AQI',
                      icon: Icons.eco_outlined,
                      iconBgColor: AppColors.sleepBg,
                      iconColor: AppColors.sleepText,
                      onTap: isLiveMonitorOnly ? null : () => context.push('/telemetry-history?type=air_quality'),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final sleepStage = ref.watch(dashboardProvider.select((s) => s.latestTelemetry?['sleep_stage']?.unit ?? 'Awake'));
                    return SummaryCard(
                      label: 'Sleep Stage',
                      value: sleepStage,
                      unit: '',
                      icon: Icons.nights_stay_outlined,
                      iconBgColor: AppColors.sleepProgressBg,
                      iconColor: AppColors.sleepProgressIcon,
                      onTap: isLiveMonitorOnly ? null : () => context.push('/telemetry-history?type=sleep_stage'),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final isCryDetected = ref.watch(dashboardProvider.select((s) => (s.latestTelemetry?['cry_detection']?.value ?? 0.0) > 0));
                    return SummaryCard(
                      label: 'Cry Detection',
                      value: isCryDetected ? 'Detected' : 'Silent',
                      unit: '',
                      icon: Icons.face_retouching_natural_outlined,
                      iconBgColor: AppColors.cryBg,
                      iconColor: AppColors.cryIcon,
                      onTap: isLiveMonitorOnly ? null : () => context.push('/telemetry-history?type=cry_detection'),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final isMovementDetected = ref.watch(dashboardProvider.select((s) => (s.latestTelemetry?['movement_detection']?.value ?? 0.0) > 0));
                    return SummaryCard(
                      label: 'Movement',
                      value: isMovementDetected ? 'Moving' : 'Still',
                      unit: '',
                      icon: Icons.directions_run_outlined,
                      iconBgColor: AppColors.connectBg,
                      iconColor: AppColors.connectText,
                      onTap: isLiveMonitorOnly ? null : () => context.push('/telemetry-history?type=movement_detection'),
                    );
                  },
                ),

              ],
            ),
            SizedBox(height: 28.h),

            // AI Insight summary
            if (!isLiveMonitorOnly) ...[
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
              SizedBox(height: 28.h),
            ],

            // Quick Actions grid
            Text('Quick Actions', style: AppTypography.sectionTitle),
            SizedBox(height: 12.h),
            if (isLiveMonitorOnly)
              GridView.count(
                crossAxisCount: 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 8.h,
                childAspectRatio: 4.5,
                children: [
                  QuickActionButton(
                    icon: Icons.videocam_outlined,
                    label: 'Open Live Camera Stream',
                    onTap: () {
                      setState(() {
                        _currentNavIndex = 1;
                      });
                    },
                  ),
                ],
              )
            else
              GridView.count(
                crossAxisCount: actionsCrossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 8.h,
                childAspectRatio: actionsChildAspectRatio,
                children: [
                  QuickActionButton(
                    icon: Icons.videocam_outlined,
                    label: 'Live Feed',
                    onTap: () {
                      setState(() {
                        _currentNavIndex = 1;
                      });
                    },
                  ),
                  QuickActionButton(
                    icon: Icons.smart_toy_outlined,
                    label: 'AI Chat',
                    onTap: isLiveMonitorOnly
                        ? () => _showRestrictedAccessDialog(context, 'AI Assistant')
                        : () => context.push('/ai-assistant'),
                  ),
                  QuickActionButton(
                    icon: Icons.favorite_border_rounded,
                    label: 'Health Stats',
                    onTap: isLiveMonitorOnly
                        ? () => _showRestrictedAccessDialog(context, 'Health Analytics')
                        : () => context.push('/predictive-health'),
                  ),
                  QuickActionButton(
                    icon: Icons.medical_services_outlined,
                    label: 'Pediatrician',
                    onTap: isLiveMonitorOnly
                        ? () => _showRestrictedAccessDialog(context, 'Pediatrician Records')
                        : () {},
                  ),
                  QuickActionButton(
                    icon: Icons.ios_share_rounded,
                    label: 'Share Info',
                    onTap: isLiveMonitorOnly
                        ? () => _showRestrictedAccessDialog(context, 'Caregiver Access Management')
                        : () => context.push('/caregiver-access'),
                  ),
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
