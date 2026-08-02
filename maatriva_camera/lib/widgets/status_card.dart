import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../services/webrtc_service.dart';
import '../theme/app_colors.dart';

class StatusCardWidget extends StatelessWidget {
  final SocketService socketService;
  final WebrtcService webrtcService;

  const StatusCardWidget({
    super.key,
    required this.socketService,
    required this.webrtcService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device title
          _buildItem(
            label: 'Device:',
            value: 'Smart Cradle Camera',
            valueColor: AppColors.textPrimary,
          ),
          const SizedBox(height: 20),

          // Socket connection status
          ValueListenableBuilder<SocketConnectionState>(
            valueListenable: socketService.connectionNotifier,
            builder: (context, connState, child) {
              String statusText = 'Disconnected';
              Color statusColor = AppColors.error;
              Widget dot = Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              );

              if (connState == SocketConnectionState.connected) {
                statusText = 'Connected';
                statusColor = AppColors.success;
                dot = Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                );
              } else if (connState == SocketConnectionState.connecting) {
                statusText = 'Connecting...';
                statusColor = AppColors.warning;
                dot = const SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
                );
              } else if (connState == SocketConnectionState.error) {
                statusText = 'Connection Error';
                statusColor = AppColors.error;
              }

              return _buildItem(
                label: 'Status:',
                valueChild: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    dot,
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Stream status
          ValueListenableBuilder<bool>(
            valueListenable: webrtcService.isStreamingNotifier,
            builder: (context, isStreaming, child) {
              return ValueListenableBuilder<int>(
                valueListenable: webrtcService.viewerCountNotifier,
                builder: (context, viewerCount, child) {
                  String streamText = isStreaming
                      ? (viewerCount > 0 ? 'Streaming ($viewerCount Viewers)' : 'Streaming (No Viewers)')
                      : 'Not Streaming';
                  Color streamColor = isStreaming ? AppColors.success : AppColors.error;

                  return _buildItem(
                    label: 'Streaming:',
                    valueChild: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: streamColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          streamText,
                          style: TextStyle(
                            color: streamColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Active camera sensor
          ValueListenableBuilder<String>(
            valueListenable: webrtcService.activeCameraNotifier,
            builder: (context, activeCam, child) {
              return _buildItem(
                label: 'Camera:',
                value: activeCam,
                valueColor: AppColors.textPrimary,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String label,
    String? value,
    Color? valueColor,
    Widget? valueChild,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        if (valueChild != null)
          valueChild
        else
          Text(
            value ?? '',
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
