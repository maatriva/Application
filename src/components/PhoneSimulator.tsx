import React, { useState } from "react";
import { 
  Wifi, 
  Battery, 
  Bell, 
  ShieldCheck, 
  Thermometer, 
  Heart, 
  Moon, 
  Smile, 
  Tv, 
  Bot, 
  BarChart3, 
  BriefcaseMedical, 
  Share2, 
  Music, 
  Plus, 
  Home, 
  Video, 
  ShoppingBag, 
  User, 
  Sparkles, 
  RefreshCw,
  AlertTriangle,
  Search,
  ShoppingCart,
  Sliders,
  Star,
  CheckCircle,
  ArrowLeft,
  Trash2,
  Minus,
  Check,
  QrCode,
  Clock,
  Unlock,
  PlusCircle,
  ChevronLeft,
  ChevronRight,
  Play,
  RotateCw,
  Volume1,
  Volume2,
  Menu
} from "lucide-react";
import { BabyMetrics } from "../types";

interface PhoneSimulatorProps {
  metrics: BabyMetrics;
  onMetricsChange: (newMetrics: Partial<BabyMetrics>) => void;
  onGenerateAIInsight: () => void;
}

interface Product {
  id: string;
  name: string;
  description: string;
  category: string;
  imageUrl: string;
  price: number;
  rating: number;
  reviewsCount: number;
  isNewArrival?: boolean;
  isFeatured?: boolean;
  features: string[];
  specifications: Record<string, string>;
}

// React Mock Database (matching Flutter precisely)
const MOCK_PRODUCTS: Product[] = [
  {
    id: "p1",
    name: "Organic Cotton Sleep Set",
    description: "Ultra-soft, organic, and beautifully crafted sleep set made with certified organic cotton. Features dual zipper functionality for convenient night changes and safe seams.",
    category: "Clothing",
    imageUrl: "https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=400&q=80",
    price: 45.00,
    rating: 4.8,
    reviewsCount: 150,
    isNewArrival: true,
    isFeatured: true,
    features: [
      "100% GOTS certified organic cotton",
      "Two-way smooth safety zipper",
      "Hypoallergenic material for extra-sensitive baby skin"
    ],
    specifications: {
      "Material": "100% Organic Cotton",
      "Size range": "0 - 12 months",
      "Machine Wash": "Yes"
    }
  },
  {
    id: "p2",
    name: "Soft Touch Pacifier",
    description: "Medical-grade orthodontic silicone pacifier designed carefully to mimic maternal soothing patterns. It promotes healthy dental and gums development.",
    category: "Baby Care",
    imageUrl: "https://images.unsplash.com/photo-1596464716127-f2a82984de30?auto=format&fit=crop&w=400&q=80",
    price: 12.00,
    rating: 4.9,
    reviewsCount: 120,
    isNewArrival: false,
    isFeatured: true,
    features: [
      "BPA-free orthodontic shield",
      "Shield ventilation openings prevent skin irritation",
      "Sterilizer-safe components"
    ],
    specifications: {
      "Material": "100% Medical-grade Silicone",
      "BPA Free": "Yes",
      "Items in Pack": "2 pack"
    }
  },
  {
    id: "p3",
    name: "Bamboo Knit Blanket",
    description: "Naturally breathable swaddling knit blanket derived from organic bamboo fibers. Gently regulates infants body temperature to keep them cosy.",
    category: "Baby Care",
    imageUrl: "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=400&q=80",
    price: 38.00,
    rating: 4.8,
    reviewsCount: 85,
    isNewArrival: false,
    isFeatured: false,
    features: [
      "Naturally hypoallergenic & antimicrobial",
      "Four-way stretch flexible weave",
      "Thermal-regulating micro fibers"
    ],
    specifications: {
      "Material": "70% Bamboo Silk, 30% Egyptian Cotton",
      "Dimensions": "44\" x 44\"",
      "Hypoallergenic": "Yes"
    }
  },
  {
    id: "p4",
    name: "Silent Glide Cradle Wheels",
    description: "Noiseless premium ball bearing wheels designed specifically to glide on hardwood or carpets with absolute zero vibration.",
    category: "Cradle Parts",
    imageUrl: "https://images.unsplash.com/photo-1591088398332-8a7791972843?auto=format&fit=crop&w=400&q=80",
    price: 24.00,
    rating: 5.0,
    reviewsCount: 42,
    isNewArrival: true,
    isFeatured: false,
    features: [
      "Super quiet dual ball bearing glide",
      "Non-scratching elastomer shell wheels",
      "Single-foot secure safety locking locks"
    ],
    specifications: {
      "Stem Size": "M8 Threaded",
      "Max Load": "120 lbs (Set of 4)",
      "Brakes": "Yes, dual locking"
    }
  },
  {
    id: "p9",
    name: "Calming Baby Lotion",
    description: "Moisturizes skin with continuous organic hydration while soothing baby senses for bed. Formulated with chamomile and lavender extracts.",
    category: "Baby Care",
    imageUrl: "https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80",
    price: 18.50,
    rating: 4.7,
    reviewsCount: 210,
    isNewArrival: false,
    isFeatured: false,
    features: [
      "Infused with 100% natural lavender oil",
      "Dermatologist tested & pediatrician approved",
      "Free from parabens, phthalates, or dyes"
    ],
    specifications: {
      "Volume": "250 ml (8.4 fl oz)",
      "Ph balanced": "Yes",
      "Fragrance": "Natural Lavender Chamomile"
    }
  }
];

export interface NotificationItem {
  id: string;
  title: string;
  description: string;
  timestamp: string;
  isRead: boolean;
  category: 'critical' | 'health' | 'sleep' | 'activity' | 'caregiver' | 'reports';
  priority: 'high' | 'medium' | 'low';
  deviceResponsible: string;
  sensorResponsible: string;
  detailedExplanation: string;
  recommendedAction: string;
  aiInsight: string;
  section: 'Today' | 'Yesterday' | 'Earlier';
}

const MOCK_NOTIFICATIONS: NotificationItem[] = [
  {
    id: '1',
    title: 'Baby Cry Detected',
    description: 'Emma has been crying continuously for 2 minutes.',
    timestamp: '2 min ago',
    isRead: false,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'Acoustic Cry Analytics Sensor',
    detailedExplanation: 'The smart acoustic sensor detected sound patterns matching infant distress frequencies (above 85dB) sustained for over 120 seconds in the nursery zone.',
    recommendedAction: 'Please check on Emma. She may need feeding, diaper replacement, or soothing support.',
    aiInsight: 'Emma usually wakes up around this time. This crying episode matches her typical hunger schedule cycles.',
    section: 'Today'
  },
  {
    id: '2',
    title: 'Body Temperature Updated',
    description: 'Current body temperature: 36.8°C (Normal).',
    timestamp: '15 min ago',
    isRead: false,
    category: 'health',
    priority: 'low',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Infrared Epidermal Thermal Sensor',
    detailedExplanation: "Chloe's skin temperature was logged at 36.8°C, which sits safely within the recommended physiological zone of 36.5°C to 37.2°C.",
    recommendedAction: 'No immediate action required. Maintain current nursery ambient settings.',
    aiInsight: "Vitals show perfect stability. Body heat regulation has improved by 4% compared to last week's averages.",
    section: 'Today'
  },
  {
    id: '3',
    title: 'Sleep Started',
    description: 'Emma started sleeping peacefully.',
    timestamp: '1 hour ago',
    isRead: true,
    category: 'sleep',
    priority: 'low',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Photoplethysmography (PPG) Sensor',
    detailedExplanation: "Chloe's heart rate variability and motion logs indicate she has entered deep restorative sleep.",
    recommendedAction: 'Ensure ambient nursery sounds remain in white-noise ranges for sleep preservation.',
    aiInsight: 'Emma fell asleep 12 minutes faster tonight. Placing her down 15 minutes after feeding reduces bedtime resistance.',
    section: 'Today'
  },
  {
    id: '4',
    title: 'Motion Detected',
    description: 'Baby movement detected inside the cradle.',
    timestamp: 'Today',
    isRead: true,
    category: 'activity',
    priority: 'low',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'AI Optical Motion Detection',
    detailedExplanation: 'Substantial structural movement was detected inside the crib area, indicating Chloe is turning or stretching.',
    recommendedAction: 'Verify through the video screen that Chloe has successfully rolled into a comfortable sleeping position.',
    aiInsight: 'Minor stirring is completely natural. Chloe rolled from side to back, which is the optimal safe posture.',
    section: 'Today'
  },
  {
    id: '5',
    title: 'Body Temperature High',
    description: 'Abnormal skin temperature detected: 38.2°C.',
    timestamp: 'Today',
    isRead: false,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Infrared Epidermal Thermal Sensor',
    detailedExplanation: "Continuous thermal tracking records an elevation of Chloe's skin temperature to 38.2°C, which exceeds normal baselines.",
    recommendedAction: "Verify Chloe's temperature using an auxiliary medical thermometer. Strip down heavy clothing if necessary.",
    aiInsight: "Fever onset corresponds with her vaccination 24 hours ago. Keep closely hydrated and check pediatrician guidance.",
    section: 'Today'
  },
  {
    id: '6',
    title: 'Heart Rate Elevated',
    description: 'Active heart rate reading is high: 165 bpm.',
    timestamp: 'Today',
    isRead: true,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'PPG Heart Rate Core',
    detailedExplanation: "Chloe's heart rate spiked to 165 bpm while she was in a waking transition, triggering a telemetry alert.",
    recommendedAction: 'Soothe Emma and offer feeding. If heart rate stays high during absolute calm, consult professional advice.',
    aiInsight: 'A heart rate of 165 bpm is common during crying or intense active play, but should subside to 110-130 bpm during rest.',
    section: 'Today'
  },
  {
    id: '7',
    title: 'Unsafe Sleeping Position',
    description: 'Emma has rolled onto her stomach.',
    timestamp: 'Today',
    isRead: false,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'Computer Vision Posture AI',
    detailedExplanation: 'The visual posture analysis framework detected that the baby rolled completely onto her stomach (prone position).',
    recommendedAction: 'Please visit the crib and gently roll Emma back onto her spine (supine position) to guarantee safe respiration.',
    aiInsight: 'Prone sleeping poses an elevated risk for infants under 12 months. Rolling her back ensures absolute safety.',
    section: 'Today'
  },
  {
    id: '8',
    title: 'Safe Sleeping Position Restored',
    description: 'Baby is now sleeping safely on her back.',
    timestamp: 'Today',
    isRead: true,
    category: 'sleep',
    priority: 'low',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'Computer Vision Posture AI',
    detailedExplanation: "Posture monitoring confirms the infant's alignment has returned to the safe spine-on-mattress orientation.",
    recommendedAction: 'No action needed. Excellent safety orientation maintained.',
    aiInsight: 'Emma spent 92% of her sleep session in the recommended safe back position tonight.',
    section: 'Today'
  },
  {
    id: '9',
    title: 'Heart Rate Stable',
    description: 'Heart rate normalized: 122 bpm.',
    timestamp: 'Today',
    isRead: true,
    category: 'health',
    priority: 'low',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'PPG Heart Rate Core',
    detailedExplanation: "Chloe's resting pulse has stabilized at a healthy 122 bpm during her quiet sleep phase.",
    recommendedAction: 'Excellent resting vital sign. Continue monitoring in real-time.',
    aiInsight: 'Resting pulse rates between 100-140 bpm are perfect benchmarks for comfortable infants.',
    section: 'Today'
  },
  {
    id: '10',
    title: 'Body Temperature Normal',
    description: 'Skin temperature returned to normal: 36.6°C.',
    timestamp: 'Today',
    isRead: true,
    category: 'health',
    priority: 'low',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Infrared Epidermal Thermal Sensor',
    detailedExplanation: 'Body temperature has cooled down to 36.6°C following the previous minor fever episode.',
    recommendedAction: "Temperature normal. Chloe's body has successfully regulated its thermal profile.",
    aiInsight: 'Fever has broken. Skin heat averages show consistent cooling over the last 4 hours.',
    section: 'Today'
  },
  {
    id: '11',
    title: 'New Caregiver Connected',
    description: 'Grandmother has accepted caregiver access.',
    timestamp: 'Yesterday',
    isRead: false,
    category: 'caregiver',
    priority: 'medium',
    deviceResponsible: 'Maatriva Authentication Gateway',
    sensorResponsible: 'QR Token Validation Engine',
    detailedExplanation: 'Martha Johnson has successfully scanned the QR sharing invitation on her auxiliary mobile client and registered as a trusted caregiver.',
    recommendedAction: 'Ensure Martha understands how to read vital parameters. Double check her allocated view permissions.',
    aiInsight: 'Allocating caregiver roles to family members ensures continuous monitoring coverage and peace of mind.',
    section: 'Yesterday'
  },
  {
    id: '12',
    title: 'Daily Health Report Ready',
    description: "Tap to view today's health summary.",
    timestamp: 'Yesterday',
    isRead: true,
    category: 'reports',
    priority: 'low',
    deviceResponsible: 'Maatriva Health Analytics Engine',
    sensorResponsible: 'AI Clinical Insights Aggregator',
    detailedExplanation: "Your baby's full daily aggregate report covering sleep cycles, vital averages, and physical milestones is compiled and ready.",
    recommendedAction: 'Open the Health Reports tab to inspect historical sleep quality scores and feeding tracking tables.',
    aiInsight: 'Sleep duration increased by 40 minutes over yesterday. Perfect hydration logs contributed to stable digestive vitals.',
    section: 'Yesterday'
  },
  {
    id: '13',
    title: 'Device Disconnected',
    description: 'Smart Sock V2 signal lost.',
    timestamp: 'Yesterday',
    isRead: true,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Bluetooth Low Energy (BLE) Radio',
    detailedExplanation: 'The physical connection with the Smart Sock V2 was broken. The hub did not receive telemetry packets for over 60 seconds.',
    recommendedAction: "Verify that the smart sock remains securely fastened on Emma's foot and is sufficiently charged.",
    aiInsight: 'Sock connection loss is often due to the baby kicking or stepping away from the Bluetooth Hub ranges (approx 10 meters).',
    section: 'Yesterday'
  },
  {
    id: '14',
    title: 'Device Connected',
    description: 'Smart Sock V2 connection re-established.',
    timestamp: 'Yesterday',
    isRead: true,
    category: 'health',
    priority: 'low',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'BLE Link Controller',
    detailedExplanation: 'The BLE radio has successfully handshake-synced with the Smart Sock V2. Real-time telemetry has resumed.',
    recommendedAction: 'No actions needed. Live monitoring signals are green.',
    aiInsight: 'Active connection restored with excellent RSSI strength (-58dB). Telemetry metrics are stream-synchronized.',
    section: 'Yesterday'
  },
  {
    id: '15',
    title: 'Weekly Sleep Summary Ready',
    description: 'Weekly sleep quality score is 88/100.',
    timestamp: 'Monday',
    isRead: true,
    category: 'reports',
    priority: 'low',
    deviceResponsible: 'Maatriva AI Engine',
    sensorResponsible: 'Sleep Pattern Classifier',
    detailedExplanation: "A weekly summary of Emma's sleep efficiency, nocturnal awakenings, and bedtime schedules has been synthesized.",
    recommendedAction: 'Tap to view the full sleep breakdown. Adjust nap timings according to our recommended schedules.',
    aiInsight: 'Consistent 8:30 PM bedtimes have reduced night-time micro-awakenings by 18% this week.',
    section: 'Earlier'
  },
  {
    id: '16',
    title: 'QR Access Approved',
    description: 'Nanny Clara QR access verified.',
    timestamp: 'Monday',
    isRead: true,
    category: 'caregiver',
    priority: 'medium',
    deviceResponsible: 'Maatriva Security Broker',
    sensorResponsible: 'QR Handshake Sync',
    detailedExplanation: 'Clara has scanned your invitation token and gained local read permissions for the live cam and health indicators.',
    recommendedAction: 'Verify active guest caregiver sessions in your Settings > Caregiver Access page.',
    aiInsight: 'Temporary guest tokens expire automatically. This credential is set to auto-revoke in 12 hours.',
    section: 'Earlier'
  },
  {
    id: '17',
    title: 'QR Access Revoked',
    description: 'Nanny Clara temporary access expired.',
    timestamp: 'Earlier',
    isRead: true,
    category: 'caregiver',
    priority: 'low',
    deviceResponsible: 'Maatriva Security Broker',
    sensorResponsible: 'Access Control Controller',
    detailedExplanation: 'The temporal permission allocation for Nanny Clara has reached its expiration limit and has been securely deleted.',
    recommendedAction: 'Generate a new QR if Clara requires access again during her shift tomorrow.',
    aiInsight: 'Automatic token cleanup maintains high security for your camera and vital health telemetry.',
    section: 'Earlier'
  },
  {
    id: '18',
    title: 'Camera Connected',
    description: 'Maatriva Smart Cam 4K is online.',
    timestamp: 'Earlier',
    isRead: true,
    category: 'activity',
    priority: 'low',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'Wi-Fi Network Interface',
    detailedExplanation: 'The 4K nursery camera has successfully logged onto the local Wi-Fi router and is transmitting secure RTSP streams.',
    recommendedAction: 'Open the Live tab to check active camera feeds and adjust pan-tilt positions.',
    aiInsight: 'Wi-Fi signal strength is outstanding (92%). Live feed stream latency is under 150ms.',
    section: 'Earlier'
  },
  {
    id: '19',
    title: 'Camera Offline',
    description: 'Maatriva Smart Cam 4K disconnected.',
    timestamp: 'Earlier',
    isRead: true,
    category: 'critical',
    priority: 'high',
    deviceResponsible: 'Maatriva Smart Cam 4K',
    sensorResponsible: 'TCP/IP Connection Watchdog',
    detailedExplanation: 'The Wi-Fi interface reported a socket exception, meaning the smart camera is temporarily offline or turned off.',
    recommendedAction: 'Check if the camera adapter is plugged in, or restart your local Wi-Fi router if other devices are struggling.',
    aiInsight: 'Camera lost ping packets completely. Confirm nursery power outlet is on.',
    section: 'Earlier'
  },
  {
    id: '20',
    title: 'Vaccination Reminder',
    description: 'Upcoming: 6-Month Rotavirus Vaccine.',
    timestamp: 'Earlier',
    isRead: true,
    category: 'health',
    priority: 'medium',
    deviceResponsible: 'Maatriva Calendar Service',
    sensorResponsible: 'Immunization Tracker Scheduler',
    detailedExplanation: 'Emma is reaching her 6-month milestone. Her third dose of Rotavirus and DTaP immunizations is due.',
    recommendedAction: "Call Dr. Carter's clinic to schedule an appointment. Log the vaccine completion inside the profile tab.",
    aiInsight: 'Timely vaccines protect infants from severe infections. Emma\'s previous immunization tolerance was excellent.',
    section: 'Earlier'
  },
  {
    id: '21',
    title: 'Feeding Reminder',
    description: 'Scheduled afternoon milk feed.',
    timestamp: 'Earlier',
    isRead: true,
    category: 'activity',
    priority: 'low',
    deviceResponsible: 'Maatriva Feeding Manager',
    sensorResponsible: 'Custom Diet Scheduler',
    detailedExplanation: 'Your customizable feeding schedule recommends a milk feed (approx. 180ml) to maintain optimal nourishment schedules.',
    recommendedAction: 'Offer Emma her bottle. Update physical logs after completion.',
    aiInsight: 'Feeding at consistent 3.5 hour gaps avoids evening colic and aids longer night sleep stretches.',
    section: 'Earlier'
  },
  {
    id: '22',
    title: 'Medicine Reminder',
    description: 'Vitamin D3 Drops scheduled dose.',
    timestamp: 'Earlier',
    isRead: true,
    category: 'health',
    priority: 'medium',
    deviceResponsible: 'Maatriva Pediatric Log',
    sensorResponsible: 'Daily Dosage Alarm',
    detailedExplanation: "Chloe's daily recommended supplement of 400 IU Vitamin D3 is scheduled.",
    recommendedAction: 'Administer 1 drop of Vitamin D3. Ensure drops are placed directly inside her mouth or added to her bottle.',
    aiInsight: 'Daily D3 ensures healthy bone structure growth and enhances overall pediatric immune function.',
    section: 'Earlier'
  },
  {
    id: '23',
    title: 'Sensor Battery Low',
    description: 'Smart Sock V2 battery is below 15%.',
    timestamp: 'Earlier',
    isRead: true,
    category: 'critical',
    priority: 'medium',
    deviceResponsible: 'Maatriva Smart Sock V2',
    sensorResponsible: 'Lithium Battery Fuel Gauge',
    detailedExplanation: 'The rechargeable cell inside the wearable smart sock is low (12% remaining) and won\'t cover the next sleep session.',
    recommendedAction: 'Place the sensor on its magnetic charging base station. Charge for 30 minutes to reach 80% battery capacity.',
    aiInsight: 'Keep battery above 20% to avoid mid-night disconnection alarms during critical sleep phases.',
    section: 'Earlier'
  },
  {
    id: '24',
    title: 'Firmware Update Available',
    description: 'Nursery Hub OS v2.4.0 is ready.',
    timestamp: 'Earlier',
    isRead: true,
    category: 'reports',
    priority: 'low',
    deviceResponsible: 'Maatriva OTA Update Server',
    sensorResponsible: 'Firmware Update Engine',
    detailedExplanation: 'A new firmware package is available with improved cry classification AI filters and optimized battery consumption.',
    recommendedAction: 'Go to Settings > Connected Devices and select "Update Firmware". Ensure the device remains plugged into power.',
    aiInsight: 'This update reduces accidental cry alerts triggered by background fans or white noise machines by 35%.',
    section: 'Earlier'
  },
  {
    id: '25',
    title: 'AI Health Insight Ready',
    description: 'Excellent heart-rate-to-temperature correlation.',
    timestamp: 'Earlier',
    isRead: true,
    category: 'reports',
    priority: 'low',
    deviceResponsible: 'Maatriva AI Engine',
    sensorResponsible: 'Biometric Correlation Classifier',
    detailedExplanation: "The deep learning system has analyzed Chloe's resting metrics over the last 30 days and noted outstanding consistency.",
    recommendedAction: 'Check out the AI Assistant tab to read the full report on pediatric wellness trends.',
    aiInsight: 'Stable heart patterns demonstrate excellent autonomic nervous system development. Keep doing what you\'re doing!',
    section: 'Earlier'
  }
];

export const PhoneSimulator: React.FC<PhoneSimulatorProps> = ({
  metrics,
  onMetricsChange,
  onGenerateAIInsight
}) => {
  const [activeTab, setActiveTab] = useState<number>(0);
  const [showDrawer, setShowDrawer] = useState<boolean>(false);
  const [showAboutUsModal, setShowAboutUsModal] = useState<boolean>(false);

  // AI Assistant Chat States
  const [chatMessages, setChatMessages] = useState<Array<{ id: string; text: string; isUser: boolean }>>([
    { id: "m1", text: "Hello! I am your Maatriva AI Assistant. How can I help you and baby Chloe today?", isUser: false },
  ]);
  const [chatInput, setChatInput] = useState("");
  const [chatIsTyping, setChatIsTyping] = useState(false);

  const handleSendChatMessage = (text: string) => {
    if (!text.trim()) return;
    const userMsg = { id: `u-${Date.now()}`, text, isUser: true };
    setChatMessages(prev => [...prev, userMsg]);
    setChatInput("");
    setChatIsTyping(true);

    setTimeout(() => {
      let replyText = "I've analyzed Chloe's telemetry data. Her vitals are fully optimal; we suggest a light feeding or gentle sensory interaction.";
      const cleanText = text.toLowerCase();
      if (cleanText.includes("sleep")) {
        replyText = `Chloe slept for ${metrics.sleepHours.toFixed(1)} hours today, which is within the optimal range of 7.5 to 8.5 hours for her age. Sleep stability remains high at 82%.`;
      } else if (cleanText.includes("heart") || cleanText.includes("pulse") || cleanText.includes("vitals")) {
        replyText = `Chloe's heart rate is currently stable at ${metrics.heartRate} bpm. Over the last 24 hours, her vitals have remained steady with no respiratory anomalies detected.`;
      } else if (cleanText.includes("cry") || cleanText.includes("crying")) {
        replyText = `Her today's cry count is ${metrics.cryCount}. We analyzed her cry frequencies and noted typical mild digestive sensitivity. We suggest checking her feeding schedule or room humidity.`;
      }

      const aiMsg = { id: `ai-${Date.now()}`, text: replyText, isUser: false };
      setChatMessages(prev => [...prev, aiMsg]);
      setChatIsTyping(false);
    }, 1000);
  };

  // Onboarding & Setup States
  const [showOnboarding, setShowOnboarding] = useState<boolean>(true);
  const [onboardingStep, setOnboardingStep] = useState<number>(0);
  const [allowedPermissions, setAllowedPermissions] = useState<Record<string, boolean>>({
    Camera: false,
    Microphone: false,
    Notifications: false,
    Bluetooth: false,
    "Wi-Fi": false,
    Location: false,
  });
  const [cradleScanState, setCradleScanState] = useState<"idle" | "scanning" | "found" | "connected">("idle");
  const [connectedCradleId, setConnectedCradleId] = useState<string | null>(null);
  const [showQrDialog, setShowQrDialog] = useState<boolean>(false);
  const [showManualDialog, setShowManualDialog] = useState<boolean>(false);
  const [manualCode, setManualCode] = useState<string>("");

  // Notifications States
  const [notifications, setNotifications] = useState<NotificationItem[]>(MOCK_NOTIFICATIONS);
  const [selectedNotification, setSelectedNotification] = useState<NotificationItem | null>(null);
  const [showNotifications, setShowNotifications] = useState(false);
  const [showMusicPlayer, setShowMusicPlayer] = useState(false);
  const [notifCategory, setNotifCategory] = useState("All");

  // Simulated Baby Music Player states
  const [simIsPlaying, setSimIsPlaying] = useState(false);
  const [simCurrentSong, setSimCurrentSong] = useState({
    id: "s1",
    title: "Sweet Sleep Chopin Waltz",
    artist: "Maatriva Acoustic Trio",
    category: "Lullabies",
    duration: 225,
    color: "purple"
  });
  const [simPosition, setSimPosition] = useState(45);
  const [simSpeed, setSimSpeed] = useState("1.0x");
  const [simTimer, setSimTimer] = useState<number | null>(null);
  const [simSearch, setSimSearch] = useState("");
  const [simCategory, setSimCategory] = useState("All");
  const [simFavs, setSimFavs] = useState<string[]>(["s1", "s3", "s5"]);
  const [simVolume, setSimVolume] = useState(70);
  const [notifSearch, setNotifSearch] = useState("");

  // Shop States
  const [shopView, setShopView] = useState<"catalog" | "cart" | "wishlist" | "details">("catalog");
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [detailQty, setDetailQty] = useState(1);
  const [detailSpecTab, setDetailSpecTab] = useState<"features" | "specs">("features");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [showFilterSheet, setShowFilterSheet] = useState(false);
  const [sortOption, setSortOption] = useState("Popular");
  const [priceRange, setPriceRange] = useState<number>(200);

  // Cart & Wishlist local state preloads to align with Flutter preloads!
  const [cart, setCart] = useState<{product: Product; quantity: number}[]>([
    { product: MOCK_PRODUCTS[1], quantity: 2 } // Soft Touch Pacifier x2 matching badge & screenshot
  ]);
  const [wishlist, setWishlist] = useState<string[]>(["p2"]); // Pacifier pre-favored
  const [promoCode, setPromoCode] = useState("");
  const [promoApplied, setPromoApplied] = useState(false);

  // Caregiver Access States (implemented in previous session)
  const [selectedDuration, setSelectedDuration] = useState("4 Hours");
  const [permissions, setPermissions] = useState({
    videoStream: true,
    audioCrying: true,
    biometrics: true,
    smartAlerts: false,
    musicControl: false
  });
  const [sessions, setSessions] = useState([
    { id: 1, name: "Grandma Miller", type: "Family Member", duration: "24 Hours", active: true },
    { id: 2, name: "Nanny Clara", type: "Trusted Caregiver", duration: "12 Hours", active: true }
  ]);

  // Profile & Settings States
  const [profileView, setProfileView] = useState<"menu" | "edit" | "parent" | "baby" | "devices" | "caregiver" | "medical" | "notifications" | "privacy" | "help">("menu");
  const [parentName, setParentName] = useState("Sarah Johnson");
  const [parentEmail, setParentEmail] = useState("sarah.johnson@maatriva.com");
  const [parentPhone, setParentPhone] = useState("+1 (555) 342-9841");
  const [partnerName, setPartnerName] = useState("David Johnson");
  const [partnerPhone, setPartnerPhone] = useState("+1 (555) 342-9842");
  const [emergencyName, setEmergencyName] = useState("Grandma Martha");
  const [emergencyPhone, setEmergencyPhone] = useState("+1 (555) 987-6543");
  const [babyName, setBabyName] = useState("Chloe");
  const [babyDob, setBabyDob] = useState("October 12, 2025");
  const [babyGender, setBabyGender] = useState("Female");
  const [babyWeight, setBabyWeight] = useState(6.4);
  const [babyHeight, setBabyHeight] = useState(62.0);
  const [pediatricianName, setPediatricianName] = useState("Dr. Evelyn Carter");
  const [pediatricianPhone, setPediatricianPhone] = useState("+1 (555) 123-4567");
  const [allergies, setAllergies] = useState("None diagnosed. Peanut monitoring in progress.");
  const [vaccines, setVaccines] = useState([
    { id: "v1", name: "Hepatitis B (HepB)", ageDue: "Birth", status: "Administered", dateAdministered: "10/12/2025" },
    { id: "v2", name: "Rotavirus (RV)", ageDue: "2 Months", status: "Administered", dateAdministered: "12/15/2025" },
    { id: "v3", name: "DTaP (Diphtheria, Tetanus, Pertussis)", ageDue: "2 Months", status: "Administered", dateAdministered: "12/15/2025" },
    { id: "v4", name: "Haemophilus influenzae type b (Hib)", ageDue: "4 Months", status: "Administered", dateAdministered: "02/16/2026" },
    { id: "v5", name: "Pneumococcal Conjugate (PCV13)", ageDue: "6 Months", status: "Pending", dateAdministered: "--" },
    { id: "v6", name: "Inactivated Poliovirus (IPV)", ageDue: "6 Months", status: "Pending", dateAdministered: "--" }
  ]);
  const [devices, setDevices] = useState([
    { id: "d1", name: "Maatriva Smart Cam 4K", type: "Camera", isConnected: true, battery: -1 },
    { id: "d2", name: "Maatriva Smart Sock V2", type: "Smart Sock", isConnected: true, battery: 82 },
    { id: "d3", name: "Maatriva Nursery Hub", type: "Hub", isConnected: false, battery: -1 }
  ]);
  const [notifPrefs, setNotifPrefs] = useState({
    cryAlerts: true,
    abnormalHeartRate: true,
    tempAlerts: true,
    feedingReminders: false,
    sleepAnalysis: true
  });
  const [privacyPrefs, setPrivacyPrefs] = useState({
    twoFactor: false,
    biometrics: true,
    sharePediatrician: true
  });
  const [helpSearch, setHelpSearch] = useState("");
  const [pairedProgress, setPairedProgress] = useState(0);
  const [isPairing, setIsPairing] = useState(false);

  // Simulated Predictive Health states
  const [simStabilityScore, setSimStabilityScore] = useState<number>(82);
  const [simStabilityInsight, setSimStabilityInsight] = useState<string>(
    "Maatriva's analysis suggests a consistent pattern of night-time restlessness combined with slight temperature fluctuations. This pattern is often a precursor to teething or mild digestive sensitivity. We've noted increased cardiac variability during the 3 AM window over the last 4 nights."
  );
  const [simIsAnalyzing, setSimIsAnalyzing] = useState<boolean>(false);

  const handleSimAIAnalysis = () => {
    setSimIsAnalyzing(true);
    setTimeout(() => {
      setSimIsAnalyzing(false);
      setSimStabilityScore(85);
      setSimStabilityInsight(
        "AI Update: Analysis completed. Recent readings show stabilization in cardiac rhythm during quiet sleep. Mild temperature variance remains, confirming typical teething progression. Continue monitoring nighttime room humidity."
      );
    }, 1500);
  };

  // Formatters
  const formattedTime = "11:47 PM";

  const toggleBabyStatus = () => {
    let nextStatus: "Sleeping" | "Awake" | "Crying" = "Sleeping";
    let nextHeartRate = 115;
    let nextTemp = 24.0;
    let nextCries = metrics.cryCount;

    if (metrics.babyStatus === "Sleeping") {
      nextStatus = "Awake";
      nextHeartRate = 128;
      nextTemp = 24.4;
    } else if (metrics.babyStatus === "Awake") {
      nextStatus = "Crying";
      nextHeartRate = 145;
      nextTemp = 25.1;
      nextCries += 1;
    } else {
      nextStatus = "Sleeping";
      nextHeartRate = 108;
      nextTemp = 23.8;
    }

    onMetricsChange({
      babyStatus: nextStatus,
      heartRate: nextHeartRate,
      temperature: nextTemp,
      cryCount: nextCries
    });
  };

  // Cart helper functions
  const handleAddToCart = (product: Product, qty = 1) => {
    setCart(prev => {
      const idx = prev.findIndex(item => item.product.id === product.id);
      if (idx >= 0) {
        const copy = [...prev];
        copy[idx].quantity += qty;
        return copy;
      }
      return [...prev, { product, quantity: qty }];
    });
  };

  const handleToggleWishlist = (id: string) => {
    setWishlist(prev => 
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    );
  };

  const cartTotalItems = cart.reduce((sum, item) => sum + item.quantity, 0);
  const cartSubtotal = cart.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
  const deliveryFee = cartSubtotal > 50 ? 0 : 5;
  const promoDiscount = promoApplied ? cartSubtotal * 0.2 : 0;
  const cartTotal = cartSubtotal + deliveryFee - promoDiscount;

  return (
    <div className="relative mx-auto w-full max-w-[385px] h-[820px] bg-neutral-900 rounded-[55px] p-3 shadow-2xl border-4 border-neutral-800 ring-12 ring-neutral-950 flex flex-col overflow-hidden select-none">
      
      {/* Phone Notch */}
      <div className="absolute top-3 left-1/2 -translate-x-1/2 w-40 h-[30px] bg-neutral-900 rounded-b-3xl z-50 flex items-center justify-center">
        <div className="w-16 h-1 bg-neutral-800 rounded-full mb-1"></div>
        <div className="absolute right-4 w-2 h-2 bg-neutral-950 rounded-full mb-1 border border-neutral-800"></div>
      </div>

      {/* Screen Container */}
      <div className="w-full h-full bg-[#FBF8FD] rounded-[44px] overflow-hidden flex flex-col relative pt-8 pb-4">
        
        {/* iOS style Top Status bar */}
        <div className="absolute top-2 left-0 right-0 px-8 flex justify-between items-center text-xs text-indigo-950 font-bold z-40 font-sans">
          <span>{formattedTime}</span>
          <div className="flex items-center gap-1.5">
            <Wifi className="w-3.5 h-3.5 stroke-[2.5]" />
            <span className="text-[10px]">5G</span>
            <Battery className="w-4 h-4 stroke-[2]" />
          </div>
        </div>

        {/* --- MAIN SCROLLABLE CONTENT AREA --- */}
        <div className="flex-1 overflow-y-auto px-4 pt-3 pb-24">
          
          {/* ========================================================================= */}
          {/* TAB 0: HOME / DASHBOARD SCREEN */}
          {/* ========================================================================= */}
          {activeTab === 0 && (
            <div className="space-y-5">
              {/* Header */}
              <div className="flex items-center justify-between bg-white p-3.5 rounded-2xl border border-indigo-50 shadow-sm">
                <div className="flex items-center gap-2.5">
                  <button 
                    onClick={() => setShowDrawer(true)}
                    className="p-1.5 hover:bg-indigo-50 rounded-lg text-indigo-600 transition-colors cursor-pointer"
                  >
                    <Menu className="w-5 h-5 stroke-[2.5]" />
                  </button>
                  <div className="text-left">
                    <h1 className="text-sm font-bold tracking-tight text-indigo-900 leading-tight">Maatriva</h1>
                    <p className="text-[8px] uppercase tracking-widest text-indigo-400 font-semibold">AI Smart Monitor</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex items-center gap-1 px-2 py-0.5 bg-emerald-50 rounded-full border border-emerald-100">
                    <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
                    <span className="text-[9px] font-bold text-emerald-700">Live</span>
                  </div>
                  <div 
                    onClick={() => setShowNotifications(true)}
                    className="relative p-1.5 bg-indigo-50 hover:bg-indigo-100 rounded-full transition-colors cursor-pointer"
                  >
                    <Bell className="w-3.5 h-3.5 text-indigo-600" />
                    {notifications.some(n => !n.isRead) && (
                      <span className="absolute top-1 right-1 w-1.5 h-1.5 bg-indigo-600 rounded-full animate-pulse"></span>
                    )}
                  </div>
                </div>
              </div>

              {/* Greeting */}
              <div className="px-1">
                <h2 className="text-lg font-black text-gray-900 tracking-tight leading-tight">
                  Good Morning, <span className="text-indigo-600">{metrics.motherName}</span>
                </h2>
                <p className="text-[11px] text-gray-500 mt-1">
                  {metrics.babyStatus === "Sleeping" && "Theo is sleeping peacefully in the smart crib."}
                  {metrics.babyStatus === "Awake" && "Theo is relaxed and happily awake."}
                  {metrics.babyStatus === "Crying" && "Baby alert: Theo is crying inside the nursery!"}
                </p>
              </div>

              {/* Quick Status Chips */}
              <div className="flex gap-2 overflow-x-auto no-scrollbar py-0.5 px-1">
                <button 
                  onClick={toggleBabyStatus}
                  className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[9px] font-bold uppercase tracking-wider border transition-all duration-300 ${
                    metrics.babyStatus === "Sleeping" ? "bg-emerald-50 text-emerald-700 border-emerald-100" :
                    metrics.babyStatus === "Awake" ? "bg-amber-50 text-amber-700 border-amber-100" :
                    "bg-red-50 text-red-700 border-red-100 animate-pulse"
                  }`}
                >
                  <span className={`w-1.5 h-1.5 rounded-full ${metrics.babyStatus === "Sleeping" ? "bg-emerald-500" : metrics.babyStatus === "Awake" ? "bg-amber-500" : "bg-red-500"}`}></span>
                  <span>{metrics.babyStatus}</span>
                </button>
                <div className="flex items-center gap-1.5 px-3 py-1 rounded-full text-[9px] font-bold uppercase tracking-wider bg-indigo-50 text-indigo-700 border border-indigo-100">
                  <ShieldCheck className="w-3 h-3 text-indigo-600" />
                  <span>{metrics.health}</span>
                </div>
                <div className="flex items-center gap-1.5 px-3 py-1 rounded-full text-[9px] font-bold uppercase tracking-wider bg-blue-50 text-blue-700 border border-blue-100">
                  <Wifi className="w-3 h-3 text-blue-600" />
                  <span>Online</span>
                </div>
              </div>

              {/* Camera Video Stream */}
              <div className="relative w-full aspect-[16/10] bg-slate-950 rounded-[22px] overflow-hidden shadow-md border border-indigo-50">
                {metrics.babyStatus === "Sleeping" && (
                  <img src="https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=400&q=80" className="w-full h-full object-cover opacity-60 grayscale" alt="Crib" />
                )}
                {metrics.babyStatus === "Awake" && (
                  <img src="https://images.unsplash.com/photo-1596464716127-f2a82984de30?auto=format&fit=crop&w=400&q=80" className="w-full h-full object-cover opacity-70" alt="Awake baby" />
                )}
                {metrics.babyStatus === "Crying" && (
                  <div className="relative w-full h-full">
                    <img src="https://images.unsplash.com/photo-1519689680058-324335c77ebe?auto=format&fit=crop&w=400&q=80" className="w-full h-full object-cover opacity-60 grayscale saturate-150" alt="Crying baby" />
                    <div className="absolute inset-0 bg-red-600/10 animate-pulse flex items-center justify-center">
                      <div className="bg-neutral-900/90 text-red-500 px-2.5 py-1.5 rounded-lg text-[9px] font-bold uppercase tracking-widest border border-red-500/30 flex items-center gap-1">
                        <AlertTriangle className="w-3 h-3 animate-bounce" /> CRY ALERT
                      </div>
                    </div>
                  </div>
                )}
                <div className="absolute top-2 left-2 bg-red-600/80 px-2 py-0.5 rounded text-white text-[7px] font-bold tracking-widest">LIVE</div>
                <div className="absolute bottom-2 left-2 right-2 bg-black/40 backdrop-blur-sm rounded-lg p-2 flex justify-between text-white text-center text-[10px] font-bold border border-white/5">
                  <div>
                    <span className="block text-[6px] text-white/60 font-medium">TEMP</span>
                    {metrics.temperature.toFixed(1)}°C
                  </div>
                  <div className="w-px h-4 bg-white/20"></div>
                  <div>
                    <span className="block text-[6px] text-white/60 font-medium">HUMID</span>
                    48%
                  </div>
                  <div className="w-px h-4 bg-white/20"></div>
                  <div>
                    <span className="block text-[6px] text-white/60 font-medium">NOISE</span>
                    {metrics.babyStatus === "Crying" ? "74 dB" : "32 dB"}
                  </div>
                </div>
              </div>

              {/* Biometrics Grid */}
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-white p-3 rounded-2xl border border-indigo-50 shadow-sm">
                  <span className="text-[8px] font-bold text-slate-400 uppercase tracking-wider block mb-1">Temperature</span>
                  <div className="flex justify-between items-end">
                    <span className="text-base font-black text-slate-800">{metrics.temperature.toFixed(1)}°C</span>
                    <span className="text-[8px] text-emerald-600 font-bold bg-emerald-50 px-1.5 py-0.5 rounded">Optimal</span>
                  </div>
                </div>
                <div className="bg-white p-3 rounded-2xl border border-indigo-50 shadow-sm">
                  <span className="text-[8px] font-bold text-slate-400 uppercase tracking-wider block mb-1">Heart Rate</span>
                  <div className="flex justify-between items-end">
                    <span className="text-base font-black text-slate-800">{metrics.heartRate} bpm</span>
                    <span className={`text-[8px] font-bold bg-indigo-50 px-1.5 py-0.5 rounded ${metrics.babyStatus === "Crying" ? "text-red-600 bg-red-50" : "text-emerald-600 bg-emerald-50"}`}>
                      {metrics.babyStatus === "Crying" ? "Active" : "Steady"}
                    </span>
                  </div>
                </div>
              </div>

              {/* AI Insight banner */}
              <div className="bg-indigo-600 text-white rounded-2xl p-4 shadow-md relative overflow-hidden">
                <div className="flex items-start gap-3">
                  <div className="p-2 bg-white/10 rounded-lg">
                    <Sparkles className="w-4 h-4 text-white" />
                  </div>
                  <div className="flex-1">
                    <div className="flex justify-between items-center mb-1">
                      <span className="text-xs font-bold text-indigo-50">AI Nurse Consultant</span>
                      <button onClick={onGenerateAIInsight} className="p-0.5 hover:bg-white/10 rounded">
                        <RefreshCw className="w-3 h-3 text-white" />
                      </button>
                    </div>
                    <p className="text-[11px] text-indigo-100 leading-relaxed">{metrics.aiInsight}</p>
                  </div>
                </div>
              </div>

              {/* Interactive Baby Music Player Quick Card */}
              <div className="bg-white border border-indigo-50 p-4 rounded-[24px] shadow-sm text-left">
                <div className="flex items-center justify-between mb-3">
                  <h4 className="text-xs font-black text-slate-800 flex items-center gap-1.5">
                    <Music className="w-4 h-4 text-indigo-600" /> Baby Music Soother
                  </h4>
                  <span className="text-[8px] bg-indigo-50 text-indigo-600 font-bold px-1.5 py-0.5 rounded uppercase tracking-wider">Premium Library</span>
                </div>
                <div className="flex items-center justify-between bg-[#FAF7FF] p-2.5 rounded-2xl border border-indigo-50">
                  <div className="flex items-center gap-2.5">
                    <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-400 flex items-center justify-center text-white text-xs font-bold shadow-sm">
                      {simIsPlaying ? "🔊" : "🎵"}
                    </div>
                    <div>
                      <h5 className="text-[11px] font-bold text-slate-800 truncate max-w-[130px]">{simCurrentSong.title}</h5>
                      <p className="text-[9px] text-slate-400 truncate max-w-[130px]">{simCurrentSong.artist}</p>
                    </div>
                  </div>
                  <button 
                    onClick={() => setShowMusicPlayer(true)}
                    className="bg-indigo-600 hover:bg-indigo-700 text-white text-[10px] font-bold px-3.5 py-2 rounded-xl shadow-xs transition-colors cursor-pointer"
                  >
                    Play Music
                  </button>
                </div>
              </div>

              {/* Quick Actions Grid */}
              <div className="space-y-3 text-left">
                <h4 className="text-xs font-black text-slate-800">Quick Actions</h4>
                <div className="grid grid-cols-3 gap-2.5">
                  <div 
                    onClick={() => setActiveTab(1)}
                    className="bg-white border border-indigo-50 p-3 rounded-2xl text-center cursor-pointer hover:bg-indigo-50/20 shadow-sm flex flex-col items-center justify-center gap-1.5"
                  >
                    <div className="w-8 h-8 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center">
                      <Video className="w-4 h-4" />
                    </div>
                    <span className="text-[9.5px] font-bold text-slate-700">Live Feed</span>
                  </div>

                  <div 
                    onClick={() => setActiveTab(4)}
                    className="bg-white border border-indigo-50 p-3 rounded-2xl text-center cursor-pointer hover:bg-indigo-50/20 shadow-sm flex flex-col items-center justify-center gap-1.5"
                  >
                    <div className="w-8 h-8 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center">
                      <Bot className="w-4 h-4" />
                    </div>
                    <span className="text-[9.5px] font-bold text-slate-700">AI Assistant</span>
                  </div>

                  <div 
                    onClick={() => setActiveTab(2)}
                    className="bg-white border border-indigo-50 p-3 rounded-2xl text-center cursor-pointer hover:bg-indigo-50/20 shadow-sm flex flex-col items-center justify-center gap-1.5"
                  >
                    <div className="w-8 h-8 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center">
                      <Heart className="w-4 h-4 text-rose-500 fill-rose-500" />
                    </div>
                    <span className="text-[9.5px] font-bold text-slate-700">Health</span>
                  </div>

                  <div 
                    onClick={() => alert("Initiating call with Pediatrician...")}
                    className="bg-white border border-indigo-50 p-3 rounded-2xl text-center cursor-pointer hover:bg-indigo-50/20 shadow-sm flex flex-col items-center justify-center gap-1.5"
                  >
                    <div className="w-8 h-8 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center">
                      <BriefcaseMedical className="w-4 h-4 text-emerald-600" />
                    </div>
                    <span className="text-[9.5px] font-bold text-slate-700">Doctor</span>
                  </div>

                  <div 
                    onClick={() => { setActiveTab(5); setProfileView("caregiver"); }}
                    className="bg-white border border-indigo-50 p-3 rounded-2xl text-center cursor-pointer hover:bg-indigo-50/20 shadow-sm flex flex-col items-center justify-center gap-1.5"
                  >
                    <div className="w-8 h-8 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center">
                      <Share2 className="w-4 h-4 text-blue-500" />
                    </div>
                    <span className="text-[9.5px] font-bold text-slate-700">Share Access</span>
                  </div>

                  <div 
                    onClick={() => setShowMusicPlayer(true)}
                    className="bg-white border border-indigo-55/40 p-3 rounded-2xl text-center cursor-pointer hover:bg-indigo-50/20 shadow-sm flex flex-col items-center justify-center gap-1.5"
                  >
                    <div className="w-8 h-8 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center">
                      <Music className="w-4 h-4" />
                    </div>
                    <span className="text-[9.5px] font-bold text-slate-700">Music</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB 1: LIVE MONITORING VIEW */}
          {/* ========================================================================= */}
          {activeTab === 1 && (
            <div className="space-y-4">
              <div className="text-center py-2">
                <h3 className="text-sm font-bold text-slate-800">Crib Live Feed</h3>
                <p className="text-[9px] text-slate-400">Stream encrypted via smart home container</p>
              </div>

              {/* Full Camera stream */}
              <div className="relative aspect-video bg-neutral-950 rounded-2xl overflow-hidden border border-indigo-50/50 flex flex-col justify-between p-3">
                <img src="https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=400&q=80" className="absolute inset-0 w-full h-full object-cover opacity-40 grayscale" alt="Stream" />
                <div className="flex justify-between z-10">
                  <span className="bg-red-500 text-white text-[8px] px-1.5 py-0.5 rounded font-black tracking-widest animate-pulse">LIVE FEED</span>
                  <span className="text-white text-[8px] bg-black/40 px-1 rounded">1080p 30FPS</span>
                </div>
                <div className="z-10 flex justify-between items-end text-white text-[10px] font-bold">
                  <span className="bg-black/50 px-2 py-0.5 rounded-full flex items-center gap-1"><Thermometer className="w-3 h-3 text-blue-400" /> {metrics.temperature}°C</span>
                  <span className="bg-black/50 px-2 py-0.5 rounded-full flex items-center gap-1"><Heart className="w-3 h-3 text-red-500 animate-pulse" /> {metrics.heartRate} BPM</span>
                </div>
              </div>

              {/* Micro Biometrics Tracking Graph */}
              <div className="bg-white border border-indigo-50 p-4 rounded-2xl shadow-sm">
                <h4 className="text-xs font-bold text-slate-800 mb-3 flex items-center justify-between">
                  <span>Heart Beat Analytics</span>
                  <span className="text-[8px] text-emerald-500 font-bold bg-emerald-50 px-1 rounded uppercase">Continuous</span>
                </h4>
                {/* SVG Mock ECG Sparkline */}
                <div className="h-16 flex items-center justify-center">
                  <svg className="w-full h-12 stroke-red-500 stroke-2 fill-none" viewBox="0 0 100 20">
                    <path d="M0 10 h10 l5 -8 l5 15 l3 -7 l15 0 l4 -6 l5 12 l3 -6 l15 0 l6 -7 l3 14 l4 -7 l15 0" />
                  </svg>
                </div>
                <p className="text-[9px] text-center text-slate-400 mt-2 font-semibold">ECG variance stable • No anomalies detected</p>
              </div>

              {/* Smart Sleep Soother Lullabies */}
              <div className="bg-white border border-indigo-50 p-4 rounded-2xl shadow-sm">
                <h4 className="text-xs font-bold text-slate-800 mb-3 flex items-center gap-1.5"><Music className="w-3.5 h-3.5 text-indigo-500" /> Sleep Soother Lullabies</h4>
                <div className="space-y-2">
                  <div className="flex items-center justify-between p-2 bg-indigo-50/50 rounded-xl">
                    <span className="text-xs font-semibold text-slate-700">🌲 Forest Rainfall Wind</span>
                    <button className="bg-indigo-600 text-white text-[9px] px-3 py-1 rounded-full font-bold">Play</button>
                  </div>
                  <div className="flex items-center justify-between p-2 bg-indigo-50/50 rounded-xl">
                    <span className="text-xs font-semibold text-slate-700">🎹 Sweet Sleep Chopin Waltz</span>
                    <button className="bg-indigo-600 text-white text-[9px] px-3 py-1 rounded-full font-bold">Play</button>
                  </div>
                  <div className="flex items-center justify-between p-2 bg-indigo-50/50 rounded-xl">
                    <span className="text-xs font-semibold text-slate-700">🤍 Gentle Mother White Noise</span>
                    <button className="bg-indigo-50 border border-indigo-200 text-indigo-600 text-[9px] px-3 py-1 rounded-full font-bold">Playing</button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB 2: PREDICTIVE HEALTH / CLINICAL ILLNESS DETECTOR */}
          {/* ========================================================================= */}
          {activeTab === 2 && (
            <div className="space-y-5">
              
              {/* Header */}
              <div className="flex items-center justify-between bg-white p-3.5 rounded-2xl border border-indigo-50 shadow-sm">
                <div className="flex items-center gap-2">
                  <button 
                    onClick={() => setActiveTab(0)}
                    className="p-1 hover:bg-slate-100 rounded-full"
                  >
                    <ArrowLeft className="w-4 h-4 text-indigo-600" />
                  </button>
                  <div className="w-8 h-8 rounded-full border border-indigo-100 overflow-hidden shadow-xs">
                    <img 
                      src="https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=120" 
                      className="w-full h-full object-cover" 
                      alt="Sarah avatar"
                    />
                  </div>
                  <div className="text-left">
                    <h3 className="text-xs font-black text-indigo-900 leading-tight">Predictive Health</h3>
                    <p className="text-[8px] font-semibold text-slate-400">AI Diagnostic Monitor</p>
                  </div>
                </div>
                <div className="flex items-center gap-1.5">
                  <button 
                    onClick={() => alert("Report shared with pediatrician.")}
                    className="p-1.5 hover:bg-slate-100 rounded-full"
                  >
                    <Share2 className="w-4 h-4 text-slate-500" />
                  </button>
                  <button 
                    onClick={() => setActiveTab(5)}
                    className="p-1.5 hover:bg-slate-100 rounded-full cursor-pointer"
                  >
                    <Sliders className="w-4 h-4 text-slate-500" />
                  </button>
                </div>
              </div>

              {/* System Stability Index Card */}
              <div className="bg-white rounded-3xl p-5 border border-indigo-50/50 shadow-xs relative overflow-hidden text-left">
                <div className="flex justify-between items-start">
                  <div>
                    <span className="inline-block text-[9px] bg-indigo-50 text-indigo-600 font-bold uppercase px-2 py-0.5 rounded-md mb-2">
                      AI Diagnostic Insight
                    </span>
                    <h4 className="text-base font-black text-slate-800 tracking-tight leading-tight">
                      System Stability<br />Index
                    </h4>
                  </div>
                  {/* Circle Gauge */}
                  <div className="relative w-16 h-16 flex items-center justify-center">
                    <svg className="w-full h-full transform -rotate-90">
                      <circle cx="32" cy="32" r="26" stroke="#F1EEFA" strokeWidth="5" fill="transparent" />
                      <circle cx="32" cy="32" r="26" stroke="#6E3DE0" strokeWidth="5" fill="transparent" 
                        strokeDasharray={2 * Math.PI * 26} 
                        strokeDashoffset={2 * Math.PI * 26 * (1 - simStabilityScore / 100)} 
                      />
                    </svg>
                    <span className="absolute text-base font-black text-indigo-600">{simStabilityScore}</span>
                  </div>
                </div>
                
                <p className="text-[11px] text-slate-500 mt-3 leading-relaxed font-medium">
                  "{simStabilityInsight}"
                </p>

                <button 
                  onClick={handleSimAIAnalysis}
                  disabled={simIsAnalyzing}
                  className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white font-bold text-xs py-2.5 px-4 rounded-xl mt-4 flex items-center justify-center gap-2 shadow-xs transition-all cursor-pointer"
                >
                  {simIsAnalyzing ? (
                    <RefreshCw className="w-3.5 h-3.5 animate-spin text-white" />
                  ) : (
                    <Sparkles className="w-3.5 h-3.5 text-white" />
                  )}
                  <span>Generate Full AI Analysis</span>
                </button>
              </div>

              {/* Vitals Pills Row */}
              <div className="flex gap-2">
                <div className="flex-1 bg-white p-3 rounded-2xl border border-indigo-50/50 shadow-xs text-center">
                  <span className="text-[8px] font-bold text-slate-400 block mb-1">Respiratory</span>
                  <span className="text-xs font-black text-emerald-600 block">Stable</span>
                </div>
                <div className="flex-1 bg-white p-3 rounded-2xl border border-indigo-50/50 shadow-xs text-center">
                  <span className="text-[8px] font-bold text-slate-400 block mb-1">Cardiac</span>
                  <span className="text-xs font-black text-blue-600 block">Normal</span>
                </div>
                <div className="flex-1 bg-white p-3 rounded-2xl border border-indigo-50/50 shadow-xs text-center">
                  <span className="text-[8px] font-bold text-slate-400 block mb-1">Temp</span>
                  <span className="text-xs font-black text-red-500 block">Fluctuating</span>
                </div>
              </div>

              {/* Potential Chronic Patterns */}
              <div className="space-y-3">
                <div className="flex justify-between items-center px-1">
                  <h4 className="text-xs font-black text-slate-800">Potential Chronic Patterns</h4>
                  <Sliders className="w-3.5 h-3.5 text-indigo-500 transform rotate-90" />
                </div>

                {/* Pattern 1 */}
                <div className="bg-white p-4 rounded-3xl border border-indigo-50/40 shadow-xs text-left">
                  <div className="flex justify-between items-start">
                    <div className="flex gap-3">
                      <div className="w-8 h-8 rounded-full bg-blue-50 flex items-center justify-center text-blue-600 text-sm">
                        <Moon className="w-4 h-4" />
                      </div>
                      <div>
                        <h5 className="text-[11.5px] font-bold text-slate-800">Chronic Sleep Fragmentation</h5>
                        <p className="text-[9.5px] text-slate-500 mt-1 leading-tight">
                          Frequent micro-arousals detected without full waking. Sensor data shows 12% drop in deep sleep phase.
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className="text-[11px] font-black text-red-500 block">68%</span>
                      <span className="text-[8px] text-slate-400 font-bold block">Prob.</span>
                    </div>
                  </div>
                  <div className="mt-3 bg-indigo-50/40 p-2 rounded-xl flex items-center gap-1.5 text-indigo-600">
                    <Clock className="w-3 h-3 text-indigo-500" />
                    <span className="text-[9px] font-bold">Sensor Evidence: Disrupted REM since Mar 12</span>
                  </div>
                </div>

                {/* Pattern 2 */}
                <div className="bg-white p-4 rounded-3xl border border-indigo-50/40 shadow-xs text-left">
                  <div className="flex justify-between items-start">
                    <div className="flex gap-3">
                      <div className="w-8 h-8 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600 text-sm">
                        <Thermometer className="w-4 h-4" />
                      </div>
                      <div>
                        <h5 className="text-[11.5px] font-bold text-slate-800">Cyclic Fever Pattern</h5>
                        <p className="text-[9.5px] text-slate-500 mt-1 leading-tight">
                          Temperature spikes detected approximately every 14 days. Likely biological growth spurts.
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className="text-[11px] font-black text-blue-600 block">24%</span>
                      <span className="text-[8px] text-slate-400 font-bold block">Prob.</span>
                    </div>
                  </div>
                  <div className="mt-3 bg-indigo-50/40 p-2 rounded-xl flex items-center gap-1.5 text-indigo-600">
                    <Heart className="w-3 h-3 text-indigo-500" />
                    <span className="text-[9px] font-bold">Evidence: Peaks at 101.2°F recurring</span>
                  </div>
                </div>
              </div>

              {/* Correlation Trends (30 Days) */}
              <div className="bg-white p-4 rounded-3xl border border-indigo-50/50 shadow-xs text-left">
                <h4 className="text-xs font-black text-slate-800 mb-3">Correlation Trends (30 Days)</h4>
                
                {/* Visual Chart Bars */}
                <div className="h-28 flex items-end justify-between px-2 pt-2 border-b border-slate-100 relative">
                  {/* Grid background lines */}
                  <div className="absolute inset-x-0 top-1/4 h-px bg-slate-50"></div>
                  <div className="absolute inset-x-0 top-2/4 h-px bg-slate-50"></div>
                  <div className="absolute inset-x-0 top-3/4 h-px bg-slate-50"></div>
                  
                  {/* Side-by-side vertical columns */}
                  {[
                    { hr: 45, temp: 35 },
                    { hr: 55, temp: 40 },
                    { hr: 65, temp: 50 },
                    { hr: 75, temp: 70 },
                    { hr: 60, temp: 55 },
                    { hr: 50, temp: 45 },
                    { hr: 45, temp: 38 }
                  ].map((bar, idx) => (
                    <div key={idx} className="flex items-end gap-0.5 h-full z-10">
                      {/* HR Bar - Purple */}
                      <div 
                        className="w-2.5 bg-indigo-300 rounded-t-sm transition-all duration-500"
                        style={{ height: `${bar.hr}%` }}
                      ></div>
                      {/* Temp Bar - Blue */}
                      <div 
                        className="w-2.5 bg-blue-600 rounded-t-sm transition-all duration-500"
                        style={{ height: `${bar.temp}%` }}
                      ></div>
                    </div>
                  ))}
                </div>
                
                {/* Legend */}
                <div className="flex justify-center gap-4 mt-2">
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-indigo-300"></span>
                    <span className="text-[9px] text-slate-400 font-bold">Heart Rate</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-blue-600"></span>
                    <span className="text-[9px] text-slate-400 font-bold">Body Temp</span>
                  </div>
                </div>
              </div>

              {/* Preventive Recommendations */}
              <div className="space-y-2 text-left">
                <h4 className="text-xs font-black text-slate-800 px-1">Preventive Recommendations</h4>
                <div className="bg-indigo-50/50 p-3 rounded-2xl flex items-center gap-3">
                  <div className="w-7 h-7 bg-white text-indigo-600 rounded-full flex items-center justify-center shadow-xs flex-shrink-0">
                    <Smile className="w-4 h-4" />
                  </div>
                  <p className="text-[9.5px] text-slate-700 leading-tight">
                    Adjust nursery humidity to <b>50%</b> to reduce nighttime respiratory stress.
                  </p>
                </div>
                <div className="bg-indigo-50/50 p-3 rounded-2xl flex items-center gap-3">
                  <div className="w-7 h-7 bg-white text-indigo-600 rounded-full flex items-center justify-center shadow-xs flex-shrink-0">
                    <BriefcaseMedical className="w-4 h-4 text-emerald-600" />
                  </div>
                  <p className="text-[9.5px] text-slate-700 leading-tight">
                    Consider a pediatric consult if <b>cough patterns</b> persist for 48 more hours.
                  </p>
                </div>
              </div>

              {/* Consult Doctor Action Button */}
              <button 
                onClick={() => alert("Pediatric consult scheduled.")}
                className="w-full bg-[#4FA0FF] hover:bg-blue-500 text-white font-bold text-xs py-3 px-4 rounded-xl flex items-center justify-center gap-2 shadow-sm transition-colors cursor-pointer"
              >
                <BriefcaseMedical className="w-4 h-4" />
                <span>Consult Doctor</span>
              </button>
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB 3: SHOP SCREEN VIEW (COMPREHENSIVELY INTERACTIVE) */}
          {/* ========================================================================= */}
          {activeTab === 3 && (
            <div className="space-y-4">
              
              {/* --- 2.1 CATALOG VIEW --- */}
              {shopView === "catalog" && (
                <div className="space-y-4">
                  
                  {/* Shop header actions */}
                  <div className="flex justify-between items-center bg-white p-3 rounded-2xl border border-indigo-50 shadow-sm">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center text-white font-bold">S</div>
                      <span className="text-xs font-bold text-indigo-900">Maatriva Shop</span>
                    </div>
                    {/* Cart / Wishlist Badges */}
                    <div className="flex items-center gap-2">
                      <button onClick={() => setShopView("wishlist")} className="p-1.5 bg-indigo-50 rounded-full text-indigo-600 relative">
                        <Heart className="w-4 h-4 fill-indigo-600" />
                        {wishlist.length > 0 && (
                          <span className="absolute -top-1 -right-1 bg-red-500 text-white text-[7px] w-3.5 h-3.5 rounded-full flex items-center justify-center font-bold">
                            {wishlist.length}
                          </span>
                        )}
                      </button>
                      <button onClick={() => setShopView("cart")} className="p-1.5 bg-indigo-50 rounded-full text-indigo-600 relative">
                        <ShoppingCart className="w-4 h-4" />
                        {cartTotalItems > 0 && (
                          <span className="absolute -top-1 -right-1 bg-emerald-500 text-white text-[7px] w-3.5 h-3.5 rounded-full flex items-center justify-center font-bold">
                            {cartTotalItems}
                          </span>
                        )}
                      </button>
                    </div>
                  </div>

                  {/* Search and Filters */}
                  <div className="flex gap-2">
                    <div className="flex-1 bg-white border border-indigo-50 rounded-xl px-2.5 flex items-center gap-2 h-10 shadow-sm">
                      <Search className="w-4 h-4 text-slate-400" />
                      <input 
                        type="text" 
                        placeholder="Search baby essentials..." 
                        className="bg-transparent border-none outline-none text-xs flex-1 text-slate-700" 
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                      />
                    </div>
                    <button onClick={() => setShowFilterSheet(!showFilterSheet)} className="w-10 h-10 bg-indigo-600 text-white rounded-xl flex items-center justify-center shadow-md">
                      <Sliders className="w-4 h-4" />
                    </button>
                  </div>

                  {/* Filter Overlay sheet */}
                  {showFilterSheet && (
                    <div className="bg-white border border-indigo-100 p-3.5 rounded-2xl shadow-lg space-y-3 relative z-30">
                      <h4 className="text-xs font-bold text-slate-800">Advanced Filter & Sort</h4>
                      <div>
                        <span className="text-[10px] text-slate-400 block mb-1 font-bold">SORT PRODUCTS</span>
                        <div className="flex gap-1.5 flex-wrap">
                          {["Popular", "Lowest Price", "Highest Price", "Highest Rated"].map(opt => (
                            <button 
                              key={opt}
                              onClick={() => setSortOption(opt)}
                              className={`text-[9px] font-bold px-2 py-1 rounded-lg border ${sortOption === opt ? "bg-indigo-600 border-indigo-600 text-white" : "border-slate-200 text-slate-600"}`}
                            >
                              {opt}
                            </button>
                          ))}
                        </div>
                      </div>
                      <div>
                        <span className="text-[10px] text-slate-400 block mb-1 font-bold">PRICE LIMIT (${priceRange})</span>
                        <input 
                          type="range" 
                          min="10" 
                          max="200" 
                          value={priceRange} 
                          onChange={(e) => setPriceRange(parseInt(e.target.value))}
                          className="w-full accent-indigo-600 h-1 bg-indigo-50 rounded-lg cursor-pointer"
                        />
                      </div>
                      <button onClick={() => setShowFilterSheet(false)} className="w-full bg-indigo-600 text-white text-[10px] py-1.5 rounded-lg font-bold">Apply Filters</button>
                    </div>
                  )}

                  {/* Featured Banner Offer */}
                  {!searchQuery && selectedCategory === "All" && (
                    <div 
                      onClick={() => {
                        setSelectedProduct(MOCK_PRODUCTS[0]);
                        setDetailQty(1);
                        setShopView("details");
                      }}
                      className="bg-purple-100/70 border border-purple-200 rounded-2xl p-3 flex justify-between items-center cursor-pointer relative overflow-hidden"
                    >
                      <div className="space-y-1.5 z-10 max-w-[60%]">
                        <span className="bg-emerald-600 text-white text-[7px] font-bold px-1.5 py-0.5 rounded">NEW ARRIVAL</span>
                        <h4 className="text-xs font-bold text-indigo-950">Organic Cotton Sleep Set</h4>
                        <p className="text-[9px] text-indigo-600 font-bold">From $45.00</p>
                        <span className="inline-block bg-indigo-600 text-white text-[8px] font-bold px-2 py-0.5 rounded-full">Shop Now</span>
                      </div>
                      <img src="https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=150&q=80" className="w-20 h-20 rounded-xl object-cover shadow-sm border border-white" alt="Featured Sleep Set" />
                    </div>
                  )}

                  {/* Categories list */}
                  <div className="space-y-1.5">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">Categories</span>
                    <div className="flex gap-2 overflow-x-auto no-scrollbar py-0.5">
                      {["All", "Accessories", "Cradle Parts", "Baby Care", "Clothing"].map(cat => {
                        const isSel = selectedCategory === cat;
                        return (
                          <button 
                            key={cat} 
                            onClick={() => setSelectedCategory(cat)}
                            className={`text-[10px] font-bold px-3 py-1 rounded-full whitespace-nowrap border transition-all ${
                              isSel ? "bg-indigo-600 border-indigo-600 text-white shadow-sm" : "bg-white border-slate-100 text-slate-700 hover:bg-slate-50"
                            }`}
                          >
                            {cat}
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  {/* Essentials Product Grid */}
                  <div className="space-y-1.5">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">Essentials Products</span>
                    <div className="grid grid-cols-2 gap-3">
                      {MOCK_PRODUCTS
                        .filter(p => selectedCategory === "All" || p.category === selectedCategory)
                        .filter(p => !searchQuery || p.name.toLowerCase().includes(searchQuery.toLowerCase()))
                        .filter(p => p.price <= priceRange)
                        .sort((a, b) => {
                          if (sortOption === "Lowest Price") return a.price - b.price;
                          if (sortOption === "Highest Price") return b.price - a.price;
                          if (sortOption === "Highest Rated") return b.rating - a.rating;
                          return b.reviewsCount - a.reviewsCount; // Popularity default
                        })
                        .map(prod => {
                          const isFav = wishlist.includes(prod.id);
                          return (
                            <div key={prod.id} className="bg-white border border-indigo-50/50 p-2.5 rounded-2xl flex flex-col justify-between shadow-sm relative">
                              {/* Favorite Heart trigger */}
                              <button 
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleToggleWishlist(prod.id);
                                }}
                                className="absolute top-1.5 right-1.5 w-6 h-6 rounded-full bg-white shadow flex items-center justify-center text-slate-400 border border-slate-50 hover:scale-105 active:scale-95 transition-transform"
                              >
                                <Heart className={`w-3.5 h-3.5 ${isFav ? "text-red-500 fill-red-500" : "text-slate-400"}`} />
                              </button>
                              
                              <div onClick={() => {
                                setSelectedProduct(prod);
                                setDetailQty(1);
                                setShopView("details");
                              }} className="cursor-pointer">
                                <img src={prod.imageUrl} className="w-full aspect-square rounded-xl object-cover mb-1.5" alt={prod.name} />
                                <span className="text-[7px] text-slate-400 font-bold uppercase">{prod.category}</span>
                                <h5 className="text-[11px] font-black text-indigo-950 truncate">{prod.name}</h5>
                                <div className="flex items-center gap-1 my-0.5">
                                  <Star className="w-2.5 h-2.5 text-amber-400 fill-amber-400" />
                                  <span className="text-[9px] font-bold text-slate-700">{prod.rating}</span>
                                  <span className="text-[8px] text-slate-400 font-medium">({prod.reviewsCount})</span>
                                </div>
                              </div>
                              <div className="flex items-center justify-between mt-1">
                                <span className="text-xs font-black text-indigo-950">${prod.price.toFixed(2)}</span>
                                <button 
                                  onClick={() => handleAddToCart(prod)}
                                  className="w-6 h-6 rounded-full bg-indigo-600 hover:bg-indigo-700 active:scale-90 text-white flex items-center justify-center shadow-md transition-all"
                                >
                                  <Plus className="w-3.5 h-3.5 stroke-[3]" />
                                </button>
                              </div>
                            </div>
                          );
                        })}
                    </div>
                  </div>

                </div>
              )}

              {/* --- 2.2 PRODUCT DETAILS MODAL VIEW --- */}
              {shopView === "details" && selectedProduct && (
                <div className="space-y-4">
                  <button onClick={() => setShopView("catalog")} className="flex items-center gap-1.5 text-xs text-indigo-600 font-bold mb-1">
                    <ArrowLeft className="w-3.5 h-3.5" /> Back to Catalog
                  </button>
                  <img src={selectedProduct.imageUrl} className="w-full aspect-video rounded-2xl object-cover shadow-sm border" alt="Product" />
                  
                  <div className="space-y-1">
                    <div className="flex justify-between items-center">
                      <span className="text-[9px] font-bold text-indigo-600 uppercase bg-indigo-50 px-2 py-0.5 rounded">{selectedProduct.category}</span>
                      <div className="flex items-center gap-1">
                        <Star className="w-3 h-3 text-amber-400 fill-amber-400" />
                        <span className="text-xs font-bold text-slate-800">{selectedProduct.rating} ({selectedProduct.reviewsCount})</span>
                      </div>
                    </div>
                    <h3 className="text-sm font-bold text-slate-900">{selectedProduct.name}</h3>
                    <p className="text-xs font-bold text-indigo-600">${selectedProduct.price.toFixed(2)}</p>
                  </div>

                  <p className="text-[10px] text-slate-500 leading-relaxed">{selectedProduct.description}</p>

                  {/* Tabs */}
                  <div className="border-b border-indigo-50 flex gap-4 text-xs font-bold">
                    <button onClick={() => setDetailSpecTab("features")} className={`pb-1.5 ${detailSpecTab === "features" ? "text-indigo-600 border-b-2 border-indigo-600" : "text-slate-400"}`}>Features</button>
                    <button onClick={() => setDetailSpecTab("specs")} className={`pb-1.5 ${detailSpecTab === "specs" ? "text-indigo-600 border-b-2 border-indigo-600" : "text-slate-400"}`}>Specs</button>
                  </div>
                  {detailSpecTab === "features" ? (
                    <ul className="text-[10px] text-slate-500 space-y-1 list-disc pl-3 font-semibold">
                      {selectedProduct.features.map((f, i) => <li key={i}>{f}</li>)}
                    </ul>
                  ) : (
                    <div className="grid grid-cols-2 gap-2 text-[9px] text-slate-500 font-semibold">
                      {Object.entries(selectedProduct.specifications).map(([k, v]) => (
                        <div key={k} className="p-1 bg-slate-50 rounded">
                          <span className="block text-slate-400 uppercase text-[7px]">{k}</span>
                          <span className="text-indigo-950 font-bold">{v}</span>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Quantity selector & Add trigger */}
                  <div className="flex items-center justify-between pt-2 border-t">
                    <div className="flex items-center border border-slate-200 rounded-full px-2 py-0.5">
                      <button onClick={() => detailQty > 1 && setDetailQty(detailQty - 1)} className="w-5 h-5 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-600"><Minus className="w-2.5 h-2.5" /></button>
                      <span className="text-xs font-bold px-3">{detailQty}</span>
                      <button onClick={() => setDetailQty(detailQty + 1)} className="w-5 h-5 rounded-full bg-indigo-600 text-white flex items-center justify-center font-bold"><Plus className="w-2.5 h-2.5" /></button>
                    </div>
                    <button 
                      onClick={() => {
                        handleAddToCart(selectedProduct, detailQty);
                        setShopView("catalog");
                      }}
                      className="bg-indigo-600 text-white text-xs font-bold px-5 py-2 rounded-xl shadow-md flex items-center gap-1"
                    >
                      <ShoppingCart className="w-3.5 h-3.5" /> Add to Cart (${(selectedProduct.price * detailQty).toFixed(2)})
                    </button>
                  </div>
                </div>
              )}

              {/* --- 2.3 SHOPPING CART VIEW --- */}
              {shopView === "cart" && (
                <div className="space-y-4">
                  <button onClick={() => setShopView("catalog")} className="flex items-center gap-1.5 text-xs text-indigo-600 font-bold">
                    <ArrowLeft className="w-3.5 h-3.5" /> Back to Catalog
                  </button>
                  <h3 className="text-sm font-black text-slate-800">My Shopping Cart</h3>

                  {cart.length === 0 ? (
                    <div className="text-center py-10 space-y-2">
                      <ShoppingCart className="w-10 h-10 text-slate-300 mx-auto" />
                      <p className="text-xs text-slate-400 font-bold">Your cart is empty.</p>
                      <button onClick={() => setShopView("catalog")} className="text-xs text-indigo-600 font-bold underline">Go shopping</button>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {cart.map((item, index) => (
                        <div key={index} className="flex gap-2.5 p-2 bg-white border border-indigo-50/50 rounded-xl items-center shadow-sm">
                          <img src={item.product.imageUrl} className="w-12 h-12 rounded-lg object-cover" alt="" />
                          <div className="flex-1 min-w-0">
                            <h4 className="text-[11px] font-bold text-slate-900 truncate">{item.product.name}</h4>
                            <p className="text-[10px] font-bold text-indigo-600">${item.product.price.toFixed(2)}</p>
                          </div>
                          {/* Quantity selectors in Cart */}
                          <div className="flex items-center gap-1.5">
                            <button 
                              onClick={() => {
                                setCart(prev => prev.map((itm, i) => i === index ? { ...itm, quantity: Math.max(1, itm.quantity - 1) } : itm));
                              }}
                              className="w-5 h-5 bg-slate-100 rounded-full flex items-center justify-center text-slate-600"
                            >
                              <Minus className="w-2.5 h-2.5" />
                            </button>
                            <span className="text-[10px] font-bold">{item.quantity}</span>
                            <button 
                              onClick={() => {
                                setCart(prev => prev.map((itm, i) => i === index ? { ...itm, quantity: itm.quantity + 1 } : itm));
                              }}
                              className="w-5 h-5 bg-indigo-600 text-white rounded-full flex items-center justify-center"
                            >
                              <Plus className="w-2.5 h-2.5" />
                            </button>
                          </div>
                          {/* Delete */}
                          <button 
                            onClick={() => {
                              setCart(prev => prev.filter((_, i) => i !== index));
                            }}
                            className="text-red-500 p-1"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      ))}

                      {/* Promo Code area */}
                      <div className="flex gap-1.5 pt-2">
                        <input 
                          type="text" 
                          placeholder="Promo Code: MAATRIVA20" 
                          value={promoCode}
                          onChange={(e) => setPromoCode(e.target.value)}
                          className="bg-white border text-[10px] px-2.5 py-1.5 rounded-lg flex-1 outline-none text-slate-700 font-bold"
                          disabled={promoApplied}
                        />
                        <button 
                          onClick={() => {
                            if (promoCode.trim().toUpperCase() === "MAATRIVA20") {
                              setPromoApplied(true);
                            }
                          }}
                          className={`text-[9px] font-bold px-3 py-1 rounded-lg ${promoApplied ? "bg-emerald-600 text-white" : "bg-indigo-600 text-white"}`}
                        >
                          {promoApplied ? "Applied" : "Apply"}
                        </button>
                      </div>

                      {/* Price breakdown */}
                      <div className="bg-indigo-50/50 p-3 rounded-xl text-[10px] font-semibold space-y-1 text-slate-600">
                        <div className="flex justify-between"><span>Subtotal</span><span className="font-bold text-slate-800">${cartSubtotal.toFixed(2)}</span></div>
                        <div className="flex justify-between"><span>Delivery Fee</span><span className="font-bold text-slate-800">{deliveryFee === 0 ? "FREE" : `$${deliveryFee.toFixed(2)}`}</span></div>
                        {promoApplied && <div className="flex justify-between text-emerald-600"><span>Promo (20% off)</span><span className="font-bold">-${promoDiscount.toFixed(2)}</span></div>}
                        <div className="border-t pt-1.5 flex justify-between text-xs font-black text-indigo-950"><span>Total</span><span>${cartTotal.toFixed(2)}</span></div>
                      </div>

                      <button 
                        onClick={() => {
                          alert(`Mock Order processed successfully! Total paid: $${cartTotal.toFixed(2)}`);
                          setCart([]);
                          setShopView("catalog");
                        }}
                        className="w-full bg-indigo-600 text-white text-xs font-bold py-2.5 rounded-xl shadow-md text-center block"
                      >
                        Proceed to Checkout
                      </button>
                    </div>
                  )}
                </div>
              )}

              {/* --- 2.4 WISHLIST VIEW --- */}
              {shopView === "wishlist" && (
                <div className="space-y-4">
                  <button onClick={() => setShopView("catalog")} className="flex items-center gap-1.5 text-xs text-indigo-600 font-bold">
                    <ArrowLeft className="w-3.5 h-3.5" /> Back to Catalog
                  </button>
                  <h3 className="text-sm font-black text-slate-800">My Favorites</h3>

                  {wishlist.length === 0 ? (
                    <div className="text-center py-10 space-y-2">
                      <Heart className="w-10 h-10 text-slate-300 mx-auto" />
                      <p className="text-xs text-slate-400 font-bold">Your wishlist is empty.</p>
                      <button onClick={() => setShopView("catalog")} className="text-xs text-indigo-600 font-bold underline">Go shopping</button>
                    </div>
                  ) : (
                    <div className="grid grid-cols-2 gap-3">
                      {MOCK_PRODUCTS
                        .filter(p => wishlist.includes(p.id))
                        .map(prod => (
                          <div key={prod.id} className="bg-white border border-indigo-50/50 p-2.5 rounded-2xl flex flex-col justify-between shadow-sm relative">
                            <button 
                              onClick={() => handleToggleWishlist(prod.id)}
                              className="absolute top-1.5 right-1.5 w-6 h-6 rounded-full bg-white shadow flex items-center justify-center text-red-500 border border-slate-50"
                            >
                              <Heart className="w-3.5 h-3.5 fill-red-500" />
                            </button>
                            <div onClick={() => {
                              setSelectedProduct(prod);
                              setDetailQty(1);
                              setShopView("details");
                            }} className="cursor-pointer">
                              <img src={prod.imageUrl} className="w-full aspect-square rounded-xl object-cover mb-1.5" alt={prod.name} />
                              <span className="text-[7px] text-slate-400 font-bold uppercase">{prod.category}</span>
                              <h5 className="text-[11px] font-black text-indigo-950 truncate">{prod.name}</h5>
                            </div>
                            <div className="flex items-center justify-between mt-1">
                              <span className="text-xs font-black text-indigo-950">${prod.price.toFixed(2)}</span>
                              <button 
                                onClick={() => handleAddToCart(prod)}
                                className="w-6 h-6 rounded-full bg-indigo-600 text-white flex items-center justify-center shadow-md"
                              >
                                <Plus className="w-3.5 h-3.5 stroke-[3]" />
                              </button>
                            </div>
                          </div>
                        ))}
                    </div>
                  )}
                </div>
              )}

            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB 4: AI ASSISTANT CHAT SCREEN */}
          {/* ========================================================================= */}
          {activeTab === 4 && (
            <div className="flex flex-col h-full bg-[#FBF8FD] pb-6">
              {/* Chat Header */}
              <div className="flex items-center gap-3 bg-white p-3 rounded-2xl border border-indigo-50 shadow-sm mb-3">
                <button 
                  onClick={() => setActiveTab(0)}
                  className="p-1 hover:bg-slate-100 rounded-full cursor-pointer"
                >
                  <ArrowLeft className="w-4 h-4 text-indigo-600" />
                </button>
                <div className="w-8 h-8 rounded-full bg-indigo-50 flex items-center justify-center border border-indigo-100">
                  <Bot className="w-4 h-4 text-indigo-600" />
                </div>
                <div className="text-left flex-1 font-sans">
                  <h3 className="text-xs font-black text-indigo-900 leading-tight">AI Assistant</h3>
                  <p className="text-[8px] font-semibold text-emerald-600">Online • Smart Nurse</p>
                </div>
              </div>

              {/* Chat Messages */}
              <div className="flex-1 overflow-y-auto space-y-3 px-1 py-2 max-h-[380px] no-scrollbar">
                {chatMessages.map((msg) => (
                  <div 
                    key={msg.id} 
                    className={`flex ${msg.isUser ? "justify-end" : "justify-start"}`}
                  >
                    <div className={`max-w-[80%] rounded-2xl p-3 text-xs leading-normal shadow-xs ${
                      msg.isUser 
                        ? "bg-indigo-600 text-white rounded-br-none text-right font-semibold" 
                        : "bg-white border border-indigo-55/60 text-slate-700 rounded-bl-none text-left font-medium"
                    }`}>
                      {msg.text}
                    </div>
                  </div>
                ))}
                {chatIsTyping && (
                  <div className="flex justify-start">
                    <div className="bg-white border border-indigo-50 text-slate-400 rounded-2xl rounded-bl-none p-3 text-xs flex items-center gap-1">
                      <span className="w-1.5 h-1.5 bg-slate-400 rounded-full animate-bounce"></span>
                      <span className="w-1.5 h-1.5 bg-slate-400 rounded-full animate-bounce [animation-delay:0.2s]"></span>
                      <span className="w-1.5 h-1.5 bg-slate-400 rounded-full animate-bounce [animation-delay:0.4s]"></span>
                    </div>
                  </div>
                )}
              </div>

              {/* Suggested Questions */}
              <div className="mt-3 px-1 text-left font-sans">
                <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest block mb-1.5">Suggested Questions</span>
                <div className="flex flex-wrap gap-1.5">
                  {[
                    "How was Chloe's sleep?",
                    "Is her heart rate normal?",
                    "Why is she crying?"
                  ].map((q, idx) => (
                    <button
                      key={idx}
                      onClick={() => handleSendChatMessage(q)}
                      className="text-[9.5px] font-bold text-indigo-600 bg-indigo-50 hover:bg-indigo-100/50 px-2.5 py-1 rounded-full border border-indigo-100/40 transition-colors cursor-pointer"
                    >
                      {q}
                    </button>
                  ))}
                </div>
              </div>

              {/* Chat Input */}
              <div className="mt-3 flex gap-2 items-center bg-white border border-indigo-50 rounded-2xl p-1.5 shadow-sm">
                <input
                  type="text"
                  placeholder="Ask about vitals, sleep, growth..."
                  value={chatInput}
                  onChange={(e) => setChatInput(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && handleSendChatMessage(chatInput)}
                  className="flex-1 text-xs px-2.5 py-1.5 bg-transparent focus:outline-none placeholder:text-slate-400 text-slate-700 font-medium"
                />
                <button
                  onClick={() => handleSendChatMessage(chatInput)}
                  className="bg-indigo-600 hover:bg-indigo-700 text-white p-2 rounded-xl transition-colors cursor-pointer flex-shrink-0"
                >
                  <Sparkles className="w-3.5 h-3.5 text-white animate-pulse" />
                </button>
              </div>
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB 5: PROFILE & SETTINGS SYSTEM */}
          {/* ========================================================================= */}
          {activeTab === 5 && (
            <div className="space-y-4">
              
              {/* Conditional back button if not on menu */}
              {profileView !== "menu" && (
                <button 
                  onClick={() => setProfileView("menu")}
                  className="flex items-center gap-1.5 text-[11px] font-bold text-indigo-600 bg-indigo-50 px-2.5 py-1.5 rounded-full hover:bg-indigo-100 transition-colors w-fit mb-1 cursor-pointer"
                >
                  <ArrowLeft className="w-3.5 h-3.5" /> Back to Settings
                </button>
              )}

              {/* 1. MENU VIEW */}
              {profileView === "menu" && (
                <div className="space-y-5">
                  {/* Gradient Card */}
                  <div className="bg-gradient-to-br from-indigo-600 to-indigo-500 rounded-3xl p-5 text-white shadow-md relative overflow-hidden">
                    <div className="flex items-center gap-4">
                      <div className="w-14 h-14 rounded-full border-2 border-white/60 overflow-hidden shadow">
                        <img 
                          src="https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=120" 
                          className="w-full h-full object-cover" 
                          alt="Sarah avatar"
                        />
                      </div>
                      <div>
                        <h3 className="text-sm font-black tracking-tight">{parentName}</h3>
                        <p className="text-[10px] text-white/80">{parentEmail}</p>
                        <span className="inline-block mt-2 text-[8px] bg-white/20 px-2.5 py-1 rounded-full font-black uppercase tracking-wider">Primary Admin</span>
                      </div>
                    </div>
                  </div>

                  {/* Bento Stats row */}
                  <div className="grid grid-cols-3 gap-2.5">
                    <div onClick={() => setProfileView("baby")} className="bg-white border border-indigo-50 p-3 rounded-2xl text-center cursor-pointer hover:bg-indigo-50/20 shadow-sm">
                      <div className="w-7 h-7 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-1.5">
                        <User className="w-4 h-4" />
                      </div>
                      <span className="text-xs font-black text-slate-800">1</span>
                      <p className="text-[9px] text-slate-400 font-bold">Baby</p>
                    </div>
                    <div onClick={() => setProfileView("devices")} className="bg-white border border-indigo-50 p-3 rounded-2xl text-center cursor-pointer hover:bg-indigo-50/20 shadow-sm">
                      <div className="w-7 h-7 bg-emerald-50 text-emerald-500 rounded-full flex items-center justify-center mx-auto mb-1.5">
                        <RefreshCw className="w-4 h-4 animate-spin-slow" />
                      </div>
                      <span className="text-xs font-black text-slate-800">
                        {devices.filter(d => d.isConnected).length}
                      </span>
                      <p className="text-[9px] text-slate-400 font-bold">IoT Online</p>
                    </div>
                    <div onClick={() => setProfileView("caregiver")} className="bg-white border border-indigo-50 p-3 rounded-2xl text-center cursor-pointer hover:bg-indigo-50/20 shadow-sm">
                      <div className="w-7 h-7 bg-indigo-50 text-indigo-500 rounded-full flex items-center justify-center mx-auto mb-1.5">
                        <Share2 className="w-4 h-4" />
                      </div>
                      <span className="text-xs font-black text-slate-800">{sessions.length}</span>
                      <p className="text-[9px] text-slate-400 font-bold">Shared</p>
                    </div>
                  </div>

                  {/* Settings Groups */}
                  <div className="space-y-4">
                    {/* PERSONAL & FAMILY */}
                    <div className="space-y-2">
                      <span className="text-[9px] font-black tracking-wider text-slate-400 uppercase px-1">Personal & Family</span>
                      <div className="bg-white border border-indigo-50/40 rounded-2xl overflow-hidden divide-y divide-indigo-50/50 shadow-sm">
                        <div onClick={() => setProfileView("edit")} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-slate-50 transition-colors">
                          <div className="p-1.5 bg-indigo-50 text-indigo-600 rounded-full"><Sliders className="w-3.5 h-3.5" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-slate-800">Edit Profile</h4><p className="text-[9px] text-slate-400">Name, email, contact photo</p></div>
                        </div>
                        <div onClick={() => setProfileView("parent")} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-slate-50 transition-colors">
                          <div className="p-1.5 bg-indigo-50 text-indigo-600 rounded-full"><User className="w-3.5 h-3.5" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-slate-800">Parent & Partner Details</h4><p className="text-[9px] text-slate-400">Spouse details, emergency contact</p></div>
                        </div>
                        <div onClick={() => setProfileView("baby")} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-slate-50 transition-colors">
                          <div className="p-1.5 bg-indigo-50 text-indigo-600 rounded-full"><User className="w-3.5 h-3.5 text-rose-500" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-slate-800">Baby's Profile Details</h4><p className="text-[9px] text-slate-400">Name, DOB, weight, height</p></div>
                        </div>
                      </div>
                    </div>

                    {/* DEVICES & SHARING */}
                    <div className="space-y-2">
                      <span className="text-[9px] font-black tracking-wider text-slate-400 uppercase px-1">Devices & Sharing</span>
                      <div className="bg-white border border-indigo-50/40 rounded-2xl overflow-hidden divide-y divide-indigo-50/50 shadow-sm">
                        <div onClick={() => setProfileView("devices")} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-slate-50 transition-colors">
                          <div className="p-1.5 bg-indigo-50 text-indigo-600 rounded-full"><Tv className="w-3.5 h-3.5" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-slate-800">Connected Devices</h4><p className="text-[9px] text-slate-400">Manage cameras, smart socks, hubs</p></div>
                        </div>
                        <div onClick={() => setProfileView("caregiver")} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-slate-50 transition-colors">
                          <div className="p-1.5 bg-indigo-50 text-indigo-600 rounded-full"><QrCode className="w-3.5 h-3.5" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-slate-800">Caregiver Access / QR Sharing</h4><p className="text-[9px] text-slate-400">Manage guest caregiver secure tokens</p></div>
                        </div>
                      </div>
                    </div>

                    {/* HEALTH & PREFERENCES */}
                    <div className="space-y-2">
                      <span className="text-[9px] font-black tracking-wider text-slate-400 uppercase px-1">Health & Preferences</span>
                      <div className="bg-white border border-indigo-50/40 rounded-2xl overflow-hidden divide-y divide-indigo-50/50 shadow-sm">
                        <div onClick={() => setProfileView("medical")} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-slate-50 transition-colors">
                          <div className="p-1.5 bg-indigo-50 text-indigo-600 rounded-full"><BriefcaseMedical className="w-3.5 h-3.5 text-emerald-600" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-slate-800">Medical & Vaccine History</h4><p className="text-[9px] text-slate-400">Immunization checkmarks, pediatrician</p></div>
                        </div>
                        <div onClick={() => setProfileView("notifications")} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-slate-50 transition-colors">
                          <div className="p-1.5 bg-indigo-50 text-indigo-600 rounded-full"><Bell className="w-3.5 h-3.5 text-amber-500" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-slate-800">Notification Preferences</h4><p className="text-[9px] text-slate-400">Cry detection, alert thresholds</p></div>
                        </div>
                        <div onClick={() => setProfileView("privacy")} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-slate-50 transition-colors">
                          <div className="p-1.5 bg-indigo-50 text-indigo-600 rounded-full"><ShieldCheck className="w-3.5 h-3.5 text-emerald-500" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-slate-800">Privacy & Security</h4><p className="text-[9px] text-slate-400">Encryption standards, 2FA, face logs</p></div>
                        </div>
                      </div>
                    </div>

                    {/* SUPPORT */}
                    <div className="space-y-2">
                      <span className="text-[9px] font-black tracking-wider text-slate-400 uppercase px-1">Support</span>
                      <div className="bg-white border border-indigo-50/40 rounded-2xl overflow-hidden divide-y divide-indigo-50/50 shadow-sm">
                        <div onClick={() => setProfileView("help")} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-slate-50 transition-colors">
                          <div className="p-1.5 bg-indigo-50 text-indigo-600 rounded-full"><Bot className="w-3.5 h-3.5 text-purple-600" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-slate-800">Help Center & FAQ</h4><p className="text-[9px] text-slate-400">Troubleshooting guides, live support chat</p></div>
                        </div>
                        <div onClick={() => {
                          setShowOnboarding(true);
                          setOnboardingStep(0);
                        }} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-indigo-55/40 transition-colors">
                          <div className="p-1.5 bg-violet-50 text-violet-600 rounded-full"><Sparkles className="w-3.5 h-3.5" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-violet-600">Onboarding & Setup Tour</h4><p className="text-[9px] text-slate-400">Restart the step-by-step pairing setup</p></div>
                        </div>
                        <div onClick={() => {
                          alert("Session Ended. Simulating logout...");
                          setProfileView("menu");
                        }} className="flex items-center gap-3 p-3 cursor-pointer hover:bg-rose-50 transition-colors">
                          <div className="p-1.5 bg-rose-50 text-rose-600 rounded-full"><Trash2 className="w-3.5 h-3.5" /></div>
                          <div className="flex-1 text-left"><h4 className="text-xs font-bold text-rose-600">Sign Out</h4><p className="text-[9px] text-rose-400">Disconnect from the smart nursery</p></div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* 2. EDIT PROFILE VIEW */}
              {profileView === "edit" && (
                <div className="space-y-4 bg-white border border-indigo-50 p-4 rounded-3xl shadow-sm">
                  <h4 className="text-xs font-black text-slate-800">Edit Parent Profile</h4>
                  <div className="space-y-3 text-left">
                    <label className="block text-[10px] font-bold text-slate-500 uppercase">Full Name</label>
                    <input 
                      type="text" 
                      value={parentName} 
                      onChange={(e) => setParentName(e.target.value)} 
                      className="w-full text-xs p-2.5 bg-indigo-50/50 rounded-xl focus:outline-none focus:ring-1 focus:ring-indigo-500"
                    />

                    <label className="block text-[10px] font-bold text-slate-500 uppercase">Email Address</label>
                    <input 
                      type="email" 
                      value={parentEmail} 
                      onChange={(e) => setParentEmail(e.target.value)} 
                      className="w-full text-xs p-2.5 bg-indigo-50/50 rounded-xl focus:outline-none focus:ring-1 focus:ring-indigo-500"
                    />

                    <label className="block text-[10px] font-bold text-slate-500 uppercase">Phone Number</label>
                    <input 
                      type="text" 
                      value={parentPhone} 
                      onChange={(e) => setParentPhone(e.target.value)} 
                      className="w-full text-xs p-2.5 bg-indigo-50/50 rounded-xl focus:outline-none focus:ring-1 focus:ring-indigo-500"
                    />

                    <button 
                      onClick={() => {
                        setProfileView("menu");
                      }}
                      className="w-full bg-indigo-600 text-white text-xs font-bold py-3 rounded-2xl shadow mt-4 cursor-pointer"
                    >
                      Save Profile Changes
                    </button>
                  </div>
                </div>
              )}

              {/* 3. PARTNER & EMERGENCY CONTACT VIEW */}
              {profileView === "parent" && (
                <div className="space-y-4 bg-white border border-indigo-50 p-4 rounded-3xl shadow-sm">
                  <h4 className="text-xs font-black text-slate-800">Parent & Emergency Details</h4>
                  <div className="space-y-3 text-left">
                    <h5 className="text-[10px] font-bold text-indigo-600 uppercase border-b border-indigo-50 pb-1">Spouse / Partner</h5>
                    <div>
                      <label className="block text-[9px] font-bold text-slate-500 uppercase">Partner Name</label>
                      <input 
                        type="text" 
                        value={partnerName} 
                        onChange={(e) => setPartnerName(e.target.value)} 
                        className="w-full text-xs p-2 bg-indigo-50/50 rounded-xl focus:outline-none"
                      />
                    </div>
                    <div>
                      <label className="block text-[9px] font-bold text-slate-500 uppercase">Partner Phone</label>
                      <input 
                        type="text" 
                        value={partnerPhone} 
                        onChange={(e) => setPartnerPhone(e.target.value)} 
                        className="w-full text-xs p-2 bg-indigo-50/50 rounded-xl focus:outline-none"
                      />
                    </div>

                    <h5 className="text-[10px] font-bold text-red-500 uppercase border-b border-indigo-50 pb-1 pt-2">Emergency Backup</h5>
                    <div>
                      <label className="block text-[9px] font-bold text-slate-500 uppercase">Contact Name</label>
                      <input 
                        type="text" 
                        value={emergencyName} 
                        onChange={(e) => setEmergencyName(e.target.value)} 
                        className="w-full text-xs p-2 bg-indigo-50/50 rounded-xl focus:outline-none"
                      />
                    </div>
                    <div>
                      <label className="block text-[9px] font-bold text-slate-500 uppercase">Backup Phone</label>
                      <input 
                        type="text" 
                        value={emergencyPhone} 
                        onChange={(e) => setEmergencyPhone(e.target.value)} 
                        className="w-full text-xs p-2 bg-indigo-50/50 rounded-xl focus:outline-none"
                      />
                    </div>

                    <button 
                      onClick={() => setProfileView("menu")}
                      className="w-full bg-indigo-600 text-white text-xs font-bold py-3 rounded-2xl shadow mt-2 cursor-pointer"
                    >
                      Update Details
                    </button>
                  </div>
                </div>
              )}

              {/* 4. BABY DETAILS VIEW */}
              {profileView === "baby" && (
                <div className="space-y-4 bg-white border border-indigo-50 p-4 rounded-3xl shadow-sm text-left">
                  <div className="flex items-center gap-3 border-b border-indigo-50 pb-3">
                    <div className="w-10 h-10 rounded-full bg-rose-50 overflow-hidden border">
                      <img src="https://images.unsplash.com/photo-1519689680058-324335c77ebe?auto=format&fit=crop&q=80&w=120" className="w-full h-full object-cover" alt="Baby Chloe"/>
                    </div>
                    <div>
                      <h4 className="text-xs font-black text-slate-800">Chloe's Bio Details</h4>
                      <p className="text-[9px] text-slate-400">Infant physical profiles</p>
                    </div>
                  </div>

                  <div className="space-y-3">
                    <div>
                      <label className="block text-[9px] font-bold text-slate-500 uppercase">Baby Name</label>
                      <input 
                        type="text" 
                        value={babyName} 
                        onChange={(e) => setBabyName(e.target.value)} 
                        className="w-full text-xs p-2 bg-indigo-50/50 rounded-xl focus:outline-none"
                      />
                    </div>
                    <div>
                      <label className="block text-[9px] font-bold text-slate-500 uppercase">Date of Birth</label>
                      <input 
                        type="text" 
                        value={babyDob} 
                        onChange={(e) => setBabyDob(e.target.value)} 
                        className="w-full text-xs p-2 bg-indigo-50/50 rounded-xl focus:outline-none"
                      />
                    </div>

                    <div>
                      <label className="block text-[9px] font-bold text-slate-500 uppercase mb-1">Gender</label>
                      <div className="flex gap-2">
                        {["Female", "Male"].map(g => (
                          <button 
                            key={g}
                            onClick={() => setBabyGender(g)}
                            className={`flex-1 py-1.5 rounded-xl text-[10px] font-bold border ${
                              babyGender === g ? "bg-rose-500 border-rose-500 text-white" : "bg-slate-50 border-slate-100 text-slate-600"
                            }`}
                          >
                            {g}
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Weight & Height Steppers */}
                    <div className="grid grid-cols-2 gap-3">
                      <div className="p-2 bg-indigo-50/20 border rounded-xl text-center">
                        <span className="block text-[8px] font-black uppercase text-slate-400">Weight</span>
                        <span className="text-xs font-black text-slate-800">{babyWeight} kg</span>
                        <div className="flex justify-center gap-3 mt-1.5">
                          <button onClick={() => setBabyWeight(p => Math.max(1, p - 0.1))} className="w-5 h-5 rounded-full bg-white border flex items-center justify-center text-xs font-bold shadow-sm">-</button>
                          <button onClick={() => setBabyWeight(p => p + 0.1)} className="w-5 h-5 rounded-full bg-white border flex items-center justify-center text-xs font-bold shadow-sm">+</button>
                        </div>
                      </div>
                      <div className="p-2 bg-indigo-50/20 border rounded-xl text-center">
                        <span className="block text-[8px] font-black uppercase text-slate-400">Height</span>
                        <span className="text-xs font-black text-slate-800">{babyHeight} cm</span>
                        <div className="flex justify-center gap-3 mt-1.5">
                          <button onClick={() => setBabyHeight(p => Math.max(10, p - 0.5))} className="w-5 h-5 rounded-full bg-white border flex items-center justify-center text-xs font-bold shadow-sm">-</button>
                          <button onClick={() => setBabyHeight(p => p + 0.5)} className="w-5 h-5 rounded-full bg-white border flex items-center justify-center text-xs font-bold shadow-sm">+</button>
                        </div>
                      </div>
                    </div>

                    <button 
                      onClick={() => setProfileView("menu")}
                      className="w-full bg-indigo-600 text-white text-xs font-bold py-3 rounded-2xl shadow mt-2 cursor-pointer"
                    >
                      Save Baby Profile
                    </button>
                  </div>
                </div>
              )}

              {/* 5. CONNECTED DEVICES VIEW */}
              {profileView === "devices" && (
                <div className="space-y-4">
                  <div className="text-left">
                    <h4 className="text-xs font-black text-slate-800">Connected Hardware ({devices.length})</h4>
                    <p className="text-[9px] text-slate-400">Continuous Bluetooth/Wifi IoT scanner</p>
                  </div>

                  <div className="space-y-3">
                    {devices.map(dev => (
                      <div key={dev.id} className="bg-white p-3 border border-indigo-50/40 rounded-2xl flex justify-between items-center shadow-sm">
                        <div className="flex items-center gap-3 text-left">
                          <div className={`p-2 rounded-xl ${dev.isConnected ? "bg-indigo-50 text-indigo-600" : "bg-slate-100 text-slate-400"}`}>
                            <Tv className="w-4 h-4" />
                          </div>
                          <div>
                            <h5 className="text-xs font-bold text-slate-800">{dev.name}</h5>
                            <p className="text-[9px] text-slate-400">
                              <span className={`inline-block w-1.5 h-1.5 rounded-full mr-1.5 ${dev.isConnected ? "bg-emerald-500 animate-pulse" : "bg-slate-300"}`}></span>
                              {dev.isConnected ? "Connected & Syncing" : "Offline / Standby"}
                              {dev.battery !== -1 && ` • Battery: ${dev.battery}%`}
                            </p>
                          </div>
                        </div>
                        <input 
                          type="checkbox" 
                          checked={dev.isConnected}
                          onChange={() => {
                            setDevices(prev => prev.map(d => d.id === dev.id ? { ...d, isConnected: !d.isConnected } : d));
                          }}
                          className="accent-indigo-600 h-4 w-4 cursor-pointer"
                        />
                      </div>
                    ))}
                  </div>

                  {/* Add New Device Pairing flow */}
                  {!isPairing ? (
                    <button 
                      onClick={() => {
                        setIsPairing(true);
                        setPairedProgress(0);
                        const interval = setInterval(() => {
                          setPairedProgress(p => {
                            if (p >= 1) {
                              clearInterval(interval);
                              setIsPairing(false);
                              alert("Pairing complete: Maatriva Sound Soother paired!");
                              return 1;
                            }
                            return p + 0.1;
                          });
                        }, 250);
                      }}
                      className="w-full bg-indigo-50 border border-dashed border-indigo-200 text-indigo-600 text-xs font-black py-4 rounded-2xl flex flex-col items-center justify-center gap-1 hover:bg-indigo-100/40 transition-colors mt-2 cursor-pointer"
                    >
                      <PlusCircle className="w-5 h-5" />
                      Pair New Smart Hardware
                    </button>
                  ) : (
                    <div className="bg-white p-4 border border-indigo-100 rounded-2xl text-center space-y-2">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-bold text-indigo-600">Pinging 2.4GHz channels...</span>
                        <span>{Math.round(pairedProgress * 100)}%</span>
                      </div>
                      <div className="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
                        <div className="bg-indigo-600 h-full transition-all duration-200" style={{ width: `${pairedProgress * 100}%` }}></div>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* 6. ORIGINAL CAREGIVER QR ACCESS */}
              {profileView === "caregiver" && (
                <div className="space-y-4">
                  {/* QR Code Container */}
                  <div className="bg-white border border-indigo-50 p-5 rounded-3xl shadow-sm text-center space-y-4 relative overflow-hidden">
                    <div className="absolute top-0 right-0 p-3 text-indigo-500/5">
                      <QrCode className="w-16 h-16" />
                    </div>
                    <div className="mx-auto w-28 h-28 bg-indigo-50 rounded-2xl border-2 border-indigo-100 flex items-center justify-center p-2 relative">
                      <QrCode className="w-full h-full text-indigo-600 stroke-[1.5]" />
                      <div className="absolute inset-0 bg-black/5 flex items-center justify-center rounded-xl">
                        <span className="bg-emerald-500 text-white text-[7px] px-2 py-0.5 rounded-full font-bold uppercase tracking-widest">Active</span>
                      </div>
                    </div>
                    <div>
                      <h4 className="text-xs font-black text-slate-800">{babyName}'s Crib QR Token</h4>
                      <p className="text-[9px] text-slate-400 mt-1 leading-tight">Scan this code with secondary Maatriva device to sync credentials</p>
                    </div>
                  </div>

                  {/* Duration Selectors */}
                  <div className="bg-white border border-indigo-50 p-4 rounded-3xl shadow-sm space-y-2.5">
                    <h4 className="text-xs font-bold text-slate-800 flex items-center gap-1.5"><Clock className="w-3.5 h-3.5 text-indigo-500" /> Share Invitation Duration</h4>
                    <div className="grid grid-cols-4 gap-1">
                      {["1 Hour", "4 Hours", "24 Hours", "Permanent"].map(dur => {
                        const isS = selectedDuration === dur;
                        return (
                          <button 
                            key={dur} 
                            onClick={() => setSelectedDuration(dur)}
                            className={`text-[8px] font-black py-1.5 rounded-xl border transition-all ${
                              isS ? "bg-indigo-600 border-indigo-600 text-white" : "bg-white border-slate-150 text-slate-600"
                            }`}
                          >
                            {dur}
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  {/* Permission parameters */}
                  <div className="bg-white border border-indigo-50 p-4 rounded-3xl shadow-sm space-y-2.5">
                    <h4 className="text-xs font-bold text-slate-800 flex items-center gap-1.5"><Unlock className="w-3.5 h-3.5 text-indigo-500" /> Access Permissions</h4>
                    <div className="space-y-2">
                      {Object.entries(permissions).map(([k, v]) => (
                        <div key={k} className="flex justify-between items-center text-xs">
                          <span className="font-semibold text-slate-700 uppercase text-[8px]">{k.replace(/([A-Z])/g, ' $1')}</span>
                          <input 
                            type="checkbox" 
                            checked={v} 
                            onChange={() => setPermissions(prev => ({ ...prev, [k]: !v }))}
                            className="accent-indigo-600 h-3.5 w-3.5 cursor-pointer"
                          />
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Active Sessions list */}
                  <div className="space-y-2">
                    <span className="text-[9px] font-bold text-slate-400 uppercase tracking-widest px-1">Active Sessions ({sessions.length})</span>
                    {sessions.map(ses => (
                      <div key={ses.id} className="flex justify-between items-center bg-white p-2.5 border border-indigo-50/50 rounded-2xl shadow-sm">
                        <div className="text-left">
                          <h4 className="text-xs font-bold text-slate-800">{ses.name}</h4>
                          <p className="text-[8px] text-slate-400 font-semibold">{ses.type} • {ses.duration}</p>
                        </div>
                        <button 
                          onClick={() => setSessions(prev => prev.filter(s => s.id !== ses.id))}
                          className="text-red-500 text-[9px] font-bold bg-red-50 hover:bg-red-100 px-2.5 py-1 rounded-xl cursor-pointer"
                        >
                          Revoke
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* 7. MEDICAL & VACCINES CHECKLIST */}
              {profileView === "medical" && (
                <div className="space-y-4 text-left">
                  {/* Pediatrician quick-connect */}
                  <div className="bg-white p-3 border rounded-2xl flex justify-between items-center shadow-sm">
                    <div>
                      <span className="text-[8px] font-black uppercase text-indigo-500">Pediatrician</span>
                      <h4 className="text-xs font-bold text-slate-800">{pediatricianName}</h4>
                      <p className="text-[9px] text-slate-400">{pediatricianPhone}</p>
                    </div>
                    <button 
                      onClick={() => alert(`Calling ${pediatricianName}...`)}
                      className="p-2 bg-emerald-50 text-emerald-600 rounded-full hover:bg-emerald-100 cursor-pointer"
                    >
                      <Home className="w-4 h-4" />
                    </button>
                  </div>

                  {/* Allergies tag */}
                  <div className="bg-amber-50/40 border border-amber-100 p-3 rounded-2xl">
                    <h5 className="text-[10px] font-black text-amber-800 uppercase flex items-center gap-1.5">
                      <AlertTriangle className="w-3.5 h-3.5" /> Allergies Notes
                    </h5>
                    <p className="text-[10px] text-amber-950 mt-1">{allergies}</p>
                  </div>

                  {/* Immunization timeline */}
                  <div className="space-y-2">
                    <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest">Immunization Timeline</span>
                    <div className="space-y-2.5">
                      {vaccines.map(vacc => {
                        const isDone = vacc.status === "Administered";
                        return (
                          <div 
                            key={vacc.id}
                            onClick={() => {
                              setVaccines(prev => prev.map(v => v.id === vacc.id ? {
                                ...v,
                                status: isDone ? "Pending" : "Administered",
                                dateAdministered: isDone ? "--" : "12/28/2025"
                              } : v));
                            }}
                            className={`p-3 bg-white border rounded-2xl flex gap-3 cursor-pointer hover:bg-slate-50 transition-colors ${
                              isDone ? "border-indigo-100" : "border-slate-100"
                            }`}
                          >
                            <div className={`w-4 h-4 rounded-full border flex items-center justify-center ${
                              isDone ? "bg-indigo-600 border-indigo-600 text-white" : "border-slate-300"
                            }`}>
                              {isDone && <Check className="w-3 h-3 stroke-[3]" />}
                            </div>
                            <div className="flex-1">
                              <h5 className={`text-[11.5px] font-bold ${isDone ? "text-slate-400 line-through" : "text-slate-800"}`}>{vacc.name}</h5>
                              <p className="text-[9px] text-slate-400">Due: {vacc.ageDue} {isDone && `• Completed: ${vacc.dateAdministered}`}</p>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </div>
              )}

              {/* 8. NOTIFICATION PREFERENCES VIEW */}
              {profileView === "notifications" && (
                <div className="space-y-4 text-left">
                  <div>
                    <h4 className="text-xs font-black text-slate-800">Telemetry Alarms</h4>
                    <p className="text-[9px] text-slate-400">Instant push sound/fever alert thresholds</p>
                  </div>

                  <div className="bg-white border rounded-2xl p-4 space-y-4 shadow-sm">
                    {Object.entries(notifPrefs).map(([k, v]) => (
                      <div key={k} className="flex justify-between items-start gap-4">
                        <div className="flex-1">
                          <h5 className="text-xs font-bold text-slate-800 capitalize">{k.replace(/([A-Z])/g, ' $1')}</h5>
                          <p className="text-[9px] text-slate-400 leading-tight">
                            {k === "cryAlerts" && "Notify if nursery crying levels exceed 65dB sound frequencies."}
                            {k === "abnormalHeartRate" && "Critical sock push warning for irregular/high BPM loops."}
                            {k === "tempAlerts" && "Receive warnings if nursery parameters escape optimal temp ranges."}
                            {k === "feedingReminders" && "Help schedule milk feeds periodically every 3 hours."}
                            {k === "sleepAnalysis" && "Weekly AI summary digests detailing sleep rhythm developments."}
                          </p>
                        </div>
                        <input 
                          type="checkbox" 
                          checked={v} 
                          onChange={() => setNotifPrefs(p => ({ ...p, [k]: !v }))}
                          className="accent-indigo-600 h-4 w-4 mt-1 cursor-pointer"
                        />
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* 9. PRIVACY VIEW */}
              {profileView === "privacy" && (
                <div className="space-y-4 text-left">
                  <div className="text-center py-2 bg-indigo-50/20 border border-indigo-50/50 rounded-2xl">
                    <ShieldCheck className="w-8 h-8 text-indigo-600 mx-auto mb-1.5" />
                    <h5 className="text-[11px] font-black text-indigo-900">End-to-End Cryptography</h5>
                    <p className="text-[9px] text-slate-400 leading-none">AES-256 standard camera feeds active</p>
                  </div>

                  <div className="bg-white border rounded-2xl p-4 space-y-4 shadow-sm">
                    <div className="flex justify-between items-start gap-4">
                      <div className="flex-1">
                        <h5 className="text-xs font-bold text-slate-800">Two-Factor Authentication</h5>
                        <p className="text-[9px] text-slate-400 leading-tight">Send verification text messages on second login sessions.</p>
                      </div>
                      <input 
                        type="checkbox" 
                        checked={privacyPrefs.twoFactor} 
                        onChange={() => setPrivacyPrefs(p => ({ ...p, twoFactor: !p.twoFactor }))}
                        className="accent-indigo-600 h-4 w-4 cursor-pointer"
                      />
                    </div>

                    <div className="flex justify-between items-start gap-4">
                      <div className="flex-1">
                        <h5 className="text-xs font-bold text-slate-800">Biometric Recognition</h5>
                        <p className="text-[9px] text-slate-400 leading-tight">Allow biometric FaceID / TouchID to open crib live feeds.</p>
                      </div>
                      <input 
                        type="checkbox" 
                        checked={privacyPrefs.biometrics} 
                        onChange={() => setPrivacyPrefs(p => ({ ...p, biometrics: !p.biometrics }))}
                        className="accent-indigo-600 h-4 w-4 cursor-pointer"
                      />
                    </div>

                    <div className="flex justify-between items-start gap-4">
                      <div className="flex-1">
                        <h5 className="text-xs font-bold text-slate-800">Pediatrician Syncing</h5>
                        <p className="text-[9px] text-slate-400 leading-tight">Authorize Dr Carter to download daily fever and sleep reports.</p>
                      </div>
                      <input 
                        type="checkbox" 
                        checked={privacyPrefs.sharePediatrician} 
                        onChange={() => setPrivacyPrefs(p => ({ ...p, sharePediatrician: !p.sharePediatrician }))}
                        className="accent-indigo-600 h-4 w-4 cursor-pointer"
                      />
                    </div>
                  </div>

                  {/* Account controls */}
                  <div className="bg-white border rounded-2xl p-3.5 space-y-2.5 shadow-sm text-center">
                    <button 
                      onClick={() => alert("Archive download link sent to: sarah.johnson@maatriva.com")}
                      className="w-full py-2 border text-slate-600 text-[10.5px] font-black rounded-xl hover:bg-slate-50 cursor-pointer"
                    >
                      Request Personal Data Archive (CSV)
                    </button>
                    <button 
                      onClick={() => {
                        if (confirm("Request deletion? This removes all telemetry files permanently.")) {
                          alert("Permanent Deletion Scheduled in 3 days.");
                        }
                      }}
                      className="w-full py-2 bg-rose-50 text-rose-600 text-[10.5px] font-black rounded-xl hover:bg-rose-100 cursor-pointer"
                    >
                      Delete Account Permanently
                    </button>
                  </div>
                </div>
              )}

              {/* 10. HELP CENTER VIEW */}
              {profileView === "help" && (
                <div className="space-y-4 text-left">
                  <div className="bg-gradient-to-br from-indigo-600 to-indigo-500 text-white p-4 rounded-3xl space-y-3 shadow-md">
                    <h5 className="text-xs font-black">Troubleshooting search</h5>
                    <input 
                      type="text"
                      placeholder="Search pairing, wifi, sensors..."
                      value={helpSearch}
                      onChange={(e) => setHelpSearch(e.target.value)}
                      className="w-full text-slate-800 text-xs p-2 rounded-xl bg-white focus:outline-none placeholder:text-slate-400"
                    />
                  </div>

                  {/* Contact options */}
                  <div className="grid grid-cols-2 gap-3">
                    <div onClick={() => alert("Launching customer chat agent session...")} className="bg-white p-3 border rounded-2xl text-center shadow-sm cursor-pointer hover:bg-slate-50">
                      <span className="block text-xs font-bold text-indigo-600">Live support chat</span>
                      <p className="text-[9px] text-slate-400">2 min avg response</p>
                    </div>
                    <div onClick={() => alert("Creating secure email ticket...")} className="bg-white p-3 border rounded-2xl text-center shadow-sm cursor-pointer hover:bg-slate-50">
                      <span className="block text-xs font-bold text-slate-600">Email tickets</span>
                      <p className="text-[9px] text-slate-400">Response in 2 hrs</p>
                    </div>
                  </div>

                  {/* FAQ list */}
                  <div className="space-y-2">
                    <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest">General FAQ</span>
                    <div className="space-y-2.5">
                      {[
                        { q: "How do I pair the Smart Sock V2?", a: "Turn on Bluetooth. In Settings > Connected Devices tap 'Pair New Hardware'. Turn on sock button until flashing, keep nearby." },
                        { q: "What does pulsing blue light mean?", a: "The camera is trying to search for the Wi-Fi. Ensure 2.4GHz channels are active with strong router signals." },
                        { q: "Can I add multiple caregivers?", a: "Yes! Navigate to QR Sharing, input details, generate temporary tokens, and send securely." }
                      ]
                        .filter(item => item.q.toLowerCase().includes(helpSearch.toLowerCase()) || item.a.toLowerCase().includes(helpSearch.toLowerCase()))
                        .map((item, idx) => (
                          <div key={idx} className="bg-white p-3 border rounded-2xl shadow-xs">
                            <h5 className="text-[11.5px] font-bold text-slate-800 leading-snug">{item.q}</h5>
                            <p className="text-[10px] text-slate-500 mt-1 leading-tight">{item.a}</p>
                          </div>
                        ))}
                    </div>
                  </div>
                </div>
              )}

            </div>
          )}

        </div>

        {/* Soft Glow Floating Action Button (AI Assistant) */}
        {!showOnboarding && activeTab !== 4 && (
          <button
            onClick={() => {
              setActiveTab(4);
            }}
            className="absolute bottom-20 right-4 w-12 h-12 bg-indigo-600 hover:bg-indigo-700 text-white rounded-full flex items-center justify-center shadow-lg hover:scale-105 active:scale-95 transition-all z-35 cursor-pointer border border-indigo-500/20 shadow-indigo-200/50"
          >
            <Bot className="w-5.5 h-5.5 text-white" />
          </button>
        )}

        {/* --- STICKY BOTTOM NAVIGATION BAR --- */}
        <div className="absolute bottom-0 left-0 right-0 h-16 bg-white border-t border-indigo-50 flex justify-around items-center px-2 z-30">
          
          <button 
            onClick={() => setActiveTab(0)}
            className="flex items-center justify-center focus:outline-none transition-all cursor-pointer"
          >
            {activeTab === 0 ? (
              <div className="bg-indigo-600 text-white flex items-center gap-1.5 px-3 py-1.5 rounded-full">
                <Home className="w-3.5 h-3.5 text-white" />
                <span className="text-[9px] font-black uppercase tracking-wider">Home</span>
              </div>
            ) : (
              <div className="text-gray-400 hover:text-gray-600 flex flex-col items-center gap-0.5">
                <Home className="w-4.5 h-4.5" />
                <span className="text-[8px] font-bold uppercase">Home</span>
              </div>
            )}
          </button>

          <button 
            onClick={() => setActiveTab(1)}
            className="flex items-center justify-center focus:outline-none transition-all cursor-pointer"
          >
            {activeTab === 1 ? (
              <div className="bg-indigo-600 text-white flex items-center gap-1.5 px-3 py-1.5 rounded-full">
                <Video className="w-3.5 h-3.5 text-white" />
                <span className="text-[9px] font-black uppercase tracking-wider">Live</span>
              </div>
            ) : (
              <div className="text-gray-400 hover:text-gray-600 flex flex-col items-center gap-0.5">
                <Video className="w-4.5 h-4.5" />
                <span className="text-[8px] font-bold uppercase">Live</span>
              </div>
            )}
          </button>

          <button 
            onClick={() => setActiveTab(2)}
            className="flex items-center justify-center focus:outline-none transition-all cursor-pointer"
          >
            {activeTab === 2 ? (
              <div className="bg-indigo-600 text-white flex items-center gap-1.5 px-3 py-1.5 rounded-full">
                <Heart className="w-3.5 h-3.5 text-white fill-white" />
                <span className="text-[9px] font-black uppercase tracking-wider">Health</span>
              </div>
            ) : (
              <div className="text-gray-400 hover:text-gray-600 flex flex-col items-center gap-0.5">
                <Heart className="w-4.5 h-4.5" />
                <span className="text-[8px] font-bold uppercase">Health</span>
              </div>
            )}
          </button>

          <button 
            onClick={() => {
              setActiveTab(3);
              setShopView("catalog");
            }}
            className="flex items-center justify-center focus:outline-none transition-all cursor-pointer"
          >
            {activeTab === 3 ? (
              <div className="bg-indigo-600 text-white flex items-center gap-1.5 px-3 py-1.5 rounded-full">
                <ShoppingBag className="w-3.5 h-3.5 text-white" />
                <span className="text-[9px] font-black uppercase tracking-wider">Shop</span>
              </div>
            ) : (
              <div className="text-gray-400 hover:text-gray-600 flex flex-col items-center gap-0.5">
                <ShoppingBag className="w-4.5 h-4.5" />
                <span className="text-[8px] font-bold uppercase">Shop</span>
              </div>
            )}
          </button>
        </div>

        {/* ========================================================================= */}
        {/* ONBOARDING & SETUP EXPERIENCES OVERLAY (z-40 COVER) */}
        {/* ========================================================================= */}
        {showOnboarding && (
          <div className="absolute inset-0 bg-[#FBF8FD] z-40 pt-10 pb-4 flex flex-col font-sans animate-fade-in overflow-hidden">
            {/* Timeline Progress Tracker */}
            {onboardingStep > 0 && (
              <div className="px-5 py-2.5 bg-white border-b border-indigo-50 flex items-center justify-between">
                <span className="text-[10px] font-black text-indigo-950 uppercase tracking-widest text-left">
                  Step {onboardingStep} of 6
                </span>
                <div className="flex gap-1.5">
                  {[1, 2, 3, 4, 5, 6].map((s) => (
                    <div
                      key={s}
                      className={`h-1.5 rounded-full transition-all duration-300 ${
                        s === onboardingStep
                          ? "w-6 bg-indigo-600"
                          : s < onboardingStep
                          ? "w-2 bg-indigo-300"
                          : "w-2 bg-indigo-100"
                      }`}
                    ></div>
                  ))}
                </div>
              </div>
            )}

            {/* Content Body */}
            <div className="flex-1 overflow-y-auto px-5 py-4 flex flex-col justify-between">
              
              {/* SCREEN 1: WELCOME */}
              {onboardingStep === 0 && (
                <div className="flex-1 flex flex-col justify-center items-center text-center space-y-6 py-6">
                  {/* Lavender Claymorphic Circle Icon */}
                  <div className="w-24 h-24 rounded-full bg-gradient-to-br from-indigo-100 to-indigo-50 flex items-center justify-center shadow-lg shadow-indigo-100/40 border border-white">
                    <Sparkles className="w-10 h-10 text-indigo-600 animate-pulse" />
                  </div>
                  <div className="space-y-2">
                    <h2 className="text-xl font-extrabold text-indigo-950 tracking-tight leading-tight">
                      Nurturing Your Little One, Smartly.
                    </h2>
                    <p className="text-[11.5px] text-slate-500 leading-relaxed max-w-[260px] mx-auto">
                      Welcome to Maatriva, where AI meets deep pediatric intelligence to keep your baby safe and sound.
                    </p>
                  </div>
                  <button
                    onClick={() => setOnboardingStep(1)}
                    className="w-full max-w-[240px] bg-indigo-600 text-white text-xs font-extrabold py-3.5 rounded-2xl shadow-md shadow-indigo-200 hover:bg-indigo-700 transition-all transform hover:-translate-y-0.5 cursor-pointer mx-auto"
                  >
                    Get Started
                  </button>
                </div>
              )}

              {/* SCREEN 2: APP INTRODUCTION */}
              {onboardingStep === 1 && (
                <div className="flex-1 flex flex-col justify-between h-full space-y-4">
                  <div className="space-y-4 text-center">
                    <div className="space-y-1">
                      <h3 className="text-base font-extrabold text-indigo-950">Intelligent Monitoring</h3>
                      <p className="text-[11px] text-slate-400">Our smart suite guides you through everything</p>
                    </div>

                    <div className="space-y-3 pt-2">
                      <div className="bg-white p-3.5 border border-indigo-50/50 rounded-2xl flex items-center gap-3 text-left shadow-sm">
                        <div className="p-2.5 bg-[#FAF7FF] text-indigo-600 rounded-xl">
                          <Bot className="w-4 h-4" />
                        </div>
                        <div>
                          <h4 className="text-xs font-black text-slate-800">Smart Cry Translation</h4>
                          <p className="text-[9.5px] text-slate-400 leading-normal">Translates cry frequencies into physiological needs in real-time.</p>
                        </div>
                      </div>

                      <div className="bg-white p-3.5 border border-indigo-50/50 rounded-2xl flex items-center gap-3 text-left shadow-sm">
                        <div className="p-2.5 bg-[#FAF7FF] text-rose-500 rounded-xl">
                          <Heart className="w-4 h-4" />
                        </div>
                        <div>
                          <h4 className="text-xs font-black text-slate-800">Real-time Biometrics</h4>
                          <p className="text-[9.5px] text-slate-400 leading-normal">Maintains active checks of oxygen levels and core temperature.</p>
                        </div>
                      </div>

                      <div className="bg-white p-3.5 border border-indigo-50/50 rounded-2xl flex items-center gap-3 text-left shadow-sm">
                        <div className="p-2.5 bg-[#FAF7FF] text-emerald-500 rounded-xl">
                          <BarChart3 className="w-4 h-4" />
                        </div>
                        <div>
                          <h4 className="text-xs font-black text-slate-800">Pediatrician Summaries</h4>
                          <p className="text-[9.5px] text-slate-400 leading-normal">Recap sleep cycles, vital trends, and historical insights.</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="flex gap-3 pt-4">
                    <button
                      onClick={() => setOnboardingStep(0)}
                      className="flex-1 bg-slate-50 border border-slate-100 text-slate-500 text-xs font-extrabold py-3 rounded-2xl hover:bg-slate-100 cursor-pointer"
                    >
                      Back
                    </button>
                    <button
                      onClick={() => setOnboardingStep(2)}
                      className="flex-1 bg-indigo-600 text-white text-xs font-extrabold py-3 rounded-2xl shadow-md hover:bg-indigo-700 cursor-pointer"
                    >
                      Next Step
                    </button>
                  </div>
                </div>
              )}

              {/* SCREEN 3: PERMISSIONS */}
              {onboardingStep === 2 && (
                <div className="flex-1 flex flex-col justify-between h-full space-y-4">
                  <div className="space-y-3">
                    <div className="text-center space-y-1">
                      <h3 className="text-base font-extrabold text-indigo-950">Ecosystem Access</h3>
                      <p className="text-[11px] text-slate-400 leading-snug">Secure permissions needed for continuous cradle and vital synching</p>
                    </div>

                    {/* Checkboxes List */}
                    <div className="space-y-2 bg-white p-4 border border-indigo-50/50 rounded-3xl shadow-xs">
                      {Object.keys(allowedPermissions).map((p) => {
                        const isAllowed = allowedPermissions[p];
                        return (
                          <div key={p} className="flex justify-between items-center py-1 border-b border-slate-50 last:border-0">
                            <div className="text-left">
                              <span className="text-xs font-bold text-slate-700">{p}</span>
                              <p className="text-[8.5px] text-slate-400 leading-none">Required for IoT communication</p>
                            </div>
                            <input
                              type="checkbox"
                              checked={isAllowed}
                              onChange={() =>
                                setAllowedPermissions((prev) => ({
                                  ...prev,
                                  [p]: !isAllowed,
                                }))
                              }
                              className="accent-indigo-600 w-4 h-4 rounded cursor-pointer"
                            />
                          </div>
                        );
                      })}
                    </div>

                    <button
                      onClick={() =>
                        setAllowedPermissions({
                          Camera: true,
                          Microphone: true,
                          Notifications: true,
                          Bluetooth: true,
                          "Wi-Fi": true,
                          Location: true,
                        })
                      }
                      className="w-full bg-indigo-50 text-indigo-600 text-[10px] font-black py-2 rounded-xl border border-dashed border-indigo-200 hover:bg-indigo-100/50 transition-colors"
                    >
                      Allow All Permissions
                    </button>
                  </div>

                  <div className="flex gap-3 pt-2">
                    <button
                      onClick={() => setOnboardingStep(1)}
                      className="flex-1 bg-slate-50 border border-slate-100 text-slate-500 text-xs font-extrabold py-3 rounded-2xl hover:bg-slate-100 cursor-pointer"
                    >
                      Back
                    </button>
                    <button
                      onClick={() => setOnboardingStep(3)}
                      className="flex-1 bg-indigo-600 text-white text-xs font-extrabold py-3 rounded-2xl shadow-md hover:bg-indigo-700 cursor-pointer"
                    >
                      Next Step
                    </button>
                  </div>
                </div>
              )}

              {/* SCREEN 4: PARENT INFORMATION */}
              {onboardingStep === 3 && (
                <div className="flex-1 flex flex-col justify-between h-full space-y-4">
                  <div className="space-y-4 text-left">
                    <div className="text-center space-y-1">
                      <h3 className="text-base font-extrabold text-indigo-950">Parent Information</h3>
                      <p className="text-[11px] text-slate-400">Let's set up your profile credentials</p>
                    </div>

                    <div className="space-y-3.5 bg-white p-4 border border-indigo-50/50 rounded-3xl shadow-sm">
                      <div className="space-y-1">
                        <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Full Name</label>
                        <input
                          type="text"
                          value={parentName}
                          onChange={(e) => setParentName(e.target.value)}
                          placeholder="e.g., Sarah Johnson"
                          className="w-full text-xs font-semibold px-3 py-2.5 bg-[#FAF7FF] border border-indigo-50 rounded-xl focus:outline-none focus:border-indigo-400"
                        />
                      </div>

                      <div className="space-y-1">
                        <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Phone Number</label>
                        <input
                          type="text"
                          value={parentPhone}
                          onChange={(e) => setParentPhone(e.target.value)}
                          placeholder="e.g., +1 (555) 342-9841"
                          className="w-full text-xs font-semibold px-3 py-2.5 bg-[#FAF7FF] border border-indigo-50 rounded-xl focus:outline-none focus:border-indigo-400"
                        />
                      </div>

                      <div className="space-y-1">
                        <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Email Address</label>
                        <input
                          type="email"
                          value={parentEmail}
                          onChange={(e) => setParentEmail(e.target.value)}
                          placeholder="e.g., sarah@gmail.com"
                          className="w-full text-xs font-semibold px-3 py-2.5 bg-[#FAF7FF] border border-indigo-50 rounded-xl focus:outline-none focus:border-indigo-400"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="flex gap-3 pt-2">
                    <button
                      onClick={() => setOnboardingStep(2)}
                      className="flex-1 bg-slate-50 border border-slate-100 text-slate-500 text-xs font-extrabold py-3 rounded-2xl hover:bg-slate-100 cursor-pointer"
                    >
                      Back
                    </button>
                    <button
                      onClick={() => {
                        if (!parentName.trim()) {
                          alert("Please enter your name to proceed.");
                          return;
                        }
                        setOnboardingStep(4);
                      }}
                      className="flex-1 bg-indigo-600 text-white text-xs font-extrabold py-3 rounded-2xl shadow-md hover:bg-indigo-700 cursor-pointer"
                    >
                      Next Step
                    </button>
                  </div>
                </div>
              )}

              {/* SCREEN 5: BABY INFORMATION */}
              {onboardingStep === 4 && (
                <div className="flex-1 flex flex-col justify-between h-full space-y-4">
                  <div className="space-y-3.5 text-left">
                    <div className="text-center space-y-1">
                      <h3 className="text-base font-extrabold text-indigo-950">Baby Information</h3>
                      <p className="text-[11px] text-slate-400">Configure vital calibration limits</p>
                    </div>

                    <div className="space-y-3 bg-white p-4 border border-indigo-50/50 rounded-3xl shadow-sm">
                      <div className="space-y-1">
                        <label className="text-[10px] font-bold text-slate-500 uppercase block">Baby's Name</label>
                        <input
                          type="text"
                          value={babyName}
                          onChange={(e) => setBabyName(e.target.value)}
                          placeholder="e.g., Chloe"
                          className="w-full text-xs font-semibold px-3 py-2.5 bg-[#FAF7FF] border border-indigo-50 rounded-xl focus:outline-none focus:border-indigo-400"
                        />
                      </div>

                      <div className="grid grid-cols-2 gap-3">
                        <div className="space-y-1">
                          <label className="text-[10px] font-bold text-slate-500 uppercase block">Gender</label>
                          <select
                            value={babyGender}
                            onChange={(e) => setBabyGender(e.target.value)}
                            className="w-full text-xs font-semibold px-2 py-2.5 bg-[#FAF7FF] border border-indigo-50 rounded-xl focus:outline-none focus:border-indigo-400"
                          >
                            <option value="Female">Female</option>
                            <option value="Male">Male</option>
                            <option value="Other">Other</option>
                          </select>
                        </div>
                        <div className="space-y-1">
                          <label className="text-[10px] font-bold text-slate-500 uppercase block">Date of Birth</label>
                          <input
                            type="text"
                            value={babyDob}
                            onChange={(e) => setBabyDob(e.target.value)}
                            placeholder="Oct 12, 2025"
                            className="w-full text-xs font-semibold px-3 py-2.5 bg-[#FAF7FF] border border-indigo-50 rounded-xl focus:outline-none focus:border-indigo-400"
                          />
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-3">
                        <div className="space-y-1">
                          <label className="text-[10px] font-bold text-slate-500 uppercase block">Weight (kg)</label>
                          <input
                            type="number"
                            step="0.1"
                            value={babyWeight}
                            onChange={(e) => setBabyWeight(parseFloat(e.target.value) || 3.2)}
                            className="w-full text-xs font-semibold px-3 py-2.5 bg-[#FAF7FF] border border-indigo-50 rounded-xl focus:outline-none focus:border-indigo-400"
                          />
                        </div>
                        <div className="space-y-1">
                          <label className="text-[10px] font-bold text-slate-500 uppercase block">Height (cm)</label>
                          <input
                            type="number"
                            step="0.1"
                            value={babyHeight}
                            onChange={(e) => setBabyHeight(parseFloat(e.target.value) || 50)}
                            className="w-full text-xs font-semibold px-3 py-2.5 bg-[#FAF7FF] border border-indigo-50 rounded-xl focus:outline-none focus:border-indigo-400"
                          />
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="flex gap-3 pt-2">
                    <button
                      onClick={() => setOnboardingStep(3)}
                      className="flex-1 bg-slate-50 border border-slate-100 text-slate-500 text-xs font-extrabold py-3 rounded-2xl hover:bg-slate-100 cursor-pointer"
                    >
                      Back
                    </button>
                    <button
                      onClick={() => {
                        if (!babyName.trim()) {
                          alert("Please enter your baby's name.");
                          return;
                        }
                        setOnboardingStep(5);
                      }}
                      className="flex-1 bg-indigo-600 text-white text-xs font-extrabold py-3 rounded-2xl shadow-md hover:bg-indigo-700 cursor-pointer"
                    >
                      Next Step
                    </button>
                  </div>
                </div>
              )}

              {/* SCREEN 6: CONNECT CRADLE */}
              {onboardingStep === 5 && (
                <div className="flex-1 flex flex-col justify-between h-full space-y-4">
                  <div className="space-y-4 text-center">
                    <div className="space-y-1">
                      <h3 className="text-base font-extrabold text-indigo-950">Device Connectivity</h3>
                      <p className="text-[11px] text-slate-400 max-w-[280px] mx-auto leading-snug">
                        Power on your Maatriva Smart Cradle nearby and choose an integration protocol below.
                      </p>
                    </div>

                    <div className="bg-white p-4 border border-indigo-50/50 rounded-3xl shadow-sm space-y-4 relative flex flex-col items-center justify-center">
                      {/* Radar Scanning Ring Graphics */}
                      <div className="relative w-24 h-24 flex items-center justify-center">
                        <div className={`absolute inset-0 rounded-full bg-indigo-100/50 ${cradleScanState === "scanning" ? "animate-ping" : ""}`}></div>
                        <div className="absolute inset-2 rounded-full bg-indigo-50 flex items-center justify-center shadow-inner">
                          <Wifi className={`w-8 h-8 ${cradleScanState === "connected" ? "text-emerald-500" : "text-indigo-600"}`} />
                        </div>
                      </div>

                      {cradleScanState === "idle" && (
                        <div className="text-center">
                          <p className="text-xs font-bold text-slate-700">Scanner Status: Unbound</p>
                          <span className="text-[9px] text-slate-400 block">Pair via Bluetooth LE or manual entry</span>
                        </div>
                      )}

                      {cradleScanState === "scanning" && (
                        <div className="text-center">
                          <p className="text-xs font-bold text-indigo-600 animate-pulse">Scanning Bluetooth LE waves...</p>
                          <span className="text-[9px] text-slate-400 block">Ensure Cradle purple LED is flashing</span>
                        </div>
                      )}

                      {cradleScanState === "found" && (
                        <div className="w-full space-y-2 text-left">
                          <span className="text-[8px] font-black text-slate-400 uppercase tracking-wider block">Nearby Hardware Found</span>
                          <div 
                            onClick={() => {
                              setCradleScanState("connected");
                              setConnectedCradleId("MTRV-CRADLE-8812");
                            }}
                            className="p-3 bg-indigo-50/50 border border-indigo-100 rounded-xl cursor-pointer hover:bg-indigo-100/40 flex justify-between items-center"
                          >
                            <div>
                              <p className="text-xs font-bold text-slate-800">Maatriva Smart Cradle #8812</p>
                              <p className="text-[9px] text-slate-400">Signal: Outstanding (BLE-98dB)</p>
                            </div>
                            <span className="text-[9px] font-black text-indigo-600 uppercase">Connect</span>
                          </div>
                        </div>
                      )}

                      {cradleScanState === "connected" && (
                        <div className="text-center">
                          <p className="text-xs font-black text-emerald-600 flex items-center gap-1.5 justify-center">
                            <Check className="w-4 h-4 stroke-[3]" /> Successfully Connected
                          </p>
                          <span className="text-[9px] text-slate-400 block">Bound ID: {connectedCradleId}</span>
                        </div>
                      )}
                    </div>

                    {cradleScanState === "idle" && (
                      <div className="space-y-2">
                        <div className="grid grid-cols-2 gap-2">
                          <button
                            onClick={() => setShowQrDialog(true)}
                            className="bg-white border border-indigo-50 py-2 rounded-xl text-[10px] font-black text-indigo-950 hover:bg-slate-50 flex items-center justify-center gap-1.5 shadow-xs cursor-pointer"
                          >
                            <QrCode className="w-3.5 h-3.5 text-indigo-600" /> QR Setup
                          </button>
                          <button
                            onClick={() => setShowManualDialog(true)}
                            className="bg-white border border-indigo-50 py-2 rounded-xl text-[10px] font-black text-indigo-950 hover:bg-slate-50 flex items-center justify-center gap-1.5 shadow-xs cursor-pointer"
                          >
                            <Wifi className="w-3.5 h-3.5 text-indigo-600" /> Manual Code
                          </button>
                        </div>
                        <button
                          onClick={() => {
                            setCradleScanState("scanning");
                            setTimeout(() => {
                              setCradleScanState("found");
                            }, 1500);
                          }}
                          className="w-full bg-indigo-600 text-white text-xs font-extrabold py-3 rounded-2xl hover:bg-indigo-700 shadow-sm cursor-pointer"
                        >
                          Start Bluetooth Scanning
                        </button>
                      </div>
                    )}

                    {cradleScanState === "scanning" && (
                      <button
                        onClick={() => setCradleScanState("idle")}
                        className="w-full bg-slate-100 border border-slate-200 text-slate-600 text-xs font-extrabold py-3 rounded-2xl hover:bg-slate-200 cursor-pointer"
                      >
                        Cancel Scanning
                      </button>
                    )}

                    {cradleScanState === "connected" && (
                      <button
                        onClick={() => {
                          setCradleScanState("idle");
                          setConnectedCradleId(null);
                        }}
                        className="w-full bg-rose-50 border border-rose-100 text-rose-600 text-xs font-extrabold py-3 rounded-2xl hover:bg-rose-100 cursor-pointer"
                      >
                        Disconnect Cradle
                      </button>
                    )}
                  </div>

                  <div className="space-y-2 pt-2">
                    {cradleScanState === "connected" ? (
                      <button
                        onClick={() => setOnboardingStep(6)}
                        className="w-full bg-indigo-600 text-white text-xs font-extrabold py-3.5 rounded-2xl shadow-md hover:bg-indigo-700 cursor-pointer"
                      >
                        Confirm & Next
                      </button>
                    ) : (
                      <button
                        onClick={() => setOnboardingStep(6)}
                        className="w-full text-indigo-600 text-[11px] font-black text-center py-2 hover:underline block cursor-pointer"
                      >
                        Configure cradle later (Skip)
                      </button>
                    )}
                    <button
                      onClick={() => setOnboardingStep(4)}
                      className="w-full bg-slate-50 border border-slate-100 text-slate-500 text-xs font-extrabold py-2.5 rounded-2xl hover:bg-slate-100 cursor-pointer"
                    >
                      Back
                    </button>
                  </div>
                </div>
              )}

              {/* SCREEN 7: SETUP COMPLETE */}
              {onboardingStep === 6 && (
                <div className="flex-1 flex flex-col justify-between h-full space-y-4 text-center">
                  <div className="space-y-4">
                    <div className="mx-auto w-16 h-16 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-500 border border-emerald-100 shadow-lg shadow-emerald-50 mt-4 animate-bounce">
                      <Check className="w-8 h-8 stroke-[3.5]" />
                    </div>

                    <div className="space-y-1">
                      <h3 className="text-lg font-black text-indigo-950">You're All Set!</h3>
                      <p className="text-[11px] text-slate-400 max-w-[280px] mx-auto leading-relaxed">
                        Maatriva has finished custom-tuning your AI nursery ecosystem and is now fully ready to protect {babyName}.
                      </p>
                    </div>

                    <div className="bg-white p-4 border border-indigo-50/50 rounded-3xl text-left shadow-sm space-y-3">
                      <div className="flex items-center gap-3">
                        <CheckCircle className="w-5 h-5 text-emerald-500 flex-shrink-0" />
                        <div>
                          <p className="text-xs font-bold text-slate-800">Caregiver Synced</p>
                          <p className="text-[9px] text-slate-400">{parentName} (Mother)</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-3 border-t border-slate-50 pt-3">
                        <CheckCircle className="w-5 h-5 text-emerald-500 flex-shrink-0" />
                        <div>
                          <p className="text-xs font-bold text-slate-800">Baby Calibration Complete</p>
                          <p className="text-[9px] text-slate-400">{babyName} • {babyDob} • {babyWeight}kg</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-3 border-t border-slate-50 pt-3">
                        <CheckCircle className="w-5 h-5 text-emerald-500 flex-shrink-0" />
                        <div>
                          <p className="text-xs font-bold text-slate-800">Hardware Suite Synced</p>
                          <p className="text-[9px] text-slate-400">{connectedCradleId ? `${connectedCradleId} connected` : "Setup as standalone hub"}</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  <button
                    onClick={() => {
                      setShowOnboarding(false);
                      setActiveTab(0);
                    }}
                    className="w-full bg-indigo-600 text-white text-xs font-extrabold py-3.5 rounded-2xl shadow-lg shadow-indigo-100 hover:bg-indigo-700 transition-all cursor-pointer"
                  >
                    Go to Dashboard
                  </button>
                </div>
              )}

            </div>

            {/* QR Setup Simulation Overlay Dialog */}
            {showQrDialog && (
              <div className="absolute inset-0 bg-black/60 z-50 flex items-center justify-center p-6 animate-fade-in">
                <div className="bg-white rounded-3xl p-5 text-center space-y-4 max-w-[280px] w-full border border-slate-100 shadow-xl mx-auto">
                  <h4 className="text-xs font-black text-slate-800 uppercase tracking-widest">Scan Cradle QR Code</h4>
                  <p className="text-[10px] text-slate-400 leading-relaxed">
                    Point your camera at the QR sticker under your Cradle base station hub.
                  </p>
                  <div className="mx-auto w-32 h-32 border-2 border-indigo-600 border-dashed rounded-2xl flex items-center justify-center bg-slate-50 relative">
                    <QrCode className="w-16 h-16 text-indigo-950 stroke-[1.5]" />
                    <div className="absolute top-2 left-2 w-3 h-3 border-t-2 border-l-2 border-indigo-600"></div>
                    <div className="absolute top-2 right-2 w-3 h-3 border-t-2 border-r-2 border-indigo-600"></div>
                    <div className="absolute bottom-2 left-2 w-3 h-3 border-b-2 border-l-2 border-indigo-600"></div>
                    <div className="absolute bottom-2 right-2 w-3 h-3 border-b-2 border-r-2 border-indigo-600"></div>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => setShowQrDialog(false)}
                      className="flex-grow bg-slate-100 text-slate-600 text-[10px] font-black py-2 rounded-xl cursor-pointer"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={() => {
                        setShowQrDialog(false);
                        setCradleScanState("connected");
                        setConnectedCradleId("MTRV-CRADLE-QR");
                      }}
                      className="flex-grow bg-indigo-600 text-white text-[10px] font-black py-2 rounded-xl shadow cursor-pointer"
                    >
                      Simulate Scan
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* Manual Entry Setup Simulation Overlay Dialog */}
            {showManualDialog && (
              <div className="absolute inset-0 bg-black/60 z-50 flex items-center justify-center p-6 animate-fade-in">
                <div className="bg-white rounded-3xl p-5 text-center space-y-4 max-w-[280px] w-full border border-slate-100 shadow-xl mx-auto">
                  <h4 className="text-xs font-black text-slate-800 uppercase tracking-widest">Manual Setup Code</h4>
                  <p className="text-[10px] text-slate-400 leading-relaxed">
                    Enter the 8-digit alpha-numeric sequence from your device manual.
                  </p>
                  <input
                    type="text"
                    placeholder="MTRV-XXXX"
                    value={manualCode}
                    onChange={(e) => setManualCode(e.target.value.toUpperCase())}
                    className="w-full text-center text-xs font-black tracking-widest uppercase px-3 py-2.5 bg-slate-50 border border-indigo-50 rounded-xl focus:outline-none"
                  />
                  <div className="flex gap-2">
                    <button
                      onClick={() => {
                        setShowManualDialog(false);
                        setManualCode("");
                      }}
                      className="flex-grow bg-slate-100 text-slate-600 text-[10px] font-black py-2 rounded-xl cursor-pointer"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={() => {
                        if (!manualCode.trim()) {
                          alert("Please enter a code.");
                          return;
                        }
                        setShowManualDialog(false);
                        setCradleScanState("connected");
                        setConnectedCradleId(manualCode);
                        setManualCode("");
                      }}
                      className="flex-grow bg-indigo-600 text-white text-[10px] font-black py-2 rounded-xl shadow cursor-pointer"
                    >
                      Pair Code
                    </button>
                  </div>
                </div>
              </div>
            )}

          </div>
        )}

        {/* ========================================================================= */}
        {/* NOTIFICATIONS MODULE OVERLAY (FULL PHONE SCREEN) */}
        {/* ========================================================================= */}
        {showNotifications && (
          <div className="absolute inset-0 bg-[#FBF8FD] z-50 pt-8 pb-4 flex flex-col animate-fade-in font-sans">
            {/* Header */}
            <div className="bg-white border-b border-indigo-50 px-4 py-3 flex items-center justify-between shadow-xs">
              <div className="flex items-center gap-2">
                <button 
                  onClick={() => {
                    setShowNotifications(false);
                    setNotifSearch("");
                    setNotifCategory("All");
                  }}
                  className="p-1.5 hover:bg-slate-100 rounded-full transition-colors cursor-pointer"
                >
                  <ArrowLeft className="w-5 h-5 text-indigo-950" />
                </button>
                <span className="text-base font-extrabold text-indigo-950">Notifications</span>
              </div>
              <div className="flex items-center gap-2">
                {notifications.some(n => !n.isRead) && (
                  <button 
                    onClick={() => {
                      setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
                    }}
                    className="text-xs font-bold text-indigo-600 hover:text-indigo-800 transition-colors cursor-pointer"
                  >
                    Mark all read
                  </button>
                )}
                <div className="p-1 text-slate-400">
                  <Sliders className="w-4 h-4 text-slate-500" />
                </div>
              </div>
            </div>

            {/* Search Bar */}
            <div className="px-4 py-2 bg-white">
              <div className="flex items-center gap-2 px-3 py-2 bg-slate-50 border border-slate-100 rounded-xl">
                <Search className="w-4 h-4 text-slate-400" />
                <input 
                  type="text"
                  placeholder="Search notifications"
                  value={notifSearch}
                  onChange={(e) => setNotifSearch(e.target.value)}
                  className="w-full bg-transparent text-xs text-slate-800 placeholder:text-slate-400 focus:outline-none"
                />
                {notifSearch && (
                  <button onClick={() => setNotifSearch("")} className="text-slate-400 font-bold text-xs">✕</button>
                )}
              </div>
            </div>

            {/* Category Filter Chips */}
            <div className="bg-white px-4 pb-3 flex gap-2 overflow-x-auto no-scrollbar pt-1 border-b border-indigo-50">
              {['All', 'Critical', 'Health', 'Sleep', 'Activity', 'Caregiver', 'Reports'].map(filter => {
                const isSelected = notifCategory === filter;
                return (
                  <button
                    key={filter}
                    onClick={() => setNotifCategory(filter)}
                    className={`flex-shrink-0 px-3.5 py-1.5 rounded-full text-[11px] font-bold transition-all cursor-pointer ${
                      isSelected 
                        ? 'bg-gradient-to-r from-indigo-600 to-violet-500 text-white shadow-sm' 
                        : 'bg-indigo-50/50 text-indigo-950 border border-indigo-100/50 hover:bg-indigo-50'
                    }`}
                  >
                    {filter}
                  </button>
                );
              })}
            </div>

            {/* Notifications Scroll Area */}
            <div className="flex-1 overflow-y-auto px-4 py-3 space-y-4">
              {(() => {
                // Filter notifications
                let list = [...notifications];
                if (notifCategory !== 'All') {
                  list = list.filter(n => n.category.toLowerCase() === notifCategory.toLowerCase());
                }
                if (notifSearch) {
                  const q = notifSearch.toLowerCase();
                  list = list.filter(n => 
                    n.title.toLowerCase().includes(q) || 
                    n.description.toLowerCase().includes(q)
                  );
                }

                if (list.length === 0) {
                  return (
                    <div className="flex flex-col items-center justify-center h-full py-12 text-center px-4">
                      <div className="w-16 h-16 rounded-full bg-indigo-50/50 flex items-center justify-center mb-4">
                        <Bell className="w-8 h-8 text-indigo-300" />
                      </div>
                      <h4 className="text-sm font-bold text-slate-800">No notifications yet</h4>
                      <p className="text-[11px] text-slate-400 mt-1 max-w-[200px]">
                        We'll notify you whenever your baby needs attention or health reports are ready.
                      </p>
                      <button
                        onClick={() => {
                          setNotifications(MOCK_NOTIFICATIONS);
                          setNotifSearch("");
                          setNotifCategory("All");
                        }}
                        className="mt-4 px-4 py-2 bg-indigo-600 text-white text-[11px] font-bold rounded-xl shadow-md hover:bg-indigo-700 cursor-pointer"
                      >
                        Restore Mock List
                      </button>
                    </div>
                  );
                }

                // Group notifications
                const sections = {
                  'Today': list.filter(n => n.section === 'Today'),
                  'Yesterday': list.filter(n => n.section === 'Yesterday'),
                  'Earlier': list.filter(n => n.section === 'Earlier')
                };

                return (
                  <div className="space-y-4">
                    {Object.entries(sections).map(([secName, secItems]) => {
                      if (secItems.length === 0) return null;
                      return (
                        <div key={secName} className="space-y-2">
                          <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest pl-1">
                            {secName}
                          </span>
                          <div className="space-y-2.5">
                            {secItems.map(notif => {
                              // Get category style
                              let colorClass = 'bg-slate-100 text-slate-600';
                              let iconBg = 'bg-slate-50';
                              if (notif.category === 'critical') {
                                colorClass = 'bg-rose-50 border-rose-100 text-rose-600';
                                iconBg = 'bg-rose-100 text-rose-600';
                              } else if (notif.category === 'health') {
                                colorClass = 'bg-amber-50 border-amber-100 text-amber-700';
                                iconBg = 'bg-amber-100 text-amber-700';
                              } else if (notif.category === 'sleep') {
                                colorClass = 'bg-purple-50 border-purple-100 text-purple-700';
                                iconBg = 'bg-purple-100 text-purple-700';
                              } else if (notif.category === 'activity') {
                                colorClass = 'bg-emerald-50 border-emerald-100 text-emerald-700';
                                iconBg = 'bg-emerald-100 text-emerald-700';
                              } else if (notif.category === 'caregiver') {
                                colorClass = 'bg-violet-50 border-violet-100 text-violet-700';
                                iconBg = 'bg-violet-100 text-violet-700';
                              } else if (notif.category === 'reports') {
                                colorClass = 'bg-blue-50 border-blue-100 text-blue-700';
                                iconBg = 'bg-blue-100 text-blue-700';
                              }

                              return (
                                <div 
                                  key={notif.id}
                                  className={`relative group bg-white border rounded-2xl p-3 shadow-xs transition-all flex items-start justify-between gap-2 border-indigo-50/50 ${
                                    !notif.isRead ? 'bg-[#FAF7FF] border-indigo-200' : 'bg-white hover:bg-slate-50/50'
                                  }`}
                                >
                                  {/* Tap Zone */}
                                  <div 
                                    onClick={() => {
                                      // Mark as read
                                      setNotifications(prev => prev.map(n => n.id === notif.id ? { ...n, isRead: true } : n));
                                      setSelectedNotification(notif);
                                    }}
                                    className="flex-1 flex gap-3 cursor-pointer"
                                  >
                                    <div className={`w-9 h-9 rounded-full ${iconBg} flex items-center justify-center flex-shrink-0 text-xs font-bold`}>
                                      {notif.category === 'critical' && <AlertTriangle className="w-4 h-4 text-rose-600" />}
                                      {notif.category === 'health' && <Thermometer className="w-4 h-4 text-amber-600" />}
                                      {notif.category === 'sleep' && <Moon className="w-4 h-4 text-purple-600" />}
                                      {notif.category === 'activity' && <Smile className="w-4 h-4 text-emerald-600" />}
                                      {notif.category === 'caregiver' && <User className="w-4 h-4 text-violet-600" />}
                                      {notif.category === 'reports' && <BarChart3 className="w-4 h-4 text-blue-600" />}
                                    </div>
                                    <div className="space-y-0.5 pr-1 text-left">
                                      <div className="flex items-center gap-1.5 flex-wrap">
                                        <h5 className="text-[12px] font-extrabold text-indigo-950 leading-tight">
                                          {notif.title}
                                        </h5>
                                        <span className={`text-[8px] font-black uppercase px-1 py-0.5 rounded ${colorClass}`}>
                                          {notif.priority}
                                        </span>
                                      </div>
                                      <p className="text-[10.5px] text-slate-500 leading-snug">
                                        {notif.description}
                                      </p>
                                      <span className="block text-[8.5px] font-semibold text-slate-400">
                                        {notif.timestamp}
                                      </span>
                                    </div>
                                  </div>

                                  {/* Actions Menu */}
                                  <div className="flex flex-col gap-2 items-center justify-center pl-1">
                                    {/* Unread indicator / Mark read toggle */}
                                    <button
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        setNotifications(prev => prev.map(n => n.id === notif.id ? { ...n, isRead: !n.isRead } : n));
                                      }}
                                      className={`p-1 rounded-full transition-colors cursor-pointer ${
                                        !notif.isRead ? 'text-indigo-600 hover:bg-indigo-50' : 'text-slate-300 hover:bg-slate-100'
                                      }`}
                                      title={notif.isRead ? "Mark Unread" : "Mark Read"}
                                    >
                                      <CheckCircle className={`w-3.5 h-3.5 ${!notif.isRead ? 'fill-indigo-600 text-white' : ''}`} />
                                    </button>

                                    {/* Delete button */}
                                    <button
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        setNotifications(prev => prev.filter(n => n.id !== notif.id));
                                      }}
                                      className="p-1 rounded-full text-rose-500 hover:bg-rose-50 transition-colors cursor-pointer"
                                      title="Delete"
                                    >
                                      <Trash2 className="w-3.5 h-3.5" />
                                    </button>
                                  </div>
                                </div>
                              );
                            })}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                );
              })()}
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* NOTIFICATION DETAIL OVERLAY (z-60 COVER) */}
        {/* ========================================================================= */}
        {selectedNotification && (
          <div className="absolute inset-0 bg-[#FBF8FD] z-[60] pt-8 pb-4 flex flex-col animate-fade-in font-sans">
            {/* Header */}
            <div className="bg-white border-b border-indigo-50 px-4 py-3 flex items-center justify-between shadow-xs">
              <div className="flex items-center gap-2">
                <button 
                  onClick={() => setSelectedNotification(null)}
                  className="p-1.5 hover:bg-slate-100 rounded-full transition-colors cursor-pointer"
                >
                  <ArrowLeft className="w-5 h-5 text-indigo-950" />
                </button>
                <span className="text-base font-extrabold text-indigo-950">Detail Insight</span>
              </div>
              <span className="text-[9px] font-black uppercase px-2 py-0.5 rounded-full bg-indigo-50 text-indigo-600 border border-indigo-100">
                {selectedNotification.category}
              </span>
            </div>

            {/* Scroll Area */}
            <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4">
              
              {/* Graphic Title block */}
              <div className="bg-white border border-indigo-50 p-5 rounded-3xl text-center space-y-3 shadow-xs">
                <div className="mx-auto w-14 h-14 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600 text-lg font-bold">
                  {selectedNotification.category === 'critical' && <AlertTriangle className="w-6 h-6 text-rose-600" />}
                  {selectedNotification.category === 'health' && <Thermometer className="w-6 h-6 text-amber-600" />}
                  {selectedNotification.category === 'sleep' && <Moon className="w-6 h-6 text-purple-600" />}
                  {selectedNotification.category === 'activity' && <Smile className="w-6 h-6 text-emerald-600" />}
                  {selectedNotification.category === 'caregiver' && <User className="w-6 h-6 text-violet-600" />}
                  {selectedNotification.category === 'reports' && <BarChart3 className="w-6 h-6 text-blue-600" />}
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-indigo-950 leading-tight">
                    {selectedNotification.title}
                  </h3>
                  <p className="text-[11px] font-bold text-slate-400 mt-1">
                    {selectedNotification.timestamp} • {selectedNotification.priority.toUpperCase()} PRIORITY
                  </p>
                </div>
              </div>

              {/* Hardware / Sensor Metadata Card */}
              <div className="bg-white border border-slate-100 p-4 rounded-2xl shadow-xs grid grid-cols-2 gap-3">
                <div className="space-y-1 text-left">
                  <span className="text-[8.5px] font-black text-slate-400 uppercase tracking-widest block">Device Involved</span>
                  <div className="flex items-center gap-1.5 text-[11px] text-indigo-950 font-bold">
                    <Tv className="w-3.5 h-3.5 text-indigo-600 flex-shrink-0" />
                    <span className="truncate">{selectedNotification.deviceResponsible}</span>
                  </div>
                </div>
                <div className="space-y-1 border-l pl-3 text-left">
                  <span className="text-[8.5px] font-black text-slate-400 uppercase tracking-widest block">Sensor Engine</span>
                  <div className="flex items-center gap-1.5 text-[11px] text-indigo-950 font-bold">
                    <ShieldCheck className="w-3.5 h-3.5 text-indigo-600 flex-shrink-0" />
                    <span className="truncate">{selectedNotification.sensorResponsible}</span>
                  </div>
                </div>
              </div>

              {/* Detailed Summary */}
              <div className="space-y-1.5 text-left">
                <span className="text-[10px] font-black text-indigo-950 uppercase tracking-widest pl-1">Detailed Summary</span>
                <div className="bg-white border border-indigo-50/50 p-4 rounded-2xl shadow-xs text-xs text-slate-600 leading-relaxed">
                  {selectedNotification.detailedExplanation}
                </div>
              </div>

              {/* Recommended Action */}
              <div className="space-y-1.5 text-left">
                <span className="text-[10px] font-black text-indigo-950 uppercase tracking-widest pl-1">Recommended Action</span>
                <div className="bg-emerald-50/40 border border-emerald-100/60 p-4 rounded-2xl shadow-xs flex gap-3 items-start">
                  <div className="p-1 rounded-full bg-emerald-100 text-emerald-700 mt-0.5">
                    <Check className="w-3 h-3 stroke-[3]" />
                  </div>
                  <p className="text-xs font-bold text-slate-800 leading-snug">
                    {selectedNotification.recommendedAction}
                  </p>
                </div>
              </div>

              {/* AI Insight Box */}
              <div className="bg-gradient-to-br from-indigo-600 to-indigo-500 text-white p-5 rounded-3xl space-y-2 shadow-md text-left">
                <div className="flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-amber-200 fill-amber-200 animate-pulse" />
                  <span className="text-[9px] font-black uppercase tracking-wider text-indigo-100">MAATRIVA AI COGNITIVE INSIGHT</span>
                </div>
                <p className="text-xs text-indigo-50 leading-relaxed font-medium">
                  {selectedNotification.aiInsight}
                </p>
              </div>

            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* BABY MUSIC PLAYER OVERLAY SYSTEM (FULL PORTABLE PLAYBACK ENGINE) */}
        {/* ========================================================================= */}
        {showMusicPlayer && (() => {
          const SIM_SONGS = [
            { id: "s1", title: "Sweet Sleep Chopin Waltz", artist: "Maatriva Acoustic Trio", category: "Lullabies", duration: 225, color: "purple" },
            { id: "s2", title: "White Noise Womb Sound", artist: "Maternity Sound Lab", category: "White Noise", duration: 600, color: "blue" },
            { id: "s3", title: "Midnight Soft Rainfalls", artist: "Nursery Nature Harmony", category: "Nature Sounds", duration: 340, color: "teal" },
            { id: "s4", title: "Golden Slumbers Guitar", artist: "Nursery Acoustic Band", category: "Lullabies", duration: 180, color: "sunset" },
            { id: "s5", title: "Mother Heartbeat Simulation", artist: "Smart Crib Audio Hub", category: "Heartbeat Sounds", duration: 480, color: "rose" },
            { id: "s6", title: "Little Star Music Box", artist: "Maatriva Bells Ensemble", category: "Lullabies", duration: 150, color: "lavender" },
            { id: "s7", title: "Forest Birdsong & Wind", artist: "Nursery Nature Harmony", category: "Nature Sounds", duration: 300, color: "emerald" },
            { id: "s8", title: "Gentle Ocean Wave Whispers", artist: "Sea Breeze Acoustics", category: "Ocean Waves", duration: 420, color: "mint" },
            { id: "s9", title: "Mozart Brain Development", artist: "Classical Baby Orchestra", category: "Classical", duration: 310, color: "indigo" },
          ];

          // React position tick timer inside the anonymous scope
          const [simPlayerExpanded, setSimPlayerExpanded] = useState(false);
          const [simShuffle, setSimShuffle] = useState(false);
          const [simRepeat, setSimRepeat] = useState(false);
          const [showTimerMenu, setShowTimerMenu] = useState(false);

          // Simulated playlist selections
          const [selectedPlaylist, setSelectedPlaylist] = useState<string | null>(null);

          // Formatter helper
          const formatTime = (secs: number) => {
            const m = Math.floor(secs / 60);
            const s = Math.floor(secs % 60).toString().padStart(2, "0");
            return `${m}:${s}`;
          };

          const handleSongSelect = (song: typeof SIM_SONGS[0]) => {
            setSimCurrentSong(song);
            setSimPosition(0);
            setSimIsPlaying(true);
            setSimPlayerExpanded(true);
          };

          const handlePrevSong = () => {
            const currentIdx = SIM_SONGS.findIndex(s => s.id === simCurrentSong.id);
            const prevIdx = currentIdx <= 0 ? SIM_SONGS.length - 1 : currentIdx - 1;
            setSimCurrentSong(SIM_SONGS[prevIdx]);
            setSimPosition(0);
          };

          const handleNextSong = () => {
            const currentIdx = SIM_SONGS.findIndex(s => s.id === simCurrentSong.id);
            const nextIdx = currentIdx === SIM_SONGS.length - 1 ? 0 : currentIdx + 1;
            setSimCurrentSong(SIM_SONGS[nextIdx]);
            setSimPosition(0);
          };

          // Filter logic
          let filteredSongs = SIM_SONGS;
          if (simCategory !== "All") {
            filteredSongs = filteredSongs.filter(s => s.category === simCategory);
          }
          if (simSearch) {
            const query = simSearch.toLowerCase();
            filteredSongs = filteredSongs.filter(s => 
              s.title.toLowerCase().includes(query) || 
              s.artist.toLowerCase().includes(query)
            );
          }
          if (selectedPlaylist === "Favorites") {
            filteredSongs = filteredSongs.filter(s => simFavs.includes(s.id));
          } else if (selectedPlaylist === "Newborn Sleep") {
            filteredSongs = filteredSongs.filter(s => s.category === "Heartbeat Sounds" || s.category === "White Noise");
          } else if (selectedPlaylist === "Night Sleep") {
            filteredSongs = filteredSongs.filter(s => s.category === "Lullabies");
          }

          const isFav = simFavs.includes(simCurrentSong.id);

          return (
            <div className="absolute inset-0 bg-[#FBF8FD] z-50 pt-8 pb-4 flex flex-col animate-fade-in font-sans">
              
              {/* --- 1. EXPANDED MUSIC PLAYER VIEW --- */}
              {simPlayerExpanded ? (
                <div className="flex-1 flex flex-col justify-between px-5 py-2">
                  {/* Top Bar */}
                  <div className="flex justify-between items-center">
                    <button 
                      onClick={() => setSimPlayerExpanded(false)}
                      className="p-1.5 hover:bg-indigo-50 rounded-full transition-colors cursor-pointer"
                    >
                      <ArrowLeft className="w-5 h-5 text-indigo-950" />
                    </button>
                    <div className="text-center">
                      <span className="block text-[8px] font-black uppercase tracking-widest text-indigo-600">Now Playing</span>
                      <span className="text-[10px] font-bold text-slate-500 uppercase">{simCurrentSong.category}</span>
                    </div>
                    <button 
                      onClick={() => setShowTimerMenu(!showTimerMenu)}
                      className={`p-1.5 rounded-full transition-all ${simTimer !== null ? "bg-indigo-50 text-indigo-600" : "hover:bg-indigo-50 text-indigo-950"}`}
                    >
                      <Clock className="w-4 h-4" />
                    </button>
                  </div>

                  {/* Sleep Timer Configuration overlay */}
                  {showTimerMenu && (
                    <div className="bg-white border border-indigo-100 rounded-2xl p-3 shadow-md space-y-2 text-left z-20">
                      <span className="text-[9px] font-black text-indigo-600 uppercase block">Set Sleep Timer</span>
                      <div className="grid grid-cols-4 gap-1.5">
                        {[5, 15, 30, 45].map(min => (
                          <button
                            key={min}
                            onClick={() => {
                              setSimTimer(min);
                              setShowTimerMenu(false);
                            }}
                            className={`text-[9px] font-bold py-1.5 rounded-lg border text-center ${simTimer === min ? "bg-indigo-600 text-white" : "bg-white text-slate-600"}`}
                          >
                            {min}m
                          </button>
                        ))}
                      </div>
                      {simTimer !== null && (
                        <button 
                          onClick={() => {
                            setSimTimer(null);
                            setShowTimerMenu(false);
                          }}
                          className="w-full bg-red-50 text-red-600 text-[9px] font-bold py-1 rounded-lg mt-1"
                        >
                          Cancel Timer
                        </button>
                      )}
                    </div>
                  )}

                  {/* Rotating Vinyl Graphic disc */}
                  <div className="flex flex-col items-center justify-center py-6">
                    <div className={`relative w-48 h-48 rounded-full shadow-lg flex items-center justify-center bg-indigo-950 border-4 border-indigo-900 ${simIsPlaying ? "animate-spin" : ""}`} style={{ animationDuration: "12s" }}>
                      {/* Album art cover gradient */}
                      <div className={`absolute inset-4 rounded-full flex items-center justify-center opacity-90 bg-gradient-to-br ${
                        simCurrentSong.color === "purple" ? "from-[#8E2DE2] to-[#4A00E0]" :
                        simCurrentSong.color === "blue" ? "from-[#00c6ff] to-[#0072ff]" :
                        simCurrentSong.color === "rose" ? "from-[#FF416C] to-[#FF4B2B]" :
                        simCurrentSong.color === "teal" ? "from-[#11998e] to-[#38ef7d]" :
                        "from-[#9d85fc] to-[#e299ff]"
                      }`}>
                        <Music className="w-10 h-10 text-white/80" />
                      </div>
                      {/* Inner grooves */}
                      <div className="absolute inset-8 border border-white/5 rounded-full"></div>
                      <div className="absolute inset-14 border border-white/5 rounded-full"></div>
                      {/* Spindle hole */}
                      <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center shadow-inner">
                        <div className="w-3.5 h-3.5 rounded-full bg-slate-800"></div>
                      </div>
                    </div>

                    {simTimer !== null && (
                      <span className="mt-4 bg-indigo-50 border border-indigo-100 text-indigo-700 text-[9px] font-bold px-2.5 py-1 rounded-full flex items-center gap-1.5 animate-pulse">
                        <Clock className="w-3 h-3" /> Stop in {simTimer} min
                      </span>
                    )}
                  </div>

                  {/* Song Details Row */}
                  <div className="space-y-1 text-left">
                    <div className="flex justify-between items-center">
                      <h3 className="text-base font-black text-slate-800 truncate max-w-[200px]">{simCurrentSong.title}</h3>
                      <button 
                        onClick={() => {
                          if (isFav) {
                            setSimFavs(prev => prev.filter(id => id !== simCurrentSong.id));
                          } else {
                            setSimFavs(prev => [...prev, simCurrentSong.id]);
                          }
                        }}
                        className="text-red-500 cursor-pointer"
                      >
                        <Heart className={`w-5 h-5 ${isFav ? "fill-red-500" : ""}`} />
                      </button>
                    </div>
                    <p className="text-xs text-slate-500 font-semibold">{simCurrentSong.artist}</p>
                  </div>

                  {/* Progress Slider */}
                  <div className="space-y-1 pt-4">
                    <input 
                      type="range"
                      min={0}
                      max={simCurrentSong.duration}
                      value={simPosition}
                      onChange={(e) => setSimPosition(parseInt(e.target.value))}
                      className="w-full accent-indigo-600 h-1 bg-indigo-50 rounded-lg cursor-pointer"
                    />
                    <div className="flex justify-between text-[10px] text-slate-400 font-bold">
                      <span>{formatTime(simPosition)}</span>
                      <span>{formatTime(simCurrentSong.duration)}</span>
                    </div>
                  </div>

                  {/* Controls Grid */}
                  <div className="flex justify-between items-center px-4">
                    <button 
                      onClick={() => setSimShuffle(!simShuffle)}
                      className={`p-1.5 transition-colors cursor-pointer ${simShuffle ? "text-indigo-600" : "text-slate-400"}`}
                    >
                      <Plus className={`w-4 h-4 transform rotate-45 ${simShuffle ? "stroke-[3]" : ""}`} />
                    </button>
                    <button onClick={handlePrevSong} className="p-1.5 text-slate-800 hover:bg-slate-100 rounded-full cursor-pointer">
                      <ChevronLeft className="w-6 h-6 stroke-[2.5]" />
                    </button>
                    <button 
                      onClick={() => setSimIsPlaying(!simIsPlaying)}
                      className="w-14 h-14 bg-indigo-600 hover:bg-indigo-700 active:scale-95 text-white rounded-full flex items-center justify-center shadow-lg shadow-indigo-100 transition-all cursor-pointer"
                    >
                      {simIsPlaying ? <Plus className="w-6 h-6 transform rotate-45 stroke-[3]" /> : <Play className="w-5 h-5 fill-white" />}
                    </button>
                    <button onClick={handleNextSong} className="p-1.5 text-slate-800 hover:bg-slate-100 rounded-full cursor-pointer">
                      <ChevronRight className="w-6 h-6 stroke-[2.5]" />
                    </button>
                    <button 
                      onClick={() => setSimRepeat(!simRepeat)}
                      className={`p-1.5 transition-colors cursor-pointer ${simRepeat ? "text-indigo-600" : "text-slate-400"}`}
                    >
                      <RotateCw className="w-4 h-4" />
                    </button>
                  </div>

                  {/* Volume & Speed Drawer Section */}
                  <div className="bg-white border border-indigo-50/50 p-3.5 rounded-3xl mt-4 space-y-2">
                    {/* Volume Row */}
                    <div className="flex items-center gap-2">
                      <Volume1 className="w-4 h-4 text-slate-400" />
                      <input 
                        type="range"
                        min={0}
                        max={100}
                        value={simVolume}
                        onChange={(e) => setSimVolume(parseInt(e.target.value))}
                        className="flex-1 accent-indigo-500 h-1 bg-slate-100 rounded-lg cursor-pointer"
                      />
                      <Volume2 className="w-4 h-4 text-slate-400" />
                    </div>

                    {/* Speed Row */}
                    <div className="flex justify-between items-center pt-2 border-t text-[10px] font-bold text-slate-500">
                      <span>Acoustic Sync Rate</span>
                      <div className="flex gap-1.5">
                        {["0.5x", "1.0x", "1.5x", "2.0x"].map(spd => (
                          <button
                            key={spd}
                            onClick={() => setSimSpeed(spd)}
                            className={`px-2 py-1 rounded-md text-[9px] ${simSpeed === spd ? "bg-indigo-600 text-white" : "bg-slate-50 text-slate-600 border"}`}
                          >
                            {spd}
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              ) : (
                /* --- 2. MUSIC CATALOG LIBRARY VIEW --- */
                <div className="flex-grow flex flex-col justify-between h-full">
                  {/* Top Header */}
                  <div className="px-4 py-1.5 flex items-center justify-between border-b">
                    <div className="flex items-center gap-1.5 text-left">
                      <button 
                        onClick={() => {
                          setShowMusicPlayer(false);
                          setSelectedPlaylist(null);
                        }}
                        className="p-1.5 hover:bg-slate-100 rounded-full cursor-pointer"
                      >
                        <ArrowLeft className="w-5 h-5 text-indigo-950" />
                      </button>
                      <div>
                        <span className="text-base font-extrabold text-indigo-950 block leading-tight">Baby Music</span>
                        <span className="text-[9px] font-bold text-slate-400 uppercase tracking-widest block">Continuous Sleep Ambient</span>
                      </div>
                    </div>
                    
                    {/* Favorites quick entry */}
                    <button 
                      onClick={() => setSelectedPlaylist(selectedPlaylist === "Favorites" ? null : "Favorites")}
                      className={`p-2 rounded-full relative transition-all ${selectedPlaylist === "Favorites" ? "bg-red-50 text-red-500" : "bg-indigo-50 text-indigo-600"}`}
                    >
                      <Heart className="w-4 h-4 fill-current" />
                      {simFavs.length > 0 && (
                        <span className="absolute -top-1 -right-1 bg-indigo-600 text-white text-[7px] w-4 h-4 rounded-full flex items-center justify-center font-bold">
                          {simFavs.length}
                        </span>
                      )}
                    </button>
                  </div>

                  {/* Body List Area */}
                  <div className="flex-1 overflow-y-auto px-4 py-3 space-y-4 pb-20">
                    
                    {/* Featured collection hero card */}
                    {!selectedPlaylist && !simSearch && (
                      <div className="bg-gradient-to-br from-indigo-700 to-indigo-500 text-white p-4 rounded-3xl text-left shadow-md space-y-3 relative overflow-hidden">
                        <div className="absolute right-0 bottom-0 opacity-10 transform translate-x-4 translate-y-4">
                          <Music className="w-32 h-32" />
                        </div>
                        <span className="bg-white/20 text-white text-[8px] font-black uppercase tracking-wider px-2 py-0.5 rounded-full">
                          Featured Sleep Collection
                        </span>
                        <div>
                          <h4 className="text-sm font-black leading-tight">Relaxing lullabies for peaceful sleep</h4>
                          <p className="text-[10px] text-white/80 mt-1 max-w-[200px] leading-relaxed">
                            Continuous smart acoustic soother tuned with pediatric sleep frequencies.
                          </p>
                        </div>
                        <button 
                          onClick={() => handleSongSelect(SIM_SONGS[0])}
                          className="bg-white hover:bg-slate-100 text-indigo-700 text-[10px] font-black px-4 py-2 rounded-xl shadow-sm transition-colors cursor-pointer"
                        >
                          Play Now
                        </button>
                      </div>
                    )}

                    {/* Search Field */}
                    <div className="flex gap-2">
                      <div className="flex-1 bg-white border rounded-xl px-2.5 flex items-center gap-2 h-9 shadow-xs">
                        <Search className="w-3.5 h-3.5 text-slate-400" />
                        <input 
                          type="text" 
                          placeholder="Search sleep music..." 
                          className="bg-transparent border-none outline-none text-[11px] flex-1 text-slate-700" 
                          value={simSearch}
                          onChange={(e) => setSimSearch(e.target.value)}
                        />
                      </div>
                    </div>

                    {/* horizontal category scroll */}
                    {!selectedPlaylist && (
                      <div className="flex gap-1.5 overflow-x-auto no-scrollbar pb-1">
                        {["All", "Lullabies", "White Noise", "Nature Sounds"].map(cat => (
                          <button
                            key={cat}
                            onClick={() => setSimCategory(cat)}
                            className={`flex-shrink-0 px-3 py-1.5 rounded-full text-[10px] font-extrabold transition-all border cursor-pointer ${
                              simCategory === cat 
                                ? "bg-indigo-600 text-white border-indigo-600" 
                                : "bg-white text-slate-600 border-indigo-50"
                            }`}
                          >
                            {cat}
                          </button>
                        ))}
                      </div>
                    )}

                    {/* Bento Predefined Playlists */}
                    {!selectedPlaylist && !simSearch && (
                      <div className="space-y-1.5">
                        <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest block pl-1">Acoustic Playlists</span>
                        <div className="grid grid-cols-2 gap-2">
                          <div 
                            onClick={() => setSelectedPlaylist("Newborn Sleep")}
                            className="bg-white border p-3 rounded-2xl shadow-xs text-left cursor-pointer hover:bg-slate-50"
                          >
                            <span className="p-1 rounded-lg bg-blue-50 text-blue-500 w-fit block mb-1">👶</span>
                            <h5 className="text-[11.5px] font-bold text-slate-800">Newborn Sleep</h5>
                            <p className="text-[8px] text-slate-400 leading-none">Womb mimic sounds</p>
                          </div>
                          <div 
                            onClick={() => setSelectedPlaylist("Night Sleep")}
                            className="bg-white border p-3 rounded-2xl shadow-xs text-left cursor-pointer hover:bg-slate-50"
                          >
                            <span className="p-1 rounded-lg bg-purple-50 text-purple-500 w-fit block mb-1">🌙</span>
                            <h5 className="text-[11.5px] font-bold text-slate-800">Night Sleep</h5>
                            <p className="text-[8px] text-slate-400 leading-none">Gentle nighttime hums</p>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Predefined playlist title indicator */}
                    {selectedPlaylist && (
                      <div className="flex justify-between items-center bg-indigo-50/50 p-2 rounded-xl text-left border border-indigo-100">
                        <span className="text-[10px] font-bold text-indigo-950 flex items-center gap-1.5">
                          📂 Playlist: {selectedPlaylist}
                        </span>
                        <button 
                          onClick={() => setSelectedPlaylist(null)}
                          className="text-[9px] font-black text-indigo-600 uppercase tracking-wide hover:underline"
                        >
                          Show All
                        </button>
                      </div>
                    )}

                    {/* List of filtered songs */}
                    <div className="space-y-2">
                      <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest block pl-1">
                        {selectedPlaylist ? "Playlist Tracks" : "All Sound Soothers"} ({filteredSongs.length})
                      </span>
                      {filteredSongs.length === 0 ? (
                        <div className="text-center py-10 bg-white border border-dashed rounded-2xl space-y-1 text-slate-400">
                          <p className="text-[11px] font-bold">No songs matching filter.</p>
                          <span className="text-[9px] block">Clear search queries or try another category.</span>
                        </div>
                      ) : (
                        filteredSongs.map(song => {
                          const playingThis = simCurrentSong.id === song.id;
                          return (
                            <div 
                              key={song.id}
                              onClick={() => handleSongSelect(song)}
                              className={`p-2.5 bg-white border rounded-2xl shadow-xs flex items-center justify-between gap-3 cursor-pointer hover:bg-slate-50 transition-colors ${
                                playingThis ? "border-indigo-300 bg-indigo-50/20" : "border-slate-100"
                              }`}
                            >
                              <div className="flex items-center gap-2.5 min-w-0 flex-1">
                                <div className={`w-9 h-9 rounded-xl flex items-center justify-center text-white font-bold text-xs bg-gradient-to-br ${
                                  song.color === "purple" ? "from-[#8E2DE2] to-[#4A00E0]" :
                                  song.color === "blue" ? "from-[#00c6ff] to-[#0072ff]" :
                                  song.color === "rose" ? "from-[#FF416C] to-[#FF4B2B]" :
                                  "from-[#11998e] to-[#38ef7d]"
                                }`}>
                                  {playingThis && simIsPlaying ? "🔊" : "🎵"}
                                </div>
                                <div className="text-left min-w-0">
                                  <h5 className={`text-[11.5px] font-bold truncate ${playingThis ? "text-indigo-600" : "text-slate-800"}`}>
                                    {song.title}
                                  </h5>
                                  <p className="text-[9px] text-slate-400 truncate leading-none mt-0.5">{song.artist}</p>
                                </div>
                              </div>
                              <div className="flex items-center gap-1 flex-shrink-0">
                                <span className="text-[9px] text-slate-400 font-bold">{formatTime(song.duration)}</span>
                                <button 
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    if (simFavs.includes(song.id)) {
                                      setSimFavs(prev => prev.filter(id => id !== song.id));
                                    } else {
                                      setSimFavs(prev => [...prev, song.id]);
                                    }
                                  }}
                                  className="text-red-500 p-1 hover:bg-slate-100 rounded-full"
                                >
                                  <Heart className={`w-3.5 h-3.5 ${simFavs.includes(song.id) ? "fill-red-500" : ""}`} />
                                </button>
                              </div>
                            </div>
                          );
                        })
                      )}
                    </div>
                  </div>

                  {/* Persistent Mini Player overlay bar */}
                  {simCurrentSong && (
                    <div 
                      onClick={() => setSimPlayerExpanded(true)}
                      className="absolute bottom-0 left-0 right-0 h-14 bg-white border-t border-indigo-50/80 px-4 py-2 flex items-center justify-between shadow-lg cursor-pointer hover:bg-slate-50 transition-colors z-30"
                    >
                      {/* Subtle top horizontal progress */}
                      <div className="absolute top-0 left-0 right-0 h-0.5 bg-indigo-50">
                        <div 
                          className="h-full bg-indigo-600 transition-all duration-300"
                          style={{ width: `${(simPosition / simCurrentSong.duration) * 100}%` }}
                        ></div>
                      </div>

                      <div className="flex items-center gap-2 min-w-0 flex-1">
                        <div className={`w-8 h-8 rounded-lg flex items-center justify-center text-white font-bold text-xs bg-gradient-to-br ${
                          simCurrentSong.color === "purple" ? "from-[#8E2DE2] to-[#4A00E0]" :
                          simCurrentSong.color === "blue" ? "from-[#00c6ff] to-[#0072ff]" :
                          "from-[#FF416C] to-[#FF4B2B]"
                        }`}>
                          {simIsPlaying ? "🔊" : "🎵"}
                        </div>
                        <div className="text-left min-w-0">
                          <h5 className="text-[11px] font-bold text-slate-800 truncate leading-none">{simCurrentSong.title}</h5>
                          <span className="text-[8px] text-slate-400 font-bold block">{simCurrentSong.artist}</span>
                        </div>
                      </div>
                      
                      <div className="flex items-center gap-1.5 flex-shrink-0" onClick={(e) => e.stopPropagation()}>
                        <button 
                          onClick={() => setSimIsPlaying(!simIsPlaying)}
                          className="w-8 h-8 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center cursor-pointer"
                        >
                          {simIsPlaying ? <Plus className="w-4 h-4 transform rotate-45 stroke-[2.5]" /> : <Play className="w-3.5 h-3.5 fill-indigo-600 text-indigo-600" />}
                        </button>
                        <button 
                          onClick={handleNextSong}
                          className="w-8 h-8 text-slate-500 rounded-full flex items-center justify-center cursor-pointer"
                        >
                          <ChevronRight className="w-4 h-4 stroke-[2.5]" />
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })()}

        {/* --- HAMBURGER MENU DRAWER OVERLAY --- */}
        {showDrawer && (
          <div className="absolute inset-0 bg-black/40 z-50 flex animate-fade-in">
            {/* Drawer Body */}
            <div className="w-3/4 h-full bg-[#FBF8FD] shadow-2xl rounded-r-3xl flex flex-col justify-between p-5 animate-slide-in-left relative">
              {/* Close Button inside Drawer */}
              <button 
                onClick={() => setShowDrawer(false)}
                className="absolute top-4 right-4 p-1 bg-indigo-50 hover:bg-indigo-100 rounded-full text-indigo-600 cursor-pointer"
              >
                <Plus className="w-4 h-4 transform rotate-45" />
              </button>

              <div className="space-y-6">
                {/* Header Profile Info Card */}
                <div className="bg-gradient-to-br from-indigo-600 to-indigo-500 rounded-2xl p-4 text-white shadow-md mt-6">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full border border-white/40 overflow-hidden">
                      <img 
                        src="https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=120" 
                        className="w-full h-full object-cover" 
                        alt="Avatar"
                      />
                    </div>
                    <div className="text-left">
                      <h4 className="text-xs font-bold">{parentName}</h4>
                      <p className="text-[9px] text-white/80">{parentEmail}</p>
                    </div>
                  </div>
                </div>

                {/* Quick Actions List */}
                <div className="space-y-2 text-left">
                  <span className="text-[9px] font-black tracking-wider text-slate-400 uppercase px-1 block mb-1">
                    Quick Actions
                  </span>
                  
                  <button 
                    onClick={() => { setShowDrawer(false); setActiveTab(4); }}
                    className="w-full flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-100 text-left text-xs font-bold text-slate-700 transition-colors cursor-pointer"
                  >
                    <Bot className="w-4 h-4 text-indigo-600" />
                    <span>AI Assistant</span>
                  </button>

                  <button 
                    onClick={() => { setShowDrawer(false); setActiveTab(2); }}
                    className="w-full flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-100 text-left text-xs font-bold text-slate-700 transition-colors cursor-pointer"
                  >
                    <Heart className="w-4 h-4 text-indigo-600 fill-indigo-50" />
                    <span>Predictive Health</span>
                  </button>

                  <button 
                    onClick={() => { setShowDrawer(false); setShowMusicPlayer(true); }}
                    className="w-full flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-100 text-left text-xs font-bold text-slate-700 transition-colors cursor-pointer"
                  >
                    <Music className="w-4 h-4 text-indigo-600" />
                    <span>Music Soother</span>
                  </button>

                  <button 
                    onClick={() => { setShowDrawer(false); setActiveTab(5); setProfileView("caregiver"); }}
                    className="w-full flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-100 text-left text-xs font-bold text-slate-700 transition-colors cursor-pointer"
                  >
                    <QrCode className="w-4 h-4 text-indigo-600" />
                    <span>Caregiver Access</span>
                  </button>

                  <button 
                    onClick={() => { setShowDrawer(false); setActiveTab(3); setShopView("catalog"); }}
                    className="w-full flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-100 text-left text-xs font-bold text-slate-700 transition-colors cursor-pointer"
                  >
                    <ShoppingBag className="w-4 h-4 text-indigo-600" />
                    <span>Nursery Shop</span>
                  </button>

                  <button 
                    onClick={() => { setShowDrawer(false); setActiveTab(1); }}
                    className="w-full flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-100 text-left text-xs font-bold text-slate-700 transition-colors cursor-pointer"
                  >
                    <Video className="w-4 h-4 text-indigo-600" />
                    <span>Live Camera Feed</span>
                  </button>
                </div>

                <div className="border-t border-slate-100 my-4"></div>

                {/* Information List */}
                <div className="space-y-2 text-left">
                  <span className="text-[9px] font-black tracking-wider text-slate-400 uppercase px-1 block mb-1">
                    Information
                  </span>
                  
                  <button 
                    onClick={() => { setShowDrawer(false); setShowAboutUsModal(true); }}
                    className="w-full flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-100 text-left text-xs font-bold text-slate-700 transition-colors cursor-pointer"
                  >
                    <Star className="w-4 h-4 text-indigo-600" />
                    <span>About Us</span>
                  </button>
                </div>
              </div>

              {/* Version Footer */}
              <div className="text-center text-[9px] text-slate-400 font-semibold mb-2">
                Maatriva Smart Baby Monitor v1.0.0
              </div>
            </div>

            {/* Click outside to close */}
            <div className="flex-1 h-full" onClick={() => setShowDrawer(false)}></div>
          </div>
        )}

        {/* --- ABOUT US MODAL OVERLAY --- */}
        {showAboutUsModal && (
          <div className="absolute inset-0 bg-black/50 z-55 flex items-center justify-center p-4 animate-fade-in">
            <div className="bg-white rounded-3xl p-5 w-11/12 max-w-sm shadow-2xl text-center space-y-4 relative">
              <button 
                onClick={() => setShowAboutUsModal(false)}
                className="absolute top-3 right-3 p-1.5 bg-indigo-50 hover:bg-indigo-100 rounded-full text-indigo-600 cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5 transform rotate-45" />
              </button>
              
              <div className="w-12 h-12 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center mx-auto shadow-xs">
                <Smile className="w-6 h-6" />
              </div>
              
              <h3 className="text-base font-black text-slate-800">About Maatriva</h3>
              <p className="text-[10px] text-slate-400 font-bold -mt-2">Version 1.0.0 (Beta)</p>
              
              <p className="text-[11.5px] text-slate-500 leading-relaxed text-left">
                Maatriva is a premium, AI-powered smart baby monitoring ecosystem designed by pediatric care specialists and IoT engineers. Our mission is to provide mothers and caregivers with clinical-grade, predictive health analytics and soothing automation to ensure every child sleeps safe and grows healthy.
              </p>
              
              <button 
                onClick={() => setShowAboutUsModal(false)}
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs py-2.5 rounded-xl transition-colors cursor-pointer"
              >
                Close
              </button>
            </div>
          </div>
        )}

      </div>
    </div>
  );
};
