import React, { useState } from "react";
import { PhoneSimulator } from "./components/PhoneSimulator";
import { CodeExplorer } from "./components/CodeExplorer";
import { AdminMusicLibrary } from "./components/AdminMusicLibrary";
import { BabyMetrics } from "./types";
import { 
  Sliders, 
  Baby, 
  Thermometer, 
  Heart, 
  Moon, 
  Sparkles, 
  Code, 
  Smartphone, 
  AlertCircle,
  Music
} from "lucide-react";

export default function App() {
  const [metrics, setMetrics] = useState<BabyMetrics>({
    motherName: "Sarah",
    babyStatus: "Sleeping",
    connectivity: "Connected",
    health: "Healthy",
    temperature: 24.0,
    heartRate: 115,
    sleepHours: 8.2,
    cryCount: 2,
    aiInsight: "Your baby had a peaceful sleep for 8 hours. This indicates the current nursery rhythm is optimal for healthy development.",
    isLoadingInsight: false
  });

  const [userRole, setUserRole] = useState<"admin" | "parent">("admin");
  const [activeWorkspaceTab, setActiveWorkspaceTab] = useState<"simulator" | "code" | "music">("simulator");

  const handleMetricsChange = (newMetrics: Partial<BabyMetrics>) => {
    setMetrics(prev => ({
      ...prev,
      ...newMetrics
    }));
  };

  // Triggers server-side call to Gemini API for live custom insights
  const generateRealAIInsight = async () => {
    handleMetricsChange({ isLoadingInsight: true });
    try {
      const response = await fetch("/api/gemini/insight", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          babyStatus: metrics.babyStatus,
          temperature: metrics.temperature,
          heartRate: metrics.heartRate,
          sleepHours: metrics.sleepHours,
          cryCount: metrics.cryCount
        })
      });

      const data = await response.json();
      if (data.insight) {
        handleMetricsChange({
          aiInsight: data.insight,
          isLoadingInsight: false
        });
      } else {
        throw new Error(data.error || "No insight returned");
      }
    } catch (err) {
      console.error(err);
      // Fallback in case of server/API key errors
      setTimeout(() => {
        const fallbackMsg = `Your baby is currently ${metrics.babyStatus.toLowerCase()}. The nursery temperature of ${metrics.temperature}°C and stable heart rate of ${metrics.heartRate} bpm are excellent indicators of sound health. Keep up the perfect sleep routine!`;
        handleMetricsChange({
          aiInsight: fallbackMsg,
          isLoadingInsight: false
        });
      }, 1000);
    }
  };

  // Scenario presets
  const applyPreset = (presetType: "napping" | "awake" | "crying") => {
    switch (presetType) {
      case "napping":
        setMetrics({
          motherName: "Sarah",
          babyStatus: "Sleeping",
          connectivity: "Connected",
          health: "Healthy",
          temperature: 23.8,
          heartRate: 110,
          sleepHours: 8.5,
          cryCount: 1,
          aiInsight: "Your baby had a peaceful sleep for 8 hours. This indicates the current nursery rhythm is optimal for healthy development.",
          isLoadingInsight: false
        });
        break;
      case "awake":
        setMetrics({
          motherName: "Sarah",
          babyStatus: "Awake",
          connectivity: "Connected",
          health: "Healthy",
          temperature: 24.2,
          heartRate: 124,
          sleepHours: 7.8,
          cryCount: 1,
          aiInsight: "Your baby is awake and relaxed. Biometric stats are fully optimal; we suggest a light feeding or gentle sensory interaction.",
          isLoadingInsight: false
        });
        break;
      case "crying":
        setMetrics({
          motherName: "Sarah",
          babyStatus: "Crying",
          connectivity: "Connected",
          health: "Restless",
          temperature: 25.4,
          heartRate: 148,
          sleepHours: 6.5,
          cryCount: 3,
          aiInsight: "Your baby is crying. A slight temperature spike of 25.4°C and heart rate of 148 bpm suggests active wakefulness; consider checking the nursery diaper or feeding cycle.",
          isLoadingInsight: false
        });
        break;
    }
  };

  return (
    <div className="min-h-screen bg-[#F2F5FF] text-gray-900 flex flex-col font-sans antialiased">
      
      {/* Top Navigation Bar */}
      <header className="flex-shrink-0 bg-white border-b border-indigo-50 sticky top-0 z-50 shadow-sm">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center text-white font-bold text-xl shadow-md">
              M
            </div>
            <div>
              <h1 className="text-lg font-bold tracking-tight text-indigo-900">Maatriva</h1>
              <p className="text-[10px] uppercase tracking-widest text-indigo-400 font-semibold">AI Smart Monitor</p>
            </div>
          </div>
          
          <div className="flex gap-2 bg-slate-100 p-1.5 rounded-2xl border border-slate-200/60">
            <button
              onClick={() => setActiveWorkspaceTab("simulator")}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer ${
                activeWorkspaceTab === "simulator"
                  ? "bg-white text-indigo-600 shadow-sm"
                  : "text-slate-500 hover:text-slate-900"
              }`}
            >
              <Smartphone className="w-3.5 h-3.5" />
              <span>Nursery Monitor</span>
            </button>

            {userRole === "admin" && (
              <button
                onClick={() => setActiveWorkspaceTab("music")}
                className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer ${
                  activeWorkspaceTab === "music"
                    ? "bg-indigo-600 text-white shadow-sm"
                    : "text-slate-500 hover:text-slate-900"
                }`}
              >
                <Music className="w-3.5 h-3.5" />
                <span>Admin Music Library</span>
              </button>
            )}

            <button
              onClick={() => setActiveWorkspaceTab("code")}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer ${
                activeWorkspaceTab === "code"
                  ? "bg-white text-indigo-600 shadow-sm"
                  : "text-slate-500 hover:text-slate-900"
              }`}
            >
              <Code className="w-3.5 h-3.5" />
              <span>Codebase</span>
            </button>
          </div>

          <div className="flex items-center gap-4">
            <div className="bg-slate-100 p-1 rounded-xl flex items-center gap-1 border border-slate-200">
              <button
                onClick={() => setUserRole("admin")}
                className={`px-2.5 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  userRole === "admin"
                    ? "bg-indigo-600 text-white shadow-xs"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Admin Mode
              </button>
              <button
                onClick={() => {
                  setUserRole("parent");
                  if (activeWorkspaceTab === "music") setActiveWorkspaceTab("simulator");
                }}
                className={`px-2.5 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  userRole === "parent"
                    ? "bg-emerald-600 text-white shadow-xs"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Parent Mode
              </button>
            </div>

            <div className="text-right">
              <p className="text-sm font-bold text-gray-900">
                {userRole === "admin" ? "Sarah Miller (Admin)" : "Sarah Miller (Parent)"}
              </p>
              <p className={`text-[10px] font-bold ${userRole === "admin" ? "text-indigo-600" : "text-emerald-600"}`}>
                {userRole === "admin" ? "System Admin Account" : "Primary Parent Account"}
              </p>
            </div>
            <div className={`w-10 h-10 rounded-full border-2 shadow-xs flex items-center justify-center font-bold text-sm select-none ${
              userRole === "admin" ? "bg-indigo-50 border-indigo-100 text-indigo-600" : "bg-emerald-50 border-emerald-100 text-emerald-600"
            }`}>
              SM
            </div>
          </div>
        </div>
      </header>

      {activeWorkspaceTab === "music" ? (
        <main className="flex-1 w-full max-w-7xl mx-auto py-4">
          <AdminMusicLibrary />
        </main>
      ) : (
        <>
          {/* Hero Welcome Banner */}
          <header className="bg-white border-b border-indigo-50/70 py-6 px-6">
            <div className="max-w-7xl mx-auto flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div>
                <h2 className="text-3xl font-bold text-gray-900 tracking-tight">Good morning, <span className="text-indigo-600">Sarah</span></h2>
                <p className="text-gray-500 mt-1">
                  Baby Theo is currently <span className="font-semibold text-indigo-600">{metrics.babyStatus.toLowerCase()}</span> soundly in the nursery.
                </p>
              </div>

              <button
                onClick={() => setActiveWorkspaceTab("music")}
                className="bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-bold text-xs px-5 py-3 rounded-2xl flex items-center gap-2 shadow-md shadow-indigo-100 transition-all cursor-pointer self-start sm:self-auto"
              >
                <Music className="w-4 h-4" />
                <span>🎵 Upload Songs & Manage Music (Admin)</span>
              </button>
            </div>
          </header>

          {/* Main Workspace Frame */}
          <main className="flex-1 max-w-7xl w-full mx-auto p-4 md:p-6 grid grid-cols-1 lg:grid-cols-12 gap-6 min-h-0 overflow-hidden">
        
        {/* Left Side: Controller Panel (4 Cols) */}
        <div className="lg:col-span-4 flex flex-col gap-5 h-full overflow-y-auto pr-1">
          
          {/* Welcome Info Card */}
          <div className="bg-white border border-indigo-50 rounded-[24px] p-5 shadow-sm relative overflow-hidden">
            <div className="absolute top-0 right-0 p-3 text-indigo-500/5">
              <Baby className="w-24 h-24 stroke-[1.5]" />
            </div>
            <h2 className="text-lg font-bold text-indigo-900">Welcome to Maatriva</h2>
            <p className="text-xs text-slate-500 mt-1.5 leading-relaxed">
              This interactive playground lets you preview your production-grade Flutter codebase's visual look, responsive grid spacing, and custom Material 3 cards.
            </p>
          </div>

          {/* Scenario presets */}
          <div className="bg-white border border-indigo-50 rounded-[24px] p-5 shadow-sm">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3 flex items-center gap-2">
              <Sparkles className="w-3.5 h-3.5 text-indigo-500" /> Choose Baby Scenario Presets
            </h3>
            <div className="grid grid-cols-3 gap-2">
              <button 
                onClick={() => applyPreset("napping")}
                className={`py-2 px-3 text-xs rounded-xl font-semibold border transition-all ${
                  metrics.babyStatus === "Sleeping" 
                    ? "bg-indigo-600 border-indigo-500 text-white shadow-md" 
                    : "bg-indigo-50/50 border-indigo-100 text-indigo-700 hover:bg-indigo-100/50"
                }`}
              >
                💤 Sleeping
              </button>
              <button 
                onClick={() => applyPreset("awake")}
                className={`py-2 px-3 text-xs rounded-xl font-semibold border transition-all ${
                  metrics.babyStatus === "Awake" 
                    ? "bg-indigo-600 border-indigo-500 text-white shadow-md" 
                    : "bg-indigo-50/50 border-indigo-100 text-indigo-700 hover:bg-indigo-100/50"
                }`}
              >
                🧸 Awake
              </button>
              <button 
                onClick={() => applyPreset("crying")}
                className={`py-2 px-3 text-xs rounded-xl font-semibold border transition-all ${
                  metrics.babyStatus === "Crying" 
                    ? "bg-indigo-600 border-indigo-500 text-white shadow-md" 
                    : "bg-indigo-50/50 border-indigo-100 text-indigo-700 hover:bg-indigo-100/50 animate-pulse"
                }`}
              >
                😭 Crying
              </button>
            </div>
          </div>

          {/* Slider Controllers */}
          <div className="bg-white border border-indigo-50 rounded-[24px] p-5 shadow-sm flex-1">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-4 flex items-center gap-2">
              <Sliders className="w-3.5 h-3.5 text-indigo-500" /> Fine-Tune Biometrics
            </h3>

            <div className="space-y-4">
              {/* Temperature slider */}
              <div>
                <div className="flex justify-between items-center mb-1 text-xs text-slate-600">
                  <span className="flex items-center gap-1 font-medium">
                    <Thermometer className="w-3.5 h-3.5 text-blue-500" /> Temperature
                  </span>
                  <span className="font-mono text-indigo-600 font-bold">{metrics.temperature.toFixed(1)}°C</span>
                </div>
                <input 
                  type="range" 
                  min="20" 
                  max="30" 
                  step="0.1"
                  value={metrics.temperature} 
                  onChange={(e) => handleMetricsChange({ temperature: parseFloat(e.target.value) })}
                  className="w-full accent-indigo-600 h-1.5 bg-indigo-50 rounded-lg cursor-pointer"
                />
              </div>

              {/* Heart rate slider */}
              <div>
                <div className="flex justify-between items-center mb-1 text-xs text-slate-600">
                  <span className="flex items-center gap-1 font-medium">
                    <Heart className="w-3.5 h-3.5 text-red-500" /> Heart Rate
                  </span>
                  <span className="font-mono text-indigo-600 font-bold">{metrics.heartRate} bpm</span>
                </div>
                <input 
                  type="range" 
                  min="80" 
                  max="160" 
                  value={metrics.heartRate} 
                  onChange={(e) => handleMetricsChange({ heartRate: parseInt(e.target.value) })}
                  className="w-full accent-indigo-600 h-1.5 bg-indigo-50 rounded-lg cursor-pointer"
                />
              </div>

              {/* Sleep Hours slider */}
              <div>
                <div className="flex justify-between items-center mb-1 text-xs text-slate-600">
                  <span className="flex items-center gap-1 font-medium">
                    <Moon className="w-3.5 h-3.5 text-purple-500" /> Cumulative Sleep
                  </span>
                  <span className="font-mono text-indigo-600 font-bold">{metrics.sleepHours.toFixed(1)} hrs</span>
                </div>
                <input 
                  type="range" 
                  min="0" 
                  max="12" 
                  step="0.1"
                  value={metrics.sleepHours} 
                  onChange={(e) => handleMetricsChange({ sleepHours: parseFloat(e.target.value) })}
                  className="w-full accent-indigo-600 h-1.5 bg-indigo-50 rounded-lg cursor-pointer"
                />
              </div>

              {/* Cry Count slider */}
              <div>
                <div className="flex justify-between items-center mb-1 text-xs text-slate-600">
                  <span className="flex items-center gap-1 font-medium">
                    😭 Today's Cry Count
                  </span>
                  <span className="font-mono text-indigo-600 font-bold">{metrics.cryCount} cries</span>
                </div>
                <input 
                  type="range" 
                  min="0" 
                  max="10" 
                  value={metrics.cryCount} 
                  onChange={(e) => handleMetricsChange({ cryCount: parseInt(e.target.value) })}
                  className="w-full accent-indigo-600 h-1.5 bg-indigo-50 rounded-lg cursor-pointer"
                />
              </div>
            </div>

            {/* Smart Consultant triggers server-side Gemini call */}
            <div className="mt-6 pt-5 border-t border-indigo-50">
              <button
                onClick={generateRealAIInsight}
                disabled={metrics.isLoadingInsight}
                className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white font-bold text-sm py-3 px-4 rounded-xl flex items-center justify-center gap-2 shadow-md transition-all cursor-pointer"
              >
                <Sparkles className={`w-4 h-4 ${metrics.isLoadingInsight ? "animate-spin" : ""}`} />
                <span>Consult Gemini Pediatrician</span>
              </button>
              <p className="text-[10px] text-slate-400 text-center mt-2">
                Creates a live, server-side pediatric inference utilizing gemini-3.5-flash.
              </p>
            </div>
          </div>

          {/* Prompt warning about folders */}
          <div className="bg-indigo-50/50 border border-indigo-100 p-4 rounded-xl flex gap-3 text-indigo-900 select-none">
            <AlertCircle className="w-5 h-5 text-indigo-500 flex-shrink-0 mt-0.5" />
            <div className="text-[11px] leading-relaxed text-indigo-950 font-medium">
              All Flutter widget files are neatly organized inside <code className="text-indigo-600 bg-indigo-100/50 px-1 rounded">lib/features/dashboard/presentation/</code> in the workspace. Toggle the right-hand tabs to browse the exact source code!
            </div>
          </div>

        </div>

        {/* Center/Right Toggle tabs on small screen, side-by-side on large screens */}
        <div className="lg:col-span-8 flex flex-col lg:flex-row gap-6 min-h-0 overflow-hidden">
          
          {/* Mobile responsive toggle */}
          <div className="lg:hidden flex bg-white border border-indigo-50 p-1 rounded-xl shadow-sm">
            <button
              onClick={() => setActiveWorkspaceTab("simulator")}
              className={`flex-1 py-2 px-4 rounded-lg text-xs font-bold flex items-center justify-center gap-2 ${
                activeWorkspaceTab === "simulator" ? "bg-indigo-600 text-white" : "text-slate-500 hover:text-slate-900"
              }`}
            >
              <Smartphone className="w-4 h-4" /> Live Mobile Simulator
            </button>
            <button
              onClick={() => setActiveWorkspaceTab("code")}
              className={`flex-1 py-2 px-4 rounded-lg text-xs font-bold flex items-center justify-center gap-2 ${
                activeWorkspaceTab === "code" ? "bg-indigo-600 text-white" : "text-slate-500 hover:text-slate-900"
              }`}
            >
              <Code className="w-4 h-4" /> Flutter Code Inspector
            </button>
          </div>

          {/* Left panel of center grid: Simulator Frame (rendered always on large screens or if active on small screen) */}
          <div className={`flex-shrink-0 flex items-center justify-center ${
            activeWorkspaceTab === "simulator" ? "flex" : "hidden lg:flex"
          } lg:w-[395px]`}>
            <PhoneSimulator 
              metrics={metrics}
              onMetricsChange={handleMetricsChange}
              onGenerateAIInsight={generateRealAIInsight}
              onOpenAdminMusic={() => setActiveWorkspaceTab("music")}
            />
          </div>

          {/* Right panel of center grid: Code Explorer (rendered always on large screens or if active on small screen) */}
          <div className={`flex-1 min-w-0 ${
            activeWorkspaceTab === "code" ? "flex flex-col" : "hidden lg:flex lg:flex-col"
          } h-full`}>
            <CodeExplorer />
          </div>

        </div>

      </main>
    </>
  )}
</div>
  );
}
