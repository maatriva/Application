import '../models/notification_model.dart';

final List<NotificationModel> initialMockNotifications = [
  NotificationModel(
    id: '1',
    title: 'Baby Cry Detected',
    description: 'Emma has been crying continuously for 2 minutes.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    isRead: false,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'Acoustic Cry Analytics Sensor',
    detailedExplanation:
        'The smart acoustic sensor detected sound patterns matching infant distress frequencies (above 85dB) sustained for over 120 seconds in the nursery zone.',
    recommendedAction:
        'Please check on Emma. She may need feeding, diaper replacement, or soothing support.',
    aiInsight:
        'Emma usually wakes up around this time. This crying episode matches her typical hunger schedule cycles.',
  ),
  NotificationModel(
    id: '2',
    title: 'Body Temperature Updated',
    description: 'Current body temperature: 36.8°C (Normal).',
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    isRead: false,
    category: 'health',
    priority: 'normal',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Infrared Epidermal Thermal Sensor',
    detailedExplanation:
        'Chloe\'s skin temperature was logged at 36.8°C, which sits safely within the recommended physiological zone of 36.5°C to 37.2°C.',
    recommendedAction:
        'No immediate action required. Maintain current nursery ambient settings.',
    aiInsight:
        'Vitals show perfect stability. Body heat regulation has improved by 4% compared to last week\'s averages.',
  ),
  NotificationModel(
    id: '3',
    title: 'Sleep Started',
    description: 'Emma started sleeping peacefully.',
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    isRead: true,
    category: 'sleep',
    priority: 'normal',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Photoplethysmography (PPG) Sensor',
    detailedExplanation:
        'Chloe\'s heart rate variability and motion logs indicate she has entered deep restorative sleep.',
    recommendedAction:
        'Ensure ambient nursery sounds remain in white-noise ranges for sleep preservation.',
    aiInsight:
        'Emma fell asleep 12 minutes faster tonight. Placing her down 15 minutes after feeding reduces bedtime resistance.',
  ),
  NotificationModel(
    id: '4',
    title: 'Motion Detected',
    description: 'Baby movement detected inside the cradle.',
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    isRead: true,
    category: 'activity',
    priority: 'normal',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'AI Optical Motion Detection',
    detailedExplanation:
        'Substantial structural movement was detected inside the crib area, indicating Chloe is turning or stretching.',
    recommendedAction:
        'Verify through the video screen that Chloe has successfully rolled into a comfortable sleeping position.',
    aiInsight:
        'Minor stirring is completely natural. Chloe rolled from side to back, which is the optimal safe posture.',
  ),
  NotificationModel(
    id: '5',
    title: 'Body Temperature High',
    description: 'Abnormal skin temperature detected: 38.2°C.',
    timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    isRead: false,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Infrared Epidermal Thermal Sensor',
    detailedExplanation:
        'Continuous thermal tracking records an elevation of Chloe\'s skin temperature to 38.2°C, which exceeds normal baselines.',
    recommendedAction:
        'Verify Chloe\'s temperature using an auxiliary medical thermometer. Strip down heavy clothing if necessary.',
    aiInsight:
        'Fever onset corresponds with her vaccination 24 hours ago. Keep closely hydrated and check pediatrician guidance.',
  ),
  NotificationModel(
    id: '6',
    title: 'Heart Rate Elevated',
    description: 'Active heart rate reading is high: 165 bpm.',
    timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    isRead: true,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'PPG Heart Rate Core',
    detailedExplanation:
        'Chloe\'s heart rate spiked to 165 bpm while she was in a waking transition, triggering a telemetry alert.',
    recommendedAction:
        'Soothe Emma and offer feeding. If heart rate stays high during absolute calm, consult professional advice.',
    aiInsight:
        'A heart rate of 165 bpm is common during crying or intense active play, but should subside to 110-130 bpm during rest.',
  ),
  NotificationModel(
    id: '7',
    title: 'Unsafe Sleeping Position',
    description: 'Emma has rolled onto her stomach.',
    timestamp: DateTime.now().subtract(const Duration(hours: 10)),
    isRead: false,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'Computer Vision Posture AI',
    detailedExplanation:
        'The visual posture analysis framework detected that the baby rolled completely onto her stomach (prone position).',
    recommendedAction:
        'Please visit the crib and gently roll Emma back onto her spine (supine position) to guarantee safe respiration.',
    aiInsight:
        'Prone sleeping poses an elevated risk for infants under 12 months. Rolling her back ensures absolute safety.',
  ),
  NotificationModel(
    id: '8',
    title: 'Safe Sleeping Position Restored',
    description: 'Baby is now sleeping safely on her back.',
    timestamp: DateTime.now().subtract(const Duration(hours: 10, minutes: 15)),
    isRead: true,
    category: 'sleep',
    priority: 'normal',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'Computer Vision Posture AI',
    detailedExplanation:
        'Posture monitoring confirms the infant\'s alignment has returned to the safe spine-on-mattress orientation.',
    recommendedAction:
        'No action needed. Excellent safety orientation maintained.',
    aiInsight:
        'Emma spent 92% of her sleep session in the recommended safe back position tonight.',
  ),
  NotificationModel(
    id: '9',
    title: 'Heart Rate Stable',
    description: 'Heart rate normalized: 122 bpm.',
    timestamp: DateTime.now().subtract(const Duration(hours: 11)),
    isRead: true,
    category: 'health',
    priority: 'normal',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'PPG Heart Rate Core',
    detailedExplanation:
        'Chloe\'s resting pulse has stabilized at a healthy 122 bpm during her quiet sleep phase.',
    recommendedAction:
        'Excellent resting vital sign. Continue monitoring in real-time.',
    aiInsight:
        'Resting pulse rates between 100-140 bpm are perfect benchmarks for comfortable infants.',
  ),
  NotificationModel(
    id: '10',
    title: 'Body Temperature Normal',
    description: 'Skin temperature returned to normal: 36.6°C.',
    timestamp: DateTime.now().subtract(const Duration(hours: 12)),
    isRead: true,
    category: 'health',
    priority: 'normal',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Infrared Epidermal Thermal Sensor',
    detailedExplanation:
        'Body temperature has cooled down to 36.6°C following the previous minor fever episode.',
    recommendedAction:
        'Temperature normal. Chloe\'s body has successfully regulated its thermal profile.',
    aiInsight:
        'Fever has broken. Skin heat averages show consistent cooling over the last 4 hours.',
  ),
  NotificationModel(
    id: '11',
    title: 'New Caregiver Connected',
    description: 'Grandmother has accepted caregiver access.',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: false,
    category: 'caregiver',
    priority: 'medium',
    deviceResponsible: 'Maatriva Authentication Gateway',
    sensorResponsible: 'QR Token Validation Engine',
    detailedExplanation:
        'Martha Johnson has successfully scanned the QR sharing invitation on her auxiliary mobile client and registered as a trusted caregiver.',
    recommendedAction:
        'Ensure Martha understands how to read vital parameters. Double check her allocated view permissions.',
    aiInsight:
        'Allocating caregiver roles to family members ensures continuous monitoring coverage and peace of mind.',
  ),
  NotificationModel(
    id: '12',
    title: 'Daily Health Report Ready',
    description: 'Tap to view today\'s health summary.',
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    isRead: true,
    category: 'reports',
    priority: 'normal',
    deviceResponsible: 'Maatriva Health Analytics Engine',
    sensorResponsible: 'AI Clinical Insights Aggregator',
    detailedExplanation:
        'Your baby\'s full daily aggregate report covering sleep cycles, vital averages, and physical milestones is compiled and ready.',
    recommendedAction:
        'Open the Health Reports tab to inspect historical sleep quality scores and feeding tracking tables.',
    aiInsight:
        'Sleep duration increased by 40 minutes over yesterday. Perfect hydration logs contributed to stable digestive vitals.',
  ),
  NotificationModel(
    id: '13',
    title: 'Device Disconnected',
    description: 'Smart Sock V2 signal lost.',
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
    isRead: true,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Bluetooth Low Energy (BLE) Radio',
    detailedExplanation:
        'The physical connection with the Smart Sock V2 was broken. The hub did not receive telemetry packets for over 60 seconds.',
    recommendedAction:
        'Verify that the smart sock remains securely fastened on Emma\'s foot and is sufficiently charged.',
    aiInsight:
        'Sock connection loss is often due to the baby kicking or stepping away from the Bluetooth Hub ranges (approx 10 meters).',
  ),
  NotificationModel(
    id: '14',
    title: 'Device Connected',
    description: 'Smart Sock V2 connection re-established.',
    timestamp: DateTime.now().subtract(
      const Duration(days: 1, hours: 6, minutes: 10),
    ),
    isRead: true,
    category: 'health',
    priority: 'normal',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'BLE Link Controller',
    detailedExplanation:
        'The BLE radio has successfully handshake-synced with the Smart Sock V2. Real-time telemetry has resumed.',
    recommendedAction: 'No actions needed. Live monitoring signals are green.',
    aiInsight:
        'Active connection restored with excellent RSSI strength (-58dB). Telemetry metrics are stream-synchronized.',
  ),
  NotificationModel(
    id: '15',
    title: 'Weekly Sleep Summary Ready',
    description: 'Weekly sleep quality score is 88/100.',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    isRead: true,
    category: 'reports',
    priority: 'normal',
    deviceResponsible: 'Maatriva AI Engine',
    sensorResponsible: 'Sleep Pattern Classifier',
    detailedExplanation:
        'A weekly summary of Emma\'s sleep efficiency, nocturnal awakenings, and bedtime schedules has been synthesized.',
    recommendedAction:
        'Tap to view the full sleep breakdown. Adjust nap timings according to our recommended schedules.',
    aiInsight:
        'Consistent 8:30 PM bedtimes have reduced night-time micro-awakenings by 18% this week.',
  ),
  NotificationModel(
    id: '16',
    title: 'QR Access Approved',
    description: 'Nanny Clara QR access verified.',
    timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    isRead: true,
    category: 'caregiver',
    priority: 'medium',
    deviceResponsible: 'Maatriva Security Broker',
    sensorResponsible: 'QR Handshake Sync',
    detailedExplanation:
        'Clara has scanned your invitation token and gained local read permissions for the live cam and health indicators.',
    recommendedAction:
        'Verify active guest caregiver sessions in your Settings > Caregiver Access page.',
    aiInsight:
        'Temporary guest tokens expire automatically. This credential is set to auto-revoke in 12 hours.',
  ),
  NotificationModel(
    id: '17',
    title: 'QR Access Revoked',
    description: 'Nanny Clara temporary access expired.',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    isRead: true,
    category: 'caregiver',
    priority: 'low',
    deviceResponsible: 'Maatriva Security Broker',
    sensorResponsible: 'Access Control Controller',
    detailedExplanation:
        'The temporal permission allocation for Nanny Clara has reached its expiration limit and has been securely deleted.',
    recommendedAction:
        'Generate a new QR if Clara requires access again during her shift tomorrow.',
    aiInsight:
        'Automatic token cleanup maintains high security for your camera and vital health telemetry.',
  ),
  NotificationModel(
    id: '18',
    title: 'Camera Connected',
    description: 'Maatriva Smart Cam 4K is online.',
    timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
    isRead: true,
    category: 'activity',
    priority: 'normal',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'Wi-Fi Network Interface',
    detailedExplanation:
        'The 4K nursery camera has successfully logged onto the local Wi-Fi router and is transmitting secure RTSP streams.',
    recommendedAction:
        'Open the Live tab to check active camera feeds and adjust pan-tilt positions.',
    aiInsight:
        'Wi-Fi signal strength is outstanding (92%). Live feed stream latency is under 150ms.',
  ),
  NotificationModel(
    id: '19',
    title: 'Camera Offline',
    description: 'Maatriva Smart Cam 4K disconnected.',
    timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 3)),
    isRead: true,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'TCP/IP Connection Watchdog',
    detailedExplanation:
        'The Wi-Fi interface reported a socket exception, meaning the smart camera is temporarily offline or turned off.',
    recommendedAction:
        'Check if the camera adapter is plugged in, or restart your local Wi-Fi router if other devices are struggling.',
    aiInsight:
        'Camera lost ping packets completely. Confirm nursery power outlet is on.',
  ),
  NotificationModel(
    id: '20',
    title: 'Vaccination Reminder',
    description: 'Upcoming: 6-Month Rotavirus Vaccine.',
    timestamp: DateTime.now().subtract(const Duration(days: 4)),
    isRead: true,
    category: 'health',
    priority: 'medium',
    deviceResponsible: 'Maatriva Calendar Service',
    sensorResponsible: 'Immunization Tracker Scheduler',
    detailedExplanation:
        'Emma is reaching her 6-month milestone. Her third dose of Rotavirus and DTaP immunizations is due.',
    recommendedAction:
        'Call Dr. Carter\'s clinic to schedule an appointment. Log the vaccine completion inside the profile tab.',
    aiInsight:
        'Timely vaccines protect infants from severe infections. Emma\'s previous immunization tolerance was excellent.',
  ),
  NotificationModel(
    id: '21',
    title: 'Feeding Reminder',
    description: 'Scheduled afternoon milk feed.',
    timestamp: DateTime.now().subtract(const Duration(days: 4, hours: 5)),
    isRead: true,
    category: 'activity',
    priority: 'low',
    deviceResponsible: 'Maatriva Feeding Manager',
    sensorResponsible: 'Custom Diet Scheduler',
    detailedExplanation:
        'Your customizable feeding schedule recommends a milk feed (approx. 180ml) to maintain optimal nourishment schedules.',
    recommendedAction:
        'Offer Emma her bottle. Update physical logs after completion.',
    aiInsight:
        'Feeding at consistent 3.5 hour gaps avoids evening colic and aids longer night sleep stretches.',
  ),
  NotificationModel(
    id: '22',
    title: 'Medicine Reminder',
    description: 'Vitamin D3 Drops scheduled dose.',
    timestamp: DateTime.now().subtract(const Duration(days: 5)),
    isRead: true,
    category: 'health',
    priority: 'medium',
    deviceResponsible: 'Maatriva Pediatric Log',
    sensorResponsible: 'Daily Dosage Alarm',
    detailedExplanation:
        'Chloe\'s daily recommended supplement of 400 IU Vitamin D3 is scheduled.',
    recommendedAction:
        'Administer 1 drop of Vitamin D3. Ensure drops are placed directly inside her mouth or added to her bottle.',
    aiInsight:
        'Daily D3 ensures healthy bone structure growth and enhances overall pediatric immune function.',
  ),
  NotificationModel(
    id: '23',
    title: 'Sensor Battery Low',
    description: 'Smart Sock V2 battery is below 15%.',
    timestamp: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
    isRead: true,
    category: 'critical',
    priority: 'medium',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Lithium Battery Fuel Gauge',
    detailedExplanation:
        'The rechargeable cell inside the wearable smart sock is low (12% remaining) and won\'t cover the next sleep session.',
    recommendedAction:
        'Place the sensor on its magnetic charging base station. Charge for 30 minutes to reach 80% battery capacity.',
    aiInsight:
        'Keep battery above 20% to avoid mid-night disconnection alarms during critical sleep phases.',
  ),
  NotificationModel(
    id: '24',
    title: 'Firmware Update Available',
    description: 'Nursery Hub OS v2.4.0 is ready.',
    timestamp: DateTime.now().subtract(const Duration(days: 6)),
    isRead: true,
    category: 'reports',
    priority: 'low',
    deviceResponsible: 'Maatriva OTA Update Server',
    sensorResponsible: 'Firmware Update Engine',
    detailedExplanation:
        'A new firmware package is available with improved cry classification AI filters and optimized battery consumption.',
    recommendedAction:
        'Go to Settings > Connected Devices and select "Update Firmware". Ensure the device remains plugged into power.',
    aiInsight:
        'This update reduces accidental cry alerts triggered by background fans or white noise machines by 35%.',
  ),
  NotificationModel(
    id: '25',
    title: 'AI Health Insight Ready',
    description: 'Excellent heart-rate-to-temperature correlation.',
    timestamp: DateTime.now().subtract(const Duration(days: 7)),
    isRead: true,
    category: 'reports',
    priority: 'normal',
    deviceResponsible: 'Maatriva AI Engine',
    sensorResponsible: 'Biometric Correlation Classifier',
    detailedExplanation:
        'The deep learning system has analyzed Chloe\'s resting metrics over the last 30 days and noted outstanding consistency.',
    recommendedAction:
        'Check out the AI Assistant tab to read the full report on pediatric wellness trends.',
    aiInsight:
        'Stable heart patterns demonstrate excellent autonomic nervous system development. Keep doing what you\'re doing!',
  ),
];
