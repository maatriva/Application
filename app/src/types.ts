export interface BabyMetrics {
  motherName: string;
  babyStatus: "Sleeping" | "Awake" | "Crying";
  connectivity: "Connected" | "Offline";
  health: "Healthy" | "Unstable" | "Restless";
  temperature: number;
  heartRate: number;
  sleepHours: number;
  cryCount: number;
  aiInsight: string;
  isLoadingInsight: boolean;
}

export interface FlutterFile {
  name: string;
  path: string;
  content: string;
  language: string;
  description: string;
}
