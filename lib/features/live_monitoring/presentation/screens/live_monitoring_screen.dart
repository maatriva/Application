import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../widgets/live_header.dart';
import '../widgets/camera_card.dart';
import '../widgets/action_button.dart';
import '../widgets/ai_summary_card.dart';
import '../widgets/body_temp_card.dart';
import '../widgets/heart_rate_card.dart';
import '../widgets/breathing_card.dart';
import '../widgets/room_temp_card.dart';
import '../widgets/gas_detection_card.dart';
import '../widgets/motion_card.dart';
import '../widgets/posture_card.dart';
import '../widgets/mood_card.dart';
import '../widgets/swing_card.dart';
import '../widgets/crying_status_card.dart';

class LiveMonitoringScreen extends StatelessWidget {
  const LiveMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Baby profile & notification bell)
            const LiveHeader(),
            const SizedBox(height: 16),

            // Live Camera Section with overlay controls and battery status
            const CameraCard(),
            const SizedBox(height: 20),

            // Quick Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ActionButton.record(onTap: () {}),
                ActionButton.snapshot(onTap: () {}),
                ActionButton.soothe(onTap: () {}),
                ActionButton.sos(onTap: () {}),
              ],
            ),
            const SizedBox(height: 20),

            // AI Smart Summary Card
            const AiSummaryCard(),
            const SizedBox(height: 20),

            // Body Temperature & Heart Rate Cards
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  const Expanded(child: BodyTempCard()),
                  const SizedBox(width: 16),
                  const Expanded(child: HeartRateCard()),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Breathing Rate Card
            const BreathingCard(),
            const SizedBox(height: 16),

            // Room Temp & Gas Detection Card
            Row(
              children: [
                const Expanded(child: RoomTempCard()),
                const SizedBox(width: 16),
                const Expanded(child: GasDetectionCard()),
              ],
            ),
            const SizedBox(height: 16),

            // Motion & Posture Cards
            Row(
              children: [
                const Expanded(child: MotionCard()),
                const SizedBox(width: 16),
                const Expanded(child: PostureCard()),
              ],
            ),
            const SizedBox(height: 16),

            // Mood & Swing Cards
            Row(
              children: [
                const Expanded(child: MoodCard()),
                const SizedBox(width: 16),
                const Expanded(child: SwingCard()),
              ],
            ),
            const SizedBox(height: 16),

            // Crying Status Card
            const CryingStatusCard(),
          ],
        ),
      ),
    );
  }
}
