import 'package:flutter/material.dart';
import 'package:maatriva/core/theme/app_colors.dart';

class LiveCameraCard extends StatelessWidget {
  const LiveCameraCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF173A70),
          boxShadow: AppColors.clayShadow,
          border: Border.all(
            color: AppColors.softTeal.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Mock Live Stream Feed (using a stylized illustration or background color)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C1B4D), Color(0xFF1E112C)],
                ),
              ),
              child: Opacity(
                opacity: 0.45,
                child: Image.network(
                  'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=600&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.child_care,
                        color: Colors.white.withOpacity(0.2),
                        size: 80,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Twinkle Stars/Lullaby Theme Overlay (to look like a real nursery monitor)
          Positioned.fill(child: CustomPaint(painter: StarsPainter())),

          // Ambient Information Sidebar Overlay (Left)
          Positioned(
            left: 14,
            top: 45,
            bottom: 14,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebarMiniButton(Icons.videocam_rounded, 'Cameras'),
                _buildSidebarMiniButton(Icons.lightbulb_rounded, 'Lights'),
                _buildSidebarMiniButton(Icons.thermostat_rounded, 'Temp & Air'),
                _buildSidebarMiniButton(Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),

          // Lullaby & Battery Status Sidebar Overlay (Right)
          Positioned(
            right: 14,
            top: 45,
            bottom: 14,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSidebarStatusText(
                  'LULLABY',
                  'On',
                  Icons.volume_up_rounded,
                ),
                _buildSidebarStatusText(
                  'NIGHT LIGHT',
                  'On',
                  Icons.nights_stay_rounded,
                ),
                _buildSidebarStatusText('AUDIO', 'High', Icons.mic_rounded),
              ],
            ),
          ),

          // Top Header Bar
          Positioned(
            left: 16,
            right: 16,
            top: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Home Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'TUE, OCT 26   11:47 PM',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Left "Live Camera Feed" Capsule
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Camera Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Sleep Indicator Circle
          Center(
            child: Icon(
              Icons.nights_stay,
              color: Colors.white.withOpacity(0.4),
              size: 40,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSidebarMiniButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 14),
    );
  }

  Widget _buildSidebarStatusText(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.greenAccent, size: 10),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$title $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    // Draw some simple tiny stars
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 1, paint);
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.25),
      1.5,
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.75), 1, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.6), 1.2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
