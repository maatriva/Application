import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/services/providers.dart';
import 'package:maatriva/core/services/webrtc_service.dart';
import 'package:maatriva/features/dashboard/presentation/providers/dashboard_provider.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/features/authentication/presentation/providers/auth_provider.dart';
import 'package:maatriva/shared/models/user_session.dart';

class CameraCard extends ConsumerStatefulWidget {
  const CameraCard({super.key});

  @override
  ConsumerState<CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends ConsumerState<CameraCard> {
  @override
  void dispose() {
    // Clean up WebRTC connection when screen/card is disposed
    Future.microtask(() {
      if (mounted) {
        ref.read(webrtcServiceProvider.notifier).disconnectStream();
      }
    });
    super.dispose();
  }

  void _togglePlay(String? babyId) {
    if (babyId == null) return;
    final webrtcState = ref.read(webrtcServiceProvider);
    final notifier = ref.read(webrtcServiceProvider.notifier);

    if (webrtcState.status == WebrtcStatus.disconnected ||
        webrtcState.status == WebrtcStatus.error ||
        webrtcState.status == WebrtcStatus.offline) {
      notifier.reconnectStream(babyId: babyId);
    } else {
      notifier.disconnectStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authSession = ref.watch(authNotifierProvider).session;
    final isCaregiver = authSession?.role == UserRole.caregiver;
    final perms = ref.watch(caregiverPermissionsProvider);
    final canViewLiveVideo = !isCaregiver || (perms['live_video'] == true || perms['camera_snapshot'] == true);

    if (!canViewLiveVideo) {
      return Container(
        width: double.infinity,
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF173A70),
          boxShadow: AppColors.softShadow,
        ),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined, color: Colors.orangeAccent, size: 36),
              const SizedBox(height: 10),
              Text(
                'Access Restricted',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You are not authorised to access this section.\nPlease ask the parent to enable access.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dashboardState = ref.watch(dashboardProvider);
    final webrtcState = ref.watch(webrtcServiceProvider);
    final webrtcNotifier = ref.read(webrtcServiceProvider.notifier);

    final baby = dashboardState.baby;
    final babyId = baby?.id;
    final babyName = baby?.name ?? 'Baby';

    // Auto-connect stream if disconnected and baby ID is available
    if (babyId != null && babyId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final currentWebrtcState = ref.read(webrtcServiceProvider);
          if (currentWebrtcState.status == WebrtcStatus.disconnected) {
            ref.read(webrtcServiceProvider.notifier).connectStream(babyId);
          }
        }
      });
    }

    // Extract real telemetry if available
    final telemetryMap = dashboardState.latestTelemetry;
    final roomTempVal = telemetryMap?['room_temperature']?.value;
    final humidityVal = telemetryMap?['humidity']?.value;
    final sleepStageStr = telemetryMap?['sleep_stage']?.unit ?? 'Asleep';

    final tempText = roomTempVal != null ? '${roomTempVal.toStringAsFixed(1)}°C' : '22.4°C';
    final humidityText = humidityVal != null ? '${humidityVal.toInt()}%' : '55%';

    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.black,
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Video Render Area based on WebRTC Status
          Positioned.fill(
            child: _buildVideoFeed(webrtcState, webrtcNotifier, babyId),
          ),

          // 2. Scan line / Infrared visual overlay
          if (webrtcState.status == WebrtcStatus.streaming)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  // Subtle vertical gradient to look like infrared scan line
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.green.withOpacity(0.02),
                      Colors.transparent,
                      Colors.green.withOpacity(0.01),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Stats Header Overlay
          Positioned(
            left: 14,
            right: 14,
            top: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'NURSERY LIVE FEED',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white30,
                      size: 10,
                    ),
                  ],
                ),
                Text(
                  'POWER AC Power   |   TEMP $tempText   HUMIDITY $humidityText',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // 4. "LIVE" Red Badge
          if (webrtcState.status == WebrtcStatus.streaming)
            Positioned(
              left: 14,
              top: 34,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE MONITORING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Center Play Overlay (Visible when not actively streaming/connecting)
          if (webrtcState.status == WebrtcStatus.disconnected)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_outline_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                        onPressed: () => _togglePlay(babyId),
                      ),
                      const Text(
                        'Tap to start live video stream',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Bottom Bar Overlay (Info and Controls)
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bottom Left Caption
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.sleepText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Baby: $babyName | $sleepStageStr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Right Camera Controls (Mute, Fullscreen, Play/Stop)
                Row(
                  children: [
                    // Mute / Unmute Button
                    if (webrtcState.status == WebrtcStatus.streaming) ...[
                      GestureDetector(
                        onTap: () => webrtcNotifier.toggleMute(),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            webrtcState.isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Full screen trigger
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FullscreenVideoPage(),
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Play / Disconnect Switch
                    GestureDetector(
                      onTap: () => _togglePlay(babyId),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: webrtcState.status == WebrtcStatus.streaming
                              ? const Color(0xFFD32F2F)
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          webrtcState.status == WebrtcStatus.streaming
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoFeed(WebrtcState webrtcState, WebrtcNotifier webrtcNotifier, String? babyId) {
    switch (webrtcState.status) {
      case WebrtcStatus.streaming:
        return RTCVideoView(
          webrtcNotifier.videoRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      case WebrtcStatus.connecting:
        return Container(
          color: const Color(0xFF130924),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Establishing secure cradle stream...',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      case WebrtcStatus.offline:
        return Container(
          color: const Color(0xFF1A1125),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.videocam_off_rounded,
                  color: Colors.white24,
                  size: 42,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cradle Camera is Offline',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Auto-checking camera connection...',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => webrtcNotifier.reconnectStream(babyId: babyId),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Reconnect Camera', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        );
      case WebrtcStatus.error:
        return Container(
          color: const Color(0xFF220D16),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 36,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stream Connection Lost',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  webrtcState.errorMessage ?? 'Reconnecting automatically...',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => webrtcNotifier.reconnectStream(babyId: babyId),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Retry Connection', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        );
      case WebrtcStatus.disconnected:
        // Mock placeholder display
        return Image.network(

          'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=800&q=80',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF1E112C),
              child: const Center(
                child: Icon(
                  Icons.child_care_rounded,
                  color: Colors.white24,
                  size: 64,
                ),
              ),
            );
          },
        );
    }
  }
}

// Standalone landscape fullscreen presentation page
class FullscreenVideoPage extends ConsumerWidget {
  const FullscreenVideoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webrtcState = ref.watch(webrtcServiceProvider);
    final webrtcNotifier = ref.read(webrtcServiceProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen WebRTC Stream
          Positioned.fill(
            child: Center(
              child: webrtcState.status == WebrtcStatus.streaming
                  ? RTCVideoView(
                      webrtcNotifier.videoRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ),
          
          // HUD Close button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Control Overlays
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mute/Unmute
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 28,
                  child: IconButton(
                    icon: Icon(
                      webrtcState.isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => webrtcNotifier.toggleMute(),
                  ),
                ),
                const SizedBox(width: 30),
                // Exit Fullscreen
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 28,
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
