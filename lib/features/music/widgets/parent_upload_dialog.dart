import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../features/authentication/presentation/providers/auth_provider.dart';
import '../../../shared/models/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../services/audio_picker_service.dart';

void showParentCustomLullabyDialog(BuildContext context, [WidgetRef? ref]) {
  if (ref != null) {
    final authState = ref.read(authNotifierProvider);
    if (authState.session?.role == UserRole.caregiver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caregivers are not permitted to add custom music.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
  }
  showDialog(
    context: context,
    builder: (dialogContext) => const ParentUploadDialog(),
  );
}

class ParentUploadDialog extends ConsumerStatefulWidget {
  const ParentUploadDialog({super.key});

  @override
  ConsumerState<ParentUploadDialog> createState() => _ParentUploadDialogState();
}

class _ParentUploadDialogState extends ConsumerState<ParentUploadDialog> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final AudioPlayer _previewPlayer = AudioPlayer();

  String _selectedCategory = 'Lullabies';
  bool _shareWithCaregiver = false;
  bool _isUploading = false;
  bool _isPlayingPreview = false;
  
  String? _selectedFileName;
  String? _selectedAudioDataUrl;
  Duration _selectedDuration = const Duration(minutes: 3, seconds: 15);

  final List<String> _categories = [
    'Lullabies',
    'Bedtime Songs',
    'Nature Sounds',
    'White Noise',
    'Nursery Rhymes',
    'Womb Sounds',
    'Parent Voice',
    'Gallery Songs',
  ];

  @override
  void initState() {
    super.initState();
    _artistController.text = 'Parent / Family';
    _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingPreview = false);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFromGallery() async {
    _stopPreview();
    final result = await AudioPickerService.pick();
    if (result != null && mounted) {
      debugPrint('[Music] Audio Selected from Gallery: ${result.name}');
      setState(() {
        _selectedFileName = result.name;
        _selectedAudioDataUrl = result.dataUrl ?? 'assets/audio/lullaby_classic.wav';
        if (result.duration != null) {
          _selectedDuration = result.duration!;
        }
        if (result.category != null && _categories.contains(result.category)) {
          _selectedCategory = result.category!;
        }
        if (_titleController.text.trim().isEmpty) {
          final cleanName = result.name
              .replaceAll(RegExp(r'\.[^/.]+$'), '')
              .replaceAll(RegExp(r'[_\-]'), ' ');
          _titleController.text = cleanName;
        }
      });
    }
  }

  void _selectPreset(AudioPickerResult preset) {
    _stopPreview();
    setState(() {
      _selectedFileName = preset.name;
      _selectedAudioDataUrl = preset.dataUrl ?? 'assets/audio/lullaby_classic.wav';
      _selectedDuration = preset.duration ?? const Duration(minutes: 3, seconds: 0);
      if (preset.category != null && _categories.contains(preset.category)) {
        _selectedCategory = preset.category!;
      }
      final cleanName = preset.name
          .replaceAll(RegExp(r'\.[^/.]+$'), '')
          .replaceAll(RegExp(r'[_\-]'), ' ');
      _titleController.text = cleanName;
      if (preset.artist != null && preset.artist!.isNotEmpty) {
        _artistController.text = preset.artist!;
      }
    });
  }

  Future<void> _togglePreview() async {
    if (_selectedAudioDataUrl == null) return;
    try {
      if (_isPlayingPreview) {
        await _stopPreview();
      } else {
        setState(() => _isPlayingPreview = true);
        if (_selectedAudioDataUrl!.startsWith('assets/')) {
          final assetPath = _selectedAudioDataUrl!.replaceFirst('assets/', '');
          await _previewPlayer.play(AssetSource(assetPath));
        } else if (_selectedAudioDataUrl!.startsWith('http') || _selectedAudioDataUrl!.startsWith('data:')) {
          await _previewPlayer.play(UrlSource(_selectedAudioDataUrl!));
        } else {
          await _previewPlayer.play(DeviceFileSource(_selectedAudioDataUrl!));
        }
      }
    } catch (e) {
      debugPrint('[AudioPreview] Error playing: $e');
      setState(() => _isPlayingPreview = false);
    }
  }

  Future<void> _stopPreview() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
    if (mounted) setState(() => _isPlayingPreview = false);
  }

  Future<void> _submitCustomLullaby() async {
    await _stopPreview();
    final authState = ref.read(authNotifierProvider);
    if (authState.session?.role == UserRole.caregiver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caregivers are not permitted to add custom music.')),
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a song title')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final newSong = Song(
        id: 'parent_custom_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        artist: _artistController.text.trim().isNotEmpty ? _artistController.text.trim() : 'Parent / Family',
        duration: _selectedDuration,
        category: _selectedCategory,
        genre: "Parent's Melody Vault",
        albumArtColor: 'amber',
        audioPath: (_selectedAudioDataUrl != null && _selectedAudioDataUrl!.isNotEmpty)
            ? _selectedAudioDataUrl!
            : 'assets/audio/lullaby_classic.wav',
        sourceType: 'UPLOADED',
        isCustomParentSong: true,
        isSharedWithCaregiver: true,
      );

      final saved = await ref.read(musicProvider.notifier).addCustomSong(newSong);
      if (!saved) {
        throw StateError('This audio file is too large to save on this device.');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00838F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _shareWithCaregiver
                        ? 'Saved "$title" to Parent\'s Melody Vault! (Shared with Caregiver)'
                        : 'Saved "$title" to Parent\'s Melody Vault! (Private to Parent)',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding song: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.folder_special_rounded, color: Color(0xFF00838F), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Song from Gallery',
                          style: GoogleFonts.outfit(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Import your favorite music to Parent\'s Melody Vault',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // File Selection Box
              InkWell(
                onTap: _pickAudioFromGallery,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _selectedFileName != null ? const Color(0xFFE0F7FA).withOpacity(0.6) : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedFileName != null ? const Color(0xFF00838F) : AppColors.divider,
                      width: _selectedFileName != null ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedFileName != null ? Icons.music_note_rounded : Icons.photo_library_rounded,
                            size: 32,
                            color: _selectedFileName != null ? const Color(0xFF00838F) : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.file_upload_outlined,
                            size: 24,
                            color: _selectedFileName != null ? const Color(0xFF00838F) : AppColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedFileName ?? 'Tap to browse audio files from gallery / storage',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _selectedFileName != null ? const Color(0xFF00838F) : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports MP3, WAV, M4A, AAC, OGG files',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),

                      if (_selectedFileName != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _togglePreview,
                              icon: Icon(_isPlayingPreview ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 16),
                              label: Text(_isPlayingPreview ? 'Stop Preview' : 'Preview Audio'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00838F),
                                side: const BorderSide(color: Color(0xFF00838F)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Quick Gallery Sample Presets
              Text(
                'Or choose a Gallery Preset:',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: galleryPresets.map((preset) {
                    final isSelected = _selectedFileName == preset.name;
                    return GestureDetector(
                      onTap: () => _selectPreset(preset),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00838F) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00838F) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.audiotrack_rounded,
                              size: 14,
                              color: isSelected ? Colors.white : const Color(0xFF00838F),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              preset.name.replaceAll('.mp3', '').replaceAll('.wav', ''),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 18),

              // Title input
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Song / Lullaby Title',
                  hintText: 'e.g. Grandma\'s Soft Blessing',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
              ),

              const SizedBox(height: 14),

              // Artist input
              TextField(
                controller: _artistController,
                decoration: InputDecoration(
                  labelText: 'Artist / Parent Name',
                  hintText: 'e.g. Mom & Dad',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
              ),

              const SizedBox(height: 14),

              // Category Selector
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _stopPreview();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitCustomLullaby,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00838F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Add to Vault', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
