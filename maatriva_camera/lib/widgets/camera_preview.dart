import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';
import '../theme/app_colors.dart';

class CameraPreviewWidget extends StatelessWidget {
  final WebrtcService webrtcService;

  const CameraPreviewWidget({
    super.key,
    required this.webrtcService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: webrtcService.isStreamingNotifier,
      builder: (context, isStreaming, child) {
        return Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBg, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Camera Feed / Placeholder
              Positioned.fill(
                child: isStreaming
                    ? RTCVideoView(
                        webrtcService.localRenderer,
                        mirror: true, // Mirror local preview for intuitive viewing
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : Container(
                        color: const Color(0xFF130924),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_off_rounded,
                                color: Colors.white24,
                                size: 64,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Camera Stream Inactive',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              // Overlay tag: Resolution info when active
              if (isStreaming)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hd_rounded, color: AppColors.primary, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '720p 30FPS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
