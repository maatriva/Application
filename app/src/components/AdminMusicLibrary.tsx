import React, { useState, useEffect, useRef } from "react";
import {
  Music,
  Upload,
  FolderArchive,
  FolderTree,
  Search,
  Filter,
  CheckCircle2,
  AlertCircle,
  Play,
  Pause,
  Volume2,
  VolumeX,
  Trash2,
  Tag,
  Globe,
  Star,
  CheckSquare,
  Square,
  FileSpreadsheet,
  RefreshCw,
  Clock,
  HardDrive,
  Layers,
  Sparkles,
  SlidersHorizontal,
  Plus,
  X,
  Check,
  ChevronRight,
  BarChart3,
  Edit3
} from "lucide-react";

export interface Track {
  id: string;
  title: string;
  category: string;
  language: string;
  duration: number; // in seconds
  fileSize: number; // in bytes
  audioFormat: string;
  bitrate?: number;
  artist: string;
  album?: string;
  storageUrl: string;
  fileHash?: string;
  thumbnail?: string;
  uploadedAt: string;
  isPremium: boolean;
  isActive: boolean;
  playCount: number;
  favouriteCount: number;
  targetAgeGroup?: string;
  tags: string[];
}

export interface Stats {
  totalSongs: number;
  totalStorageBytes: number;
  totalCategoriesCount: number;
  totalPlays: number;
  categoryBreakdown: Record<string, number>;
  languageBreakdown: Record<string, number>;
}

export function AdminMusicLibrary() {
  const [tracks, setTracks] = useState<Track[]>([]);
  const [stats, setStats] = useState<Stats>({
    totalSongs: 0,
    totalStorageBytes: 0,
    totalCategoriesCount: 0,
    totalPlays: 0,
    categoryBreakdown: {},
    languageBreakdown: {},
  });
  const [loading, setLoading] = useState(true);

  // Filters & Sorting
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [selectedLanguage, setSelectedLanguage] = useState("All");
  const [statusFilter, setStatusFilter] = useState("all");
  const [sortBy, setSortBy] = useState<"newest" | "title" | "duration" | "plays">("newest");
  const [viewMode, setViewMode] = useState<"grid" | "table">("table");

  // Selection for Batch Operations
  const [selectedTrackIds, setSelectedTrackIds] = useState<string[]>([]);
  const [batchActionModal, setBatchActionModal] = useState<"category" | "language" | null>(null);
  const [batchCategoryValue, setBatchCategoryValue] = useState("Lullabies");
  const [batchLanguageValue, setBatchLanguageValue] = useState("English");

  // Audio Preview Player
  const [currentPlayingTrack, setCurrentPlayingTrack] = useState<Track | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(0.8);
  const [isMuted, setIsMuted] = useState(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Upload Modal & Progress
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [uploadCategory, setUploadCategory] = useState("Auto-Detect");
  const [uploadLanguage, setUploadLanguage] = useState("English");
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [currentUploadingFile, setCurrentUploadingFile] = useState("");
  const [successCount, setSuccessCount] = useState(0);
  const [failedCount, setFailedCount] = useState(0);
  const [failedList, setFailedList] = useState<Array<{ name: string; error: string }>>([]);
  const [duplicateModal, setDuplicateModal] = useState<Array<{ fileName: string; existingTitle: string }>>([]);

  // Single Track Edit Modal
  const [editingTrack, setEditingTrack] = useState<Track | null>(null);

  const categoriesList = [
    "All",
    "Lullabies",
    "White Noise",
    "Nature Sounds",
    "Womb Sounds",
    "Instrumental",
    "Nursery Rhymes",
    "Regional",
    "Parent Recordings"
  ];

  const languagesList = ["All", "English", "Hindi", "Spanish", "French", "Universal"];

  // Load catalog on mount & filter change
  useEffect(() => {
    fetchCatalog();
    fetchStats();
  }, [selectedCategory, selectedLanguage, statusFilter, sortBy]);

  const fetchCatalog = async () => {
    setLoading(true);
    try {
      const queryParams = new URLSearchParams({
        category: selectedCategory,
        language: selectedLanguage,
        isActive: statusFilter,
        sortBy: sortBy,
        search: searchTerm,
      });

      const res = await fetch(`/api/music?${queryParams.toString()}`);
      const json = await res.json();
      if (json.success && json.data) {
        setTracks(json.data);
      }
    } catch (err) {
      console.error("Error fetching music catalog:", err);
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      const res = await fetch("/api/music/stats");
      const json = await res.json();
      if (json.success && json.data) {
        setStats(json.data);
      }
    } catch (err) {
      console.error("Error fetching stats:", err);
    }
  };

  // Audio Control Handlers
  const handlePlayPreview = (track: Track) => {
    if (currentPlayingTrack?.id === track.id) {
      if (isPlaying) {
        audioRef.current?.pause();
        setIsPlaying(false);
      } else {
        audioRef.current?.play();
        setIsPlaying(true);
      }
    } else {
      setCurrentPlayingTrack(track);
      setIsPlaying(true);
      if (audioRef.current) {
        audioRef.current.src = track.storageUrl;
        audioRef.current.play().catch(() => {
          // If local static audio doesn't exist, use synthetic audio preview
          audioRef.current!.src = "https://actions.google.com/sounds/v1/ambiences/rain_heavy_loud.ogg";
          audioRef.current!.play();
        });
      }
    }
  };

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const time = parseFloat(e.target.value);
    setCurrentTime(time);
    if (audioRef.current) {
      audioRef.current.currentTime = time;
    }
  };

  const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = parseFloat(e.target.value);
    setVolume(val);
    if (audioRef.current) {
      audioRef.current.volume = val;
    }
    if (val === 0) setIsMuted(true);
    else setIsMuted(false);
  };

  const toggleMute = () => {
    if (audioRef.current) {
      audioRef.current.muted = !isMuted;
      setIsMuted(!isMuted);
    }
  };

  // File Drop / Select Handler for Bulk Upload
  const handleFileDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      const filesArray = Array.from(e.dataTransfer.files) as File[];
      setSelectedFiles(filesArray);
      checkDuplicatesBeforeUpload(filesArray);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      const filesArray = Array.from(e.target.files) as File[];
      setSelectedFiles(filesArray);
      checkDuplicatesBeforeUpload(filesArray);
    }
  };

  const checkDuplicatesBeforeUpload = async (files: File[]) => {
    try {
      const filePayloads = files.map(f => ({ fileName: f.name, fileSize: f.size }));
      const res = await fetch("/api/music/check-duplicates", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ files: filePayloads })
      });
      const json = await res.json();
      if (json.success && json.data?.duplicates?.length > 0) {
        setDuplicateModal(json.data.duplicates);
      }
    } catch (err) {
      console.error("Duplicate check error:", err);
    }
  };

  // Execute Bulk Upload Operation
  const triggerBulkUpload = async () => {
    if (selectedFiles.length === 0) return;

    setIsUploading(true);
    setUploadProgress(0);
    setSuccessCount(0);
    setFailedCount(0);
    setFailedList([]);

    // Convert files to base64 buffer objects for client API transmission
    const filesData: Array<{ name: string; size: number; type: string; path: string; base64Data: string }> = [];

    for (let i = 0; i < selectedFiles.length; i++) {
      const file = selectedFiles[i];
      setCurrentUploadingFile(file.name);
      setUploadProgress(Math.round(((i + 1) / selectedFiles.length) * 40));

      const base64 = await new Promise<string>((resolve) => {
        const reader = new FileReader();
        reader.onload = () => {
          const resStr = reader.result as string;
          const base64Content = resStr.split(",")[1] || "";
          resolve(base64Content);
        };
        reader.readAsDataURL(file);
      });

      const relPath = (file as any).webkitRelativePath || file.name;
      filesData.push({
        name: file.name,
        size: file.size,
        type: file.type,
        path: relPath,
        base64Data: base64
      });
    }

    setUploadProgress(60);
    setCurrentUploadingFile("Processing metadata and storing tracks on server...");

    try {
      const res = await fetch("/api/music/upload-bulk", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          category: uploadCategory,
          language: uploadLanguage,
          files: filesData
        })
      });

      const json = await res.json();
      setUploadProgress(100);

      if (json.success && json.data) {
        const job = json.data;
        setSuccessCount(job.successCount || filesData.length);
        setFailedCount(job.failedCount || 0);

        if (job.details) {
          const fails = job.details
            .filter((d: any) => d.status === "failed")
            .map((d: any) => ({ name: d.fileName, error: d.error || "Upload failed" }));
          setFailedList(fails);
        }
      } else {
        setFailedCount(selectedFiles.length);
      }
    } catch (err: any) {
      console.error("Bulk upload request failed:", err);
      setFailedCount(selectedFiles.length);
      setFailedList([{ name: "Batch Job", error: err.message || "Network request failed" }]);
    } finally {
      setIsUploading(false);
      fetchCatalog();
      fetchStats();
    }
  };

  // Batch Operations (Delete, Change Category, Change Language, Toggle Active, Toggle Premium, Export CSV)
  const toggleSelectAll = () => {
    if (selectedTrackIds.length === tracks.length) {
      setSelectedTrackIds([]);
    } else {
      setSelectedTrackIds(tracks.map(t => t.id));
    }
  };

  const toggleSelectTrack = (id: string) => {
    if (selectedTrackIds.includes(id)) {
      setSelectedTrackIds(prev => prev.filter(item => item !== id));
    } else {
      setSelectedTrackIds(prev => [...prev, id]);
    }
  };

  const handleBatchOperation = async (action: string, extraData?: any) => {
    if (selectedTrackIds.length === 0) return;

    try {
      const res = await fetch("/api/music/batch", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action,
          trackIds: selectedTrackIds,
          data: extraData
        })
      });

      if (action === "export_metadata") {
        const blob = await res.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `maatriva_music_metadata_${Date.now()}.csv`;
        a.click();
        return;
      }

      const json = await res.json();
      if (json.success) {
        setSelectedTrackIds([]);
        setBatchActionModal(null);
        fetchCatalog();
        fetchStats();
      }
    } catch (err) {
      console.error("Batch action failed:", err);
    }
  };

  // Single Track Save
  const handleSaveTrackEdit = async () => {
    if (!editingTrack) return;
    try {
      const res = await fetch(`/api/music/${editingTrack.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(editingTrack)
      });
      const json = await res.json();
      if (json.success) {
        setEditingTrack(null);
        fetchCatalog();
      }
    } catch (err) {
      console.error("Save track edit error:", err);
    }
  };

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs < 10 ? "0" : ""}${secs}`;
  };

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return "0 MB";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  };

  return (
    <div className="min-h-screen bg-[#F6F8FC] text-slate-800 p-4 md:p-8 font-sans antialiased">
      
      {/* Hidden Audio Player Element */}
      <audio
        ref={audioRef}
        onTimeUpdate={() => setCurrentTime(audioRef.current?.currentTime || 0)}
        onLoadedMetadata={() => setDuration(audioRef.current?.duration || 0)}
        onEnded={() => setIsPlaying(false)}
      />

      {/* Header Banner */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 mb-8 bg-white p-6 rounded-3xl border border-indigo-50 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-tr from-indigo-600 to-purple-600 rounded-2xl flex items-center justify-center text-white shadow-lg shadow-indigo-200">
            <Music className="w-7 h-7 stroke-[2]" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Admin Music Library</h1>
              <span className="px-2.5 py-0.5 text-[10px] uppercase font-bold tracking-wider bg-indigo-50 text-indigo-700 rounded-full border border-indigo-100">
                Bulk Audio v2.4
              </span>
            </div>
            <p className="text-xs text-slate-500 mt-1">
              Upload, auto-categorize, extract metadata, and manage hundreds of baby sleep lullabies & white noise tracks.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="hidden sm:flex items-center gap-2.5 px-3.5 py-2 bg-indigo-50/80 border border-indigo-100 rounded-2xl">
            <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></div>
            <div>
              <p className="text-[11px] font-bold text-indigo-950">admin@maatriva.com</p>
              <p className="text-[9px] text-indigo-600 font-semibold">Global Admin Mode (All Users)</p>
            </div>
          </div>

          <button
            onClick={() => {
              setShowUploadModal(true);
              setSelectedFiles([]);
              setUploadProgress(0);
              setSuccessCount(0);
              setFailedCount(0);
            }}
            className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm px-5 py-3 rounded-xl flex items-center gap-2 shadow-md shadow-indigo-100 transition-all cursor-pointer"
          >
            <Upload className="w-4 h-4" />
            <span>Bulk Upload Songs</span>
          </button>
        </div>
      </div>

      {/* System Metrics Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mb-8">
        <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
            <Music className="w-6 h-6" />
          </div>
          <div>
            <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">Total Audio Songs</p>
            <h3 className="text-xl font-black text-slate-900 mt-0.5">{stats.totalSongs}</h3>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <HardDrive className="w-6 h-6" />
          </div>
          <div>
            <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">Cloud Storage Used</p>
            <h3 className="text-xl font-black text-slate-900 mt-0.5">{formatBytes(stats.totalStorageBytes)}</h3>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center">
            <FolderTree className="w-6 h-6" />
          </div>
          <div>
            <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">Active Categories</p>
            <h3 className="text-xl font-black text-slate-900 mt-0.5">{stats.totalCategoriesCount} Categories</h3>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
            <BarChart3 className="w-6 h-6" />
          </div>
          <div>
            <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">Total Nursery Stream Plays</p>
            <h3 className="text-xl font-black text-slate-900 mt-0.5">{stats.totalPlays.toLocaleString()}</h3>
          </div>
        </div>
      </div>

      {/* Main Catalog Workspace Card */}
      <div className="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden mb-24">
        
        {/* Filters & Search Toolbar */}
        <div className="p-6 border-b border-slate-100 flex flex-col lg:flex-row lg:items-center justify-between gap-4 bg-slate-50/40">
          
          {/* Search Box */}
          <div className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search by song title, artist, or keyword..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && fetchCatalog()}
              className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:border-indigo-500 shadow-sm"
            />
          </div>

          {/* Category, Language & Sort Selectors */}
          <div className="flex flex-wrap items-center gap-3">
            
            {/* Category Dropdown */}
            <div className="flex items-center gap-1.5 bg-white border border-slate-200 px-3 py-2 rounded-xl shadow-sm">
              <FolderTree className="w-3.5 h-3.5 text-indigo-500" />
              <select
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value)}
                className="bg-transparent text-xs font-semibold text-slate-700 outline-none cursor-pointer"
              >
                {categoriesList.map((cat) => (
                  <option key={cat} value={cat}>
                    Category: {cat}
                  </option>
                ))}
              </select>
            </div>

            {/* Language Dropdown */}
            <div className="flex items-center gap-1.5 bg-white border border-slate-200 px-3 py-2 rounded-xl shadow-sm">
              <Globe className="w-3.5 h-3.5 text-blue-500" />
              <select
                value={selectedLanguage}
                onChange={(e) => setSelectedLanguage(e.target.value)}
                className="bg-transparent text-xs font-semibold text-slate-700 outline-none cursor-pointer"
              >
                {languagesList.map((lang) => (
                  <option key={lang} value={lang}>
                    Lang: {lang}
                  </option>
                ))}
              </select>
            </div>

            {/* Sort Selector */}
            <div className="flex items-center gap-1.5 bg-white border border-slate-200 px-3 py-2 rounded-xl shadow-sm">
              <SlidersHorizontal className="w-3.5 h-3.5 text-slate-400" />
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as any)}
                className="bg-transparent text-xs font-semibold text-slate-700 outline-none cursor-pointer"
              >
                <option value="newest">Sort: Newest First</option>
                <option value="title">Sort: Alphabetical</option>
                <option value="duration">Sort: Duration</option>
                <option value="plays">Sort: Most Played</option>
              </select>
            </div>

            {/* View Mode Toggle */}
            <div className="flex items-center bg-slate-100 p-1 rounded-xl">
              <button
                onClick={() => setViewMode("table")}
                className={`p-1.5 rounded-lg text-xs transition-all ${
                  viewMode === "table" ? "bg-white text-indigo-600 shadow-sm font-bold" : "text-slate-500 hover:text-slate-800"
                }`}
              >
                Table View
              </button>
              <button
                onClick={() => setViewMode("grid")}
                className={`p-1.5 rounded-lg text-xs transition-all ${
                  viewMode === "grid" ? "bg-white text-indigo-600 shadow-sm font-bold" : "text-slate-500 hover:text-slate-800"
                }`}
              >
                Grid Cards
              </button>
            </div>

          </div>
        </div>

        {/* Batch Operations Floating Action Toolbar */}
        {selectedTrackIds.length > 0 && (
          <div className="bg-indigo-900 text-white px-6 py-3.5 flex flex-wrap items-center justify-between gap-4 animate-fadeIn">
            <div className="flex items-center gap-3">
              <span className="bg-indigo-700 text-indigo-100 text-xs font-extrabold px-3 py-1 rounded-full">
                {selectedTrackIds.length} Selected
              </span>
              <span className="text-xs text-indigo-200 font-medium">Batch Operations:</span>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <button
                onClick={() => setBatchActionModal("category")}
                className="bg-indigo-800 hover:bg-indigo-700 text-xs font-semibold px-3 py-1.5 rounded-lg flex items-center gap-1.5 transition-all"
              >
                <Tag className="w-3.5 h-3.5" /> Change Category
              </button>
              <button
                onClick={() => setBatchActionModal("language")}
                className="bg-indigo-800 hover:bg-indigo-700 text-xs font-semibold px-3 py-1.5 rounded-lg flex items-center gap-1.5 transition-all"
              >
                <Globe className="w-3.5 h-3.5" /> Change Language
              </button>
              <button
                onClick={() => handleBatchOperation("toggle_active", { isActive: true })}
                className="bg-indigo-800 hover:bg-indigo-700 text-xs font-semibold px-3 py-1.5 rounded-lg flex items-center gap-1.5 transition-all"
              >
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" /> Enable Selected
              </button>
              <button
                onClick={() => handleBatchOperation("toggle_premium", { isPremium: true })}
                className="bg-indigo-800 hover:bg-indigo-700 text-xs font-semibold px-3 py-1.5 rounded-lg flex items-center gap-1.5 transition-all"
              >
                <Star className="w-3.5 h-3.5 text-amber-400" /> Mark Premium
              </button>
              <button
                onClick={() => handleBatchOperation("export_metadata")}
                className="bg-emerald-600 hover:bg-emerald-700 text-xs font-semibold px-3 py-1.5 rounded-lg flex items-center gap-1.5 transition-all"
              >
                <FileSpreadsheet className="w-3.5 h-3.5" /> Export Metadata CSV
              </button>
              <button
                onClick={() => handleBatchOperation("delete")}
                className="bg-rose-600 hover:bg-rose-700 text-xs font-semibold px-3 py-1.5 rounded-lg flex items-center gap-1.5 transition-all"
              >
                <Trash2 className="w-3.5 h-3.5" /> Delete Selected
              </button>
            </div>
          </div>
        )}

        {/* Music Catalog Content Area */}
        {loading ? (
          <div className="py-20 text-center text-slate-400">
            <RefreshCw className="w-8 h-8 animate-spin mx-auto text-indigo-500 mb-3" />
            <p className="text-xs font-medium">Loading Music Catalog...</p>
          </div>
        ) : tracks.length === 0 ? (
          <div className="py-20 text-center text-slate-400">
            <Music className="w-12 h-12 mx-auto text-slate-300 mb-3 stroke-[1.5]" />
            <h4 className="text-sm font-bold text-slate-700">No Music Tracks Found</h4>
            <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
              No audio tracks match your selected filters. Click "Bulk Upload Songs" to add new lullabies.
            </p>
          </div>
        ) : viewMode === "table" ? (
          /* Table View */
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50/80 text-[11px] font-bold text-slate-400 uppercase tracking-wider border-b border-slate-100">
                  <th className="py-3.5 px-4 w-10">
                    <button onClick={toggleSelectAll} className="text-slate-400 hover:text-indigo-600">
                      {selectedTrackIds.length === tracks.length ? (
                        <CheckSquare className="w-4 h-4 text-indigo-600" />
                      ) : (
                        <Square className="w-4 h-4" />
                      )}
                    </button>
                  </th>
                  <th className="py-3.5 px-4">Preview</th>
                  <th className="py-3.5 px-4">Song Name & Details</th>
                  <th className="py-3.5 px-4">Category</th>
                  <th className="py-3.5 px-4">Language</th>
                  <th className="py-3.5 px-4">Duration</th>
                  <th className="py-3.5 px-4">Format / Size</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs">
                {tracks.map((track) => {
                  const isSelected = selectedTrackIds.includes(track.id);
                  const isCurrent = currentPlayingTrack?.id === track.id && isPlaying;

                  return (
                    <tr
                      key={track.id}
                      className={`hover:bg-indigo-50/30 transition-colors ${
                        isSelected ? "bg-indigo-50/40" : ""
                      }`}
                    >
                      <td className="py-3 px-4">
                        <button
                          onClick={() => toggleSelectTrack(track.id)}
                          className="text-slate-400 hover:text-indigo-600"
                        >
                          {isSelected ? (
                            <CheckSquare className="w-4 h-4 text-indigo-600" />
                          ) : (
                            <Square className="w-4 h-4" />
                          )}
                        </button>
                      </td>

                      <td className="py-3 px-4">
                        <button
                          onClick={() => handlePlayPreview(track)}
                          className={`w-9 h-9 rounded-xl flex items-center justify-center transition-all ${
                            isCurrent
                              ? "bg-indigo-600 text-white shadow-md shadow-indigo-200"
                              : "bg-slate-100 hover:bg-indigo-100 text-slate-700 hover:text-indigo-600"
                          }`}
                        >
                          {isCurrent ? <Pause className="w-4 h-4 fill-white" /> : <Play className="w-4 h-4 fill-current ml-0.5" />}
                        </button>
                      </td>

                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3">
                          <img
                            src={track.thumbnail || "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=300&q=80"}
                            alt={track.title}
                            className="w-10 h-10 rounded-lg object-cover border border-slate-100 flex-shrink-0"
                          />
                          <div>
                            <div className="flex items-center gap-1.5">
                              <span className="font-bold text-slate-900">{track.title}</span>
                              {track.isPremium && (
                                <span className="bg-amber-100 text-amber-800 text-[9px] font-extrabold px-1.5 py-0.5 rounded">
                                  PREMIUM
                                </span>
                              )}
                            </div>
                            <p className="text-[10px] text-slate-400 mt-0.5">
                              {track.artist} • {track.playCount} plays
                            </p>
                          </div>
                        </div>
                      </td>

                      <td className="py-3 px-4">
                        <span className="px-2.5 py-1 rounded-full text-[10px] font-semibold bg-indigo-50 text-indigo-700 border border-indigo-100">
                          {track.category}
                        </span>
                      </td>

                      <td className="py-3 px-4 font-medium text-slate-600">{track.language}</td>

                      <td className="py-3 px-4 font-mono font-medium text-slate-600">
                        {formatDuration(track.duration)}
                      </td>

                      <td className="py-3 px-4">
                        <span className="uppercase text-[10px] font-bold text-slate-500">
                          {track.audioFormat}
                        </span>
                        <span className="text-[10px] text-slate-400 block">{formatBytes(track.fileSize)}</span>
                      </td>

                      <td className="py-3 px-4">
                        <span
                          className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                            track.isActive
                              ? "bg-emerald-50 text-emerald-700 border border-emerald-100"
                              : "bg-slate-100 text-slate-500"
                          }`}
                        >
                          <span
                            className={`w-1.5 h-1.5 rounded-full ${
                              track.isActive ? "bg-emerald-500" : "bg-slate-400"
                            }`}
                          ></span>
                          {track.isActive ? "Active" : "Disabled"}
                        </span>
                      </td>

                      <td className="py-3 px-4 text-right">
                        <div className="flex items-center justify-end gap-1">
                          <button
                            onClick={() => setEditingTrack(track)}
                            className="p-1.5 text-slate-400 hover:text-indigo-600 rounded-lg hover:bg-slate-100"
                            title="Edit Metadata"
                          >
                            <Edit3 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => {
                              setSelectedTrackIds([track.id]);
                              handleBatchOperation("delete");
                            }}
                            className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-slate-100"
                            title="Delete Song"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        ) : (
          /* Grid Cards View */
          <div className="p-6 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-5">
            {tracks.map((track) => {
              const isSelected = selectedTrackIds.includes(track.id);
              const isCurrent = currentPlayingTrack?.id === track.id && isPlaying;

              return (
                <div
                  key={track.id}
                  className={`bg-white rounded-2xl border p-4 transition-all relative flex flex-col justify-between ${
                    isSelected ? "border-indigo-500 ring-2 ring-indigo-100" : "border-slate-100 hover:border-slate-200"
                  }`}
                >
                  <div>
                    <div className="relative aspect-video rounded-xl overflow-hidden mb-3 group">
                      <img
                        src={track.thumbnail || "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=300&q=80"}
                        alt={track.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-all duration-300"
                      />
                      <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                        <button
                          onClick={() => handlePlayPreview(track)}
                          className="w-11 h-11 rounded-full bg-white text-indigo-600 flex items-center justify-center shadow-lg transform hover:scale-105 transition-all"
                        >
                          {isCurrent ? <Pause className="w-5 h-5 fill-current" /> : <Play className="w-5 h-5 fill-current ml-0.5" />}
                        </button>
                      </div>
                      <span className="absolute bottom-2 right-2 bg-black/70 text-white text-[10px] font-mono px-2 py-0.5 rounded-md backdrop-blur-sm">
                        {formatDuration(track.duration)}
                      </span>
                    </div>

                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <h4 className="font-bold text-slate-900 text-xs line-clamp-1">{track.title}</h4>
                        <p className="text-[10px] text-slate-400 mt-0.5">{track.artist}</p>
                      </div>
                      <button
                        onClick={() => toggleSelectTrack(track.id)}
                        className="text-slate-400 hover:text-indigo-600 flex-shrink-0"
                      >
                        {isSelected ? <CheckSquare className="w-4 h-4 text-indigo-600" /> : <Square className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>

                  <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-[10px]">
                    <span className="px-2 py-0.5 rounded-full bg-indigo-50 text-indigo-700 font-semibold">
                      {track.category}
                    </span>
                    <span className="text-slate-400 uppercase font-bold">{track.audioFormat}</span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Persistent Audio Preview Bar (Bottom Fixed) */}
      {currentPlayingTrack && (
        <div className="fixed bottom-0 left-0 right-0 bg-slate-900 text-white p-4 z-50 border-t border-slate-800 shadow-2xl backdrop-blur-md bg-slate-900/95 animate-slideUp">
          <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
            
            {/* Track Info */}
            <div className="flex items-center gap-3 w-full sm:w-1/4">
              <img
                src={currentPlayingTrack.thumbnail || "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=300&q=80"}
                alt={currentPlayingTrack.title}
                className="w-12 h-12 rounded-xl object-cover border border-slate-700 flex-shrink-0"
              />
              <div className="min-w-0">
                <h5 className="text-xs font-bold text-white truncate">{currentPlayingTrack.title}</h5>
                <p className="text-[10px] text-indigo-400 truncate">{currentPlayingTrack.category} • {currentPlayingTrack.artist}</p>
              </div>
            </div>

            {/* Play Controls & Seek Bar */}
            <div className="flex-1 max-w-xl w-full flex flex-col items-center gap-1.5">
              <div className="flex items-center gap-4">
                <button
                  onClick={() => handlePlayPreview(currentPlayingTrack)}
                  className="w-10 h-10 rounded-full bg-indigo-600 hover:bg-indigo-500 text-white flex items-center justify-center shadow-lg transition-all"
                >
                  {isPlaying ? <Pause className="w-5 h-5 fill-white" /> : <Play className="w-5 h-5 fill-white ml-0.5" />}
                </button>
              </div>

              <div className="flex items-center gap-2 w-full text-[10px] text-slate-400 font-mono">
                <span>{formatDuration(currentTime)}</span>
                <input
                  type="range"
                  min="0"
                  max={duration || currentPlayingTrack.duration || 100}
                  value={currentTime}
                  onChange={handleSeek}
                  className="w-full accent-indigo-500 h-1.5 bg-slate-800 rounded-lg cursor-pointer"
                />
                <span>{formatDuration(duration || currentPlayingTrack.duration)}</span>
              </div>
            </div>

            {/* Volume Control & Close */}
            <div className="flex items-center gap-3 w-full sm:w-auto justify-end">
              <button onClick={toggleMute} className="text-slate-400 hover:text-white">
                {isMuted || volume === 0 ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
              </button>
              <input
                type="range"
                min="0"
                max="1"
                step="0.05"
                value={volume}
                onChange={handleVolumeChange}
                className="w-20 accent-indigo-500 h-1.5 bg-slate-800 rounded-lg cursor-pointer"
              />
              <button
                onClick={() => {
                  audioRef.current?.pause();
                  setIsPlaying(false);
                  setCurrentPlayingTrack(null);
                }}
                className="text-slate-500 hover:text-white p-1 rounded-lg ml-2"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

          </div>
        </div>
      )}

      {/* BULK UPLOAD MODAL */}
      {showUploadModal && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-2xl w-full p-6 shadow-2xl border border-slate-100 max-h-[90vh] overflow-y-auto">
            
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
                  <Upload className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-slate-900">Bulk Music Upload System</h3>
                  <p className="text-[11px] text-slate-400">Supports 100-500 files, ZIP extraction & folder auto-categorization</p>
                </div>
              </div>
              <button
                onClick={() => setShowUploadModal(false)}
                className="p-2 text-slate-400 hover:text-slate-700 rounded-xl hover:bg-slate-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Drag & Drop Area */}
            <div
              onDragOver={(e) => e.preventDefault()}
              onDrop={handleFileDrop}
              className="mt-6 border-2 border-dashed border-indigo-200 hover:border-indigo-500 bg-indigo-50/30 rounded-2xl p-8 text-center transition-all cursor-pointer"
            >
              <FolderArchive className="w-12 h-12 mx-auto text-indigo-500 mb-3 stroke-[1.5]" />
              <h4 className="text-sm font-bold text-slate-800">Drag & Drop Music Folder or ZIP File</h4>
              <p className="text-xs text-slate-400 mt-1">
                Upload MP3, WAV, AAC, M4A, OGG files or structured .ZIP archives
              </p>
              
              <label className="mt-4 inline-block bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-4 py-2.5 rounded-xl cursor-pointer shadow-sm transition-all">
                Browse Files
                <input
                  type="file"
                  multiple
                  accept=".mp3,.wav,.aac,.m4a,.ogg,.zip"
                  onChange={handleFileSelect}
                  className="hidden"
                />
              </label>
            </div>

            {/* Folder Auto-Categorization Options */}
            <div className="grid grid-cols-2 gap-4 mt-6">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">Default Category Override</label>
                <select
                  value={uploadCategory}
                  onChange={(e) => setUploadCategory(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-700 outline-none focus:border-indigo-500"
                >
                  <option value="Auto-Detect">Auto-Detect Category from Folder Names</option>
                  {categoriesList.filter(c => c !== "All").map(cat => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">Language</label>
                <select
                  value={uploadLanguage}
                  onChange={(e) => setUploadLanguage(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-700 outline-none focus:border-indigo-500"
                >
                  {languagesList.filter(l => l !== "All").map(lang => (
                    <option key={lang} value={lang}>{lang}</option>
                  ))}
                </select>
              </div>
            </div>

            {/* Selected File Summary & Progress */}
            {selectedFiles.length > 0 && (
              <div className="mt-6 bg-slate-50 p-4 rounded-2xl border border-slate-100">
                <div className="flex items-center justify-between text-xs font-bold text-slate-800 mb-2">
                  <span>Selected Files: {selectedFiles.length} files</span>
                  <span>{formatBytes(selectedFiles.reduce((acc, f) => acc + f.size, 0))}</span>
                </div>

                {isUploading && (
                  <div>
                    <div className="w-full bg-slate-200 rounded-full h-2 overflow-hidden mb-2">
                      <div
                        className="bg-indigo-600 h-full transition-all duration-300 rounded-full"
                        style={{ width: `${uploadProgress}%` }}
                      ></div>
                    </div>
                    <p className="text-[10px] text-indigo-600 font-medium truncate">
                      Processing: {currentUploadingFile}
                    </p>
                  </div>
                )}

                {/* Success & Fail Counter Badges */}
                {(successCount > 0 || failedCount > 0) && (
                  <div className="flex items-center gap-3 mt-3">
                    <span className="bg-emerald-100 text-emerald-800 text-[10px] font-extrabold px-2.5 py-1 rounded-full flex items-center gap-1">
                      <CheckCircle2 className="w-3 h-3 text-emerald-600" /> Success: {successCount}
                    </span>
                    {failedCount > 0 && (
                      <span className="bg-rose-100 text-rose-800 text-[10px] font-extrabold px-2.5 py-1 rounded-full flex items-center gap-1">
                        <AlertCircle className="w-3 h-3 text-rose-600" /> Failed: {failedCount}
                      </span>
                    )}
                  </div>
                )}
              </div>
            )}

            {/* Action buttons */}
            <div className="mt-6 flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
              <button
                onClick={() => setShowUploadModal(false)}
                className="px-4 py-2.5 text-xs font-bold text-slate-500 hover:text-slate-800"
              >
                Cancel
              </button>
              <button
                onClick={triggerBulkUpload}
                disabled={selectedFiles.length === 0 || isUploading}
                className="bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white font-bold text-xs px-6 py-2.5 rounded-xl shadow-md transition-all cursor-pointer flex items-center gap-2"
              >
                {isUploading && <RefreshCw className="w-3.5 h-3.5 animate-spin" />}
                <span>{isUploading ? "Uploading & Extracting..." : `Start Bulk Upload (${selectedFiles.length})`}</span>
              </button>
            </div>

          </div>
        </div>
      )}

      {/* SINGLE TRACK EDIT MODAL */}
      {editingTrack && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-100">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
              <h3 className="text-sm font-bold text-slate-900">Edit Song Metadata</h3>
              <button onClick={() => setEditingTrack(null)} className="text-slate-400 hover:text-slate-700">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block text-[11px] font-bold text-slate-700 mb-1">Song Title</label>
                <input
                  type="text"
                  value={editingTrack.title}
                  onChange={(e) => setEditingTrack({ ...editingTrack, title: e.target.value })}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-800 outline-none focus:border-indigo-500"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-slate-700 mb-1">Category</label>
                <select
                  value={editingTrack.category}
                  onChange={(e) => setEditingTrack({ ...editingTrack, category: e.target.value })}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-800 outline-none focus:border-indigo-500"
                >
                  {categoriesList.filter(c => c !== "All").map(cat => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-[11px] font-bold text-slate-700 mb-1">Language</label>
                <select
                  value={editingTrack.language}
                  onChange={(e) => setEditingTrack({ ...editingTrack, language: e.target.value })}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-800 outline-none focus:border-indigo-500"
                >
                  {languagesList.filter(l => l !== "All").map(lang => (
                    <option key={lang} value={lang}>{lang}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-[11px] font-bold text-slate-700 mb-1">Artist</label>
                <input
                  type="text"
                  value={editingTrack.artist}
                  onChange={(e) => setEditingTrack({ ...editingTrack, artist: e.target.value })}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-800 outline-none focus:border-indigo-500"
                />
              </div>

              <div className="flex items-center gap-4 pt-2">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={editingTrack.isActive}
                    onChange={(e) => setEditingTrack({ ...editingTrack, isActive: e.target.checked })}
                    className="accent-indigo-600 rounded"
                  />
                  <span className="font-bold text-slate-700">Active</span>
                </label>

                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={editingTrack.isPremium}
                    onChange={(e) => setEditingTrack({ ...editingTrack, isPremium: e.target.checked })}
                    className="accent-indigo-600 rounded"
                  />
                  <span className="font-bold text-slate-700">Premium Only</span>
                </label>
              </div>
            </div>

            <div className="mt-6 flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                onClick={() => setEditingTrack(null)}
                className="px-3 py-1.5 font-bold text-slate-500 hover:text-slate-800"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveTrackEdit}
                className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold px-4 py-2 rounded-xl shadow-sm"
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}

      {/* BATCH ACTION MODALS */}
      {batchActionModal && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-sm w-full p-6 shadow-2xl border border-slate-100">
            <h3 className="text-sm font-bold text-slate-900 mb-3">
              {batchActionModal === "category" ? "Batch Update Category" : "Batch Update Language"}
            </h3>
            <p className="text-xs text-slate-500 mb-4">
              Apply change to all {selectedTrackIds.length} selected tracks.
            </p>

            {batchActionModal === "category" ? (
              <select
                value={batchCategoryValue}
                onChange={(e) => setBatchCategoryValue(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-xs font-semibold text-slate-800 outline-none mb-6"
              >
                {categoriesList.filter(c => c !== "All").map(cat => (
                  <option key={cat} value={cat}>{cat}</option>
                ))}
              </select>
            ) : (
              <select
                value={batchLanguageValue}
                onChange={(e) => setBatchLanguageValue(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-xs font-semibold text-slate-800 outline-none mb-6"
              >
                {languagesList.filter(l => l !== "All").map(lang => (
                  <option key={lang} value={lang}>{lang}</option>
                ))}
              </select>
            )}

            <div className="flex items-center justify-end gap-2">
              <button
                onClick={() => setBatchActionModal(null)}
                className="px-3 py-1.5 font-bold text-slate-500 hover:text-slate-800"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  if (batchActionModal === "category") {
                    handleBatchOperation("update_category", { category: batchCategoryValue });
                  } else {
                    handleBatchOperation("update_language", { language: batchLanguageValue });
                  }
                }}
                className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold px-4 py-2 rounded-xl shadow-sm"
              >
                Apply to {selectedTrackIds.length} Items
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
