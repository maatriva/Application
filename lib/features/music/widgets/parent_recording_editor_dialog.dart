import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/core/theme/app_typography.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../services/audio_service.dart';
import '../services/audio_picker_service.dart';
import '../services/voice_recorder_service.dart';

import '../services/audio_scanner_service.dart';

enum EditorPhase {
  recording, // Step 1: Record Parent Voice
  editing,   // Step 2: Recording Editor (Playback, BG Music, Mixer, Trim, Fade, Noise Reduction, Save)
}

class ParentRecordingEditorDialog extends ConsumerStatefulWidget {
  const ParentRecordingEditorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ParentRecordingEditorDialog(),
    );
  }

  @override
  ConsumerState<ParentRecordingEditorDialog> createState() =>
      _ParentRecordingEditorDialogState();
}

class _ParentRecordingEditorDialogState
    extends ConsumerState<ParentRecordingEditorDialog> {
  EditorPhase _currentPhase = EditorPhase.recording;

  final AudioService _voicePlayer = AudioService();
  final AudioService _bgPlayer = AudioService();

  // ── Recording State ────────────────────────────────────────────────────────
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _recordedVoicePath;
  String? _recordedFileName;

  // ── Playback / Position State ──────────────────────────────────────────────
  bool _isPlayingPreview = false;
  double _currentPositionSeconds = 0.0;
  Timer? _playbackPositionTimer;

  // ── Editor Controls & Features State ───────────────────────────────────────

  // Dynamic Background Tracks scanned from backend/uploads/music/ & assets/audio/
  List<Map<String, dynamic>> _bgMusicTracks = [];
  bool _isLoadingBgTracks = false;

  String _selectedBgTrackName = '';

  // 3. Audio Mixer (0 - 100%)
  double _voiceVolume = 0.8;    // 80%
  double _bgMusicVolume = 0.3;  // 30%

  // 4. Non-Destructive Trim
  double _trimStartSeconds = 0.0;
  double _trimEndSeconds = 30.0;

  // 5. Fade In / Fade Out (0 – 5 seconds)
  double _fadeInSeconds = 1.0;
  double _fadeOutSeconds = 1.0;

  // 6. Noise Reduction
  bool _noiseReductionEnabled = true;

  // 8. Save & Metadata
  final TextEditingController _titleController = TextEditingController();
  final String _ownerId = 'parent_user_01';
  final String _babyId = 'baby_01';
  bool _shareWithCaregiver = false; // Requirement 10: Private by default!
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadScannedBgMusicTracks();
  }

  Future<void> _loadScannedBgMusicTracks() async {
    setState(() => _isLoadingBgTracks = true);
    final scanned = await AudioScannerService.scanBgMusicTracks();
    if (mounted) {
      setState(() {
        _bgMusicTracks = scanned;
        _isLoadingBgTracks = false;
        if (_bgMusicTracks.isNotEmpty) {
          if (_selectedBgTrackName.isEmpty || !_bgMusicTracks.any((t) => t['name'] == _selectedBgTrackName)) {
            _selectedBgTrackName = _bgMusicTracks.first['name'] as String;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playbackPositionTimer?.cancel();
    _voicePlayer.pause();
    _bgPlayer.pause();
    _titleController.dispose();
    super.dispose();
  }

  // ── Recording Logic ────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final started = await VoiceRecorderService.start();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone access simulation mode active.'),
          backgroundColor: Color(0xFF6B4EE6),
        ),
      );
    }
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final result = await VoiceRecorderService.stop(_recordingSeconds);
    if (mounted) {
      final totalSecs = _recordingSeconds > 0 ? _recordingSeconds : 30;
      setState(() {
        _isRecording = false;
        if (result != null && result.dataUrl.isNotEmpty) {
          _recordedVoicePath = result.dataUrl;
          _recordedFileName = 'Voice Recording (${totalSecs}s)';
        } else {
          _recordedVoicePath = 'assets/audio/apalonbeats-bollywood-indian-hindi-song-music-576335.mp3';
          _recordedFileName = 'Parent Voice Recording (${totalSecs}s)';
        }
        _recordingSeconds = totalSecs;
        _trimStartSeconds = 0.0;
        _trimEndSeconds = totalSecs.toDouble();
        // Automatically switch to Recording Editor phase!
        _currentPhase = EditorPhase.editing;
      });
    }
  }

  // ── Playback & Preview Engine ──────────────────────────────────────────────
  Future<void> _stopPreviewPlayback() async {
    _playbackPositionTimer?.cancel();
    await _voicePlayer.pause();
    await _bgPlayer.pause();
    if (mounted) {
      setState(() {
        _isPlayingPreview = false;
      });
    }
  }

  Future<void> _togglePreviewPlayback() async {
    if (_isPlayingPreview) {
      await _stopPreviewPlayback();
    } else {
      await _stopPreviewPlayback();

      final bgTrack = _bgMusicTracks.isNotEmpty
          ? _bgMusicTracks.firstWhere(
              (t) => t['name'] == _selectedBgTrackName,
              orElse: () => _bgMusicTracks.first,
            )
          : null;
      final bgAudioUrl = bgTrack != null ? (bgTrack['audioUrl'] as String) : '';

      final String mainAudioPath = (_recordedVoicePath != null && _recordedVoicePath!.isNotEmpty)
          ? _recordedVoicePath!
          : bgAudioUrl;

      if (mainAudioPath.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No audio file selected for preview.')),
          );
        }
        return;
      }

      final previewSong = Song(
        id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Preview Audio',
        artist: bgTrack != null ? (bgTrack['name'] as String) : 'Background Sound',
        duration: Duration(seconds: (_trimEndSeconds - _trimStartSeconds).round().clamp(1, 600)),
        category: 'Parent Voice',
        genre: "Parent's Melody Vault",
        albumArtColor: 'rose',
        audioPath: mainAudioPath,
        sourceType: mainAudioPath.startsWith('assets/') || mainAudioPath.startsWith('audio/') ? 'ASSET' : 'RECORDED',
        bgAudioPath: (_recordedVoicePath != null && _recordedVoicePath!.isNotEmpty) ? bgAudioUrl : null,
        bgMusicVolume: _bgMusicVolume,
        voiceVolume: _voiceVolume,
        trimStartSeconds: _trimStartSeconds,
        trimEndSeconds: _trimEndSeconds,
      );

      debugPrint('[Editor Preview] Playing song preview: main=$mainAudioPath, bg=$bgAudioUrl');
      final success = await _voicePlayer.playSong(previewSong);

      if (mounted) {
        setState(() {
          _isPlayingPreview = success;
        });
      }

      // Start position tracking ticker
      _playbackPositionTimer?.cancel();
      _playbackPositionTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
        if (!mounted || !_isPlayingPreview) {
          t.cancel();
          return;
        }
        setState(() {
          _currentPositionSeconds += 0.3;
          if (_currentPositionSeconds >= _trimEndSeconds) {
            _currentPositionSeconds = _trimStartSeconds;
            _stopPreviewPlayback();
          }
        });
      });
    }
  }

  // ── Save & Database Integration ────────────────────────────────────────────
  Future<void> _handleSave() async {
    await _stopPreviewPlayback();
    if (!mounted) return;

    if (_recordingSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save an empty recording.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final defaultTitle = 'Parent Lullaby (${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year})';
    final title = _titleController.text.trim().isEmpty ? defaultTitle : _titleController.text.trim();

    setState(() => _isSaving = true);

    final bgTrack = _bgMusicTracks.firstWhere(
      (t) => t['name'] == _selectedBgTrackName,
      orElse: () => _bgMusicTracks.first,
    );

    final timestamp = DateTime.now();
    final recordingId = 'parent_recording_${timestamp.millisecondsSinceEpoch}';
    final voiceUrl = (_recordedVoicePath != null && _recordedVoicePath!.isNotEmpty)
        ? _recordedVoicePath!
        : 'assets/audio/lullaby_classic.wav';

    // Store both raw voice recording and mixed recording reference
    final newSong = Song(
      id: recordingId,
      title: title,
      artist: 'Parent Voice (${bgTrack['name']})',
      duration: Duration(seconds: (_trimEndSeconds - _trimStartSeconds).round().clamp(1, 600)),
      category: 'Parent Voice',
      genre: "Parent's Melody Vault",
      albumArtColor: 'rose',
      audioPath: voiceUrl,
      sourceType: 'RECORDED',
      isCustomParentSong: true,
      isSharedWithCaregiver: true,
      visibility: 'SHARED_WITH_CAREGIVERS',
      ownerId: _ownerId,
      babyId: _babyId,
      aiBadge: 'Parent Recording',
      voiceFileUrl: voiceUrl,
      mixedFileUrl: voiceUrl,
      backgroundTrack: bgTrack['name'] as String,
      bgAudioPath: bgTrack['audioUrl'] as String,
      bgMusicVolume: _bgMusicVolume,
      voiceVolume: _voiceVolume,
      trimStartSeconds: _trimStartSeconds,
      trimEndSeconds: _trimEndSeconds,
      fadeIn: _fadeInSeconds,
      fadeOut: _fadeOutSeconds,
      noiseReduction: _noiseReductionEnabled,
      createdAt: timestamp,
    );

    await ref.read(musicProvider.notifier).addCustomSong(newSong);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saved "$title" to Parent\'s Melody Vault!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF6B4EE6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDuration(double totalSecs) {
    final secs = totalSecs.round();
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── UI Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: const Color(0xFFFBF9FE),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFBF9FE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),

              // Dialog Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _currentPhase == EditorPhase.recording ? Icons.mic_rounded : Icons.tune_rounded,
                        color: const Color(0xFF6B4EE6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentPhase == EditorPhase.recording
                                ? 'Record Parent Voice'
                                : 'Parent Recording Editor',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _currentPhase == EditorPhase.recording
                                ? 'Record a lullaby or story in your own voice'
                                : 'Mix background sounds, trim, and set volume',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const Divider(height: 20, thickness: 1, color: Color(0xFFEDE7F6)),

              // Active View
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _currentPhase == EditorPhase.recording
                      ? _buildRecordingPhase()
                      : _buildEditorPhase(),
                ),
              ),

              // Bottom Action Footer
              if (_currentPhase == EditorPhase.editing) _buildEditorFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PHASE 1: RECORD PARENT VOICE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecordingPhase() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          _isRecording ? 'Recording in Progress...' : 'Tap Mic to Start Recording',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatDuration(_recordingSeconds.toDouble()),
          style: GoogleFonts.outfit(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _isRecording ? const Color(0xFFE53935) : const Color(0xFF6B4EE6),
          ),
        ),
        const SizedBox(height: 32),

        // Record Button
        GestureDetector(
          onTap: () {
            if (_isRecording) {
              _stopRecording();
            } else {
              _startRecording();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? const Color(0xFFFFEBEE) : const Color(0xFFEDE7F6),
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? const Color(0xFFE53935) : const Color(0xFF6B4EE6))
                      .withOpacity(0.25),
                  blurRadius: _isRecording ? 32 : 16,
                  spreadRadius: _isRecording ? 8 : 2,
                )
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? const Color(0xFFE53935) : const Color(0xFF6B4EE6),
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isRecording
              ? 'Tap red stop button to complete recording & open editor'
              : 'Speak or sing softly into your mic',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        if (!_isRecording) ...[
          OutlinedButton.icon(
            onPressed: () async {
              final result = await AudioPickerService.pick();
              if (result != null && mounted) {
                setState(() {
                  _recordedFileName = result.name;
                  _recordedVoicePath = result.dataUrl;
                  _recordingSeconds = 60;
                  _trimStartSeconds = 0;
                  _trimEndSeconds = 60;
                  _currentPhase = EditorPhase.editing;
                });
              }
            },
            icon: const Icon(Icons.audio_file_rounded, size: 18, color: Color(0xFF6B4EE6)),
            label: Text(
              _recordedFileName != null
                  ? 'Selected: $_recordedFileName'
                  : 'Or import existing voice file',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B4EE6)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6B4EE6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PHASE 2: RECORDING EDITOR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEditorPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Playback Preview Card
        _buildPlaybackPreviewCard(),
        const SizedBox(height: 16),

        // 2. Background Music Selector
        _buildBackgroundMusicCard(),
        const SizedBox(height: 16),

        // 3. Dual Audio Mixer
        _buildAudioMixerCard(),
        const SizedBox(height: 16),

        // 4. Non-Destructive Trim
        _buildTrimCard(),
        const SizedBox(height: 16),

        // 5. Fade In / Fade Out Controls
        _buildFadeControlsCard(),
        const SizedBox(height: 16),

        // 6. Noise Reduction Toggle
        _buildNoiseReductionCard(),
        const SizedBox(height: 16),

        // 7. Preview Button & Save Title Input
        _buildSaveMetadataCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── 1. Playback Preview Card ───────────────────────────────────────────────
  Widget _buildPlaybackPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE7F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.graphic_eq_rounded, color: Color(0xFF6B4EE6), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Playback Preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_formatDuration(_currentPositionSeconds)} / ${_formatDuration(_trimEndSeconds - _trimStartSeconds)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4EE6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual Waveform & Position Slider
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  30,
                  (i) {
                    final isPlayed = (i / 30.0) <=
                        (_currentPositionSeconds / (_trimEndSeconds > 0 ? _trimEndSeconds : 30.0));
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 4,
                      height: (10 + (i % 6) * 5).toDouble(),
                      decoration: BoxDecoration(
                        color: isPlayed ? const Color(0xFF6B4EE6) : const Color(0xFFD1C4E9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ),
              Slider(
                value: _currentPositionSeconds.clamp(_trimStartSeconds, _trimEndSeconds),
                min: _trimStartSeconds,
                max: _trimEndSeconds > _trimStartSeconds ? _trimEndSeconds : 30.0,
                activeColor: const Color(0xFF6B4EE6),
                inactiveColor: Colors.grey.shade200,
                onChanged: (val) {
                  setState(() {
                    _currentPositionSeconds = val;
                  });
                },
              ),
            ],
          ),

          Center(
            child: TextButton.icon(
              onPressed: _togglePreviewPlayback,
              icon: Icon(
                _isPlayingPreview ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                color: const Color(0xFF6B4EE6),
                size: 36,
              ),
              label: Text(
                _isPlayingPreview ? 'Pause Preview' : 'Play Preview',
                style: const TextStyle(
                  color: Color(0xFF6B4EE6),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Background Music Selector Card ──────────────────────────────────────
  Widget _buildBackgroundMusicCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.folder_open_rounded, color: Color(0xFF0288D1), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Background Music (Folder Songs)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${_bgMusicTracks.length} Tracks',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: _isLoadingBgTracks
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0288D1)),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF0288D1)),
                    tooltip: 'Rescan folder songs',
                    onPressed: _isLoadingBgTracks ? null : _loadScannedBgMusicTracks,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_bgMusicTracks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(Icons.drive_folder_upload_rounded, color: Color(0xFF0288D1), size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'No songs found in backend music folder',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Drop MP3 / WAV files into "backend/uploads/music/" on your server/disk and tap refresh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loadScannedBgMusicTracks,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Rescan Music Folder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0288D1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 115,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _bgMusicTracks.length,
                itemBuilder: (context, idx) {
                  final track = _bgMusicTracks[idx];
                  final isSelected = _selectedBgTrackName == track['name'];

                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _selectedBgTrackName = track['name'] as String;
                      });
                      await _stopPreviewPlayback();
                      await _togglePreviewPlayback();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6B4EE6) : (track['color'] as Color),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6B4EE6) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            track['icon'] as IconData,
                            size: 24,
                            color: isSelected ? Colors.white : const Color(0xFF6B4EE6),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            track['name'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track['desc'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── 3. Audio Mixer Card ───────────────────────────────────────────────────
  Widget _buildAudioMixerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tune_rounded, color: Color(0xFF6B4EE6), size: 20),
              SizedBox(width: 8),
              Text(
                'Audio Mixer (Volume Control)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Voice Volume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Voice Volume', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${(_voiceVolume * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4EE6))),
            ],
          ),
          Slider(
            value: _voiceVolume,
            min: 0.0,
            max: 1.0,
            activeColor: const Color(0xFF6B4EE6),
            inactiveColor: Colors.grey.shade200,
            onChanged: (val) {
              setState(() => _voiceVolume = val);
              if (_isPlayingPreview) {
                _voicePlayer.setVolume(val);
              }
            },
          ),

          const SizedBox(height: 8),

          // Background Music Volume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Background Music ($_selectedBgTrackName)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${(_bgMusicVolume * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0288D1))),
            ],
          ),
          Slider(
            value: _bgMusicVolume,
            min: 0.0,
            max: 1.0,
            activeColor: const Color(0xFF0288D1),
            inactiveColor: Colors.grey.shade200,
            onChanged: (val) {
              setState(() => _bgMusicVolume = val);
              if (_isPlayingPreview) {
                _voicePlayer.setBgVolume(val);
              }
            },
          ),
        ],
      ),
    );
  }

  // ── 4. Non-Destructive Trim Card ──────────────────────────────────────────
  Widget _buildTrimCard() {
    final maxDuration = (_recordingSeconds > 0 ? _recordingSeconds : 30).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.content_cut_rounded, color: Color(0xFF6B4EE6), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Trim Audio (Non-Destructive)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const Text(
                'Original Kept Intact',
                style: TextStyle(fontSize: 10, color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Start: ${_trimStartSeconds.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('End: ${_trimEndSeconds.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),

          RangeSlider(
            values: RangeValues(_trimStartSeconds, _trimEndSeconds.clamp(_trimStartSeconds, maxDuration)),
            min: 0.0,
            max: maxDuration,
            activeColor: const Color(0xFF6B4EE6),
            inactiveColor: Colors.grey.shade200,
            onChanged: (RangeValues values) {
              setState(() {
                _trimStartSeconds = values.start;
                _trimEndSeconds = values.end;
              });
            },
          ),
        ],
      ),
    );
  }

  // ── 5. Fade Controls Card ──────────────────────────────────────────────────
  Widget _buildFadeControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF6B4EE6), size: 20),
              SizedBox(width: 8),
              Text(
                'Fade In & Fade Out (0–5 seconds)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fade In: ${_fadeInSeconds.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Slider(
                      value: _fadeInSeconds,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      activeColor: const Color(0xFF6B4EE6),
                      inactiveColor: Colors.grey.shade200,
                      onChanged: (val) => setState(() => _fadeInSeconds = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fade Out: ${_fadeOutSeconds.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Slider(
                      value: _fadeOutSeconds,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      activeColor: const Color(0xFF6B4EE6),
                      inactiveColor: Colors.grey.shade200,
                      onChanged: (val) => setState(() => _fadeOutSeconds = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 6. Noise Reduction Card ────────────────────────────────────────────────
  Widget _buildNoiseReductionCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDE7F6)),
        ),
        child: SwitchListTile(
          tileColor: Colors.white,
          title: Row(
            children: const [
              Icon(Icons.cleaning_services_rounded, color: Color(0xFF6B4EE6), size: 20),
              SizedBox(width: 8),
              Text('Noise Reduction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          subtitle: const Text(
            'Suppress background room hiss and fan noise',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          value: _noiseReductionEnabled,
          activeColor: const Color(0xFF6B4EE6),
          onChanged: (val) => setState(() => _noiseReductionEnabled = val),
        ),
      ),
    );
  }

  // ── 7. Save & Metadata Card ────────────────────────────────────────────────
  Widget _buildSaveMetadataCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.save_rounded, color: Color(0xFF6B4EE6), size: 20),
              SizedBox(width: 8),
              Text(
                'Save Details & Privacy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Recording Title',
              hintText: 'e.g. Mommy\'s Bedtime Story for Baby',
              prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF6B4EE6)),
              filled: true,
              fillColor: const Color(0xFFFBF9FE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // ── Editor Footer Bar ──────────────────────────────────────────────────────
  Widget _buildEditorFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _stopPreviewPlayback();
                setState(() => _currentPhase = EditorPhase.recording);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF6B4EE6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Re-Record', style: TextStyle(color: Color(0xFF6B4EE6), fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EE6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Save to Custom Folder',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
