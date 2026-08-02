import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

class JoinSharedBabyScreen extends ConsumerStatefulWidget {
  const JoinSharedBabyScreen({super.key});

  @override
  ConsumerState<JoinSharedBabyScreen> createState() => _JoinSharedBabyScreenState();
}

class _JoinSharedBabyScreenState extends ConsumerState<JoinSharedBabyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  bool _isProcessing = false;
  final _manualController = TextEditingController();
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _manualController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQRData(String jsonString) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Stop camera to prevent duplicate detections while processing
    _cameraController.stop();

    print('[DEBUG] QR scanned raw value: $jsonString');

    try {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (parseErr) {
        print('[DEBUG] JSON parse error: $parseErr');
        throw const FormatException('QR is not valid JSON.');
      }

      print('[DEBUG] Parsed QR data keys: ${data.keys.toList()}');

      var server = data['server'] as String?;
      final token = data['token'] as String?;
      final babyId = data['babyId'] as String?;

      print('[DEBUG] server=$server | token=${token != null ? '***' : 'NULL'} | babyId=$babyId');

      if (server == null || token == null || babyId == null) {
        throw const FormatException('Invalid QR code format. Missing keys: server, token or babyId.');
      }

      final expiresAtStr = data['expiresAt'] as String?;
      if (expiresAtStr != null) {
        final expiresAt = DateTime.tryParse(expiresAtStr);
        if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
          throw const FormatException('QR Code has expired. Please ask the parent for a new QR code.');
        }
      }

      final resolvedServer = ApiConfig.resolveServerUrl(server);
      print('[DEBUG] Resolved server URL for client: $resolvedServer');

      final authState = ref.read(authNotifierProvider);
      final prefs = ref.read(sharedPreferencesProvider);

      if (authState.status != AuthStatus.authenticated) {
        await prefs.setString('pending_qr_join_data', jsonString);
        print('[DEBUG] Caregiver not logged in. Saved QR join data. Navigating to login...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Access saved! Please login to complete authorization.'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
          context.go('/login');
        }
        return;
      }

      print('[DEBUG] Auth OK. Setting base URL to: $resolvedServer');
      ref.read(apiClientProvider).setBaseUrl(resolvedServer);

      print('[DEBUG] Sending POST /caregivers/accept with token...');
      dynamic response;
      try {
        response = await ref.read(apiClientProvider).post(
          '/caregivers/accept',
          body: {'token': token},
        );
        print('[DEBUG] Accept response: $response');
      } catch (apiErr) {
        print('[DEBUG] API call failed: $apiErr');
        rethrow;
      }

      await prefs.remove('pending_qr_join_data');

      // Refresh dashboard — wrapped separately so it doesn't block success dialog
      try {
        print('[DEBUG] Refreshing dashboard...');
        await ref.read(dashboardProvider.notifier).refresh();
        print('[DEBUG] Dashboard refreshed.');
      } catch (refreshErr) {
        print('[DEBUG] Dashboard refresh failed (non-critical): $refreshErr');
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Access Granted',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Live Monitoring Access Granted successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('[DEBUG] ❌ Error processing QR: $e');
      print('[DEBUG] StackTrace: $stackTrace');

      String errMsg = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      if (e is FormatException) {
        errMsg = 'Invalid QR structure: ${e.message}\n\nPlease scan a valid MAATRIVA invite.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('connectionError') ||
          e.toString().contains('500') ||
          e.toString().contains('502') ||
          e.toString().contains('503')) {
        errMsg = 'Backend server is offline or unreachable.\n\nMake sure you are on the same Wi-Fi as the parent\'s device.';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                const SizedBox(width: 8),
                Text('Scan Failed', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(child: Text(errMsg)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Try Again', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        // Resume camera scanning after processing
        _cameraController.start();
      }
    }
  }

  void _showManualInputDialog() {
    _manualController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Enter QR Data Manually',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste the raw JSON string generated by the parent phone below:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _manualController,
              maxLines: 5,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '{\n  "server": "http://192.168.1.15:3000",\n  "token": "...",\n  "babyId": "..."\n}',
                filled: true,
                fillColor: const Color(0xFFF7F5FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final text = _manualController.text.trim();
                  Navigator.pop(context);
                  if (text.isNotEmpty) {
                    _processQRData(text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Text(
                  'Submit QR Data',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Join Shared Baby',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Scan Parent\'s QR Code',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Point camera at the QR code displayed on the parent\'s screen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            // Live Camera Viewfinder
            Center(
              child: Container(
                width: 260.r,
                height: 260.r,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(32.r),
                  border: Border.all(color: AppColors.primary, width: 2.5),
                  boxShadow: AppColors.softShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _cameraController,
                        onDetect: (capture) {
                          if (_isProcessing) return;
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                              _processQRData(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                        errorBuilder: (context, error) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.r),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 40.r, color: Colors.white54),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Camera access unavailable or permission required',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: _scanAnimation.value * 250.r,
                            left: 16.w,
                            right: 16.w,
                            child: Container(
                              height: 3.h,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(2.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withOpacity(0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (_isProcessing)
                        Container(
                          color: Colors.black.withOpacity(0.6),
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Flash / Torch & Camera Flip controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _cameraController.toggleTorch(),
                  icon: const Icon(Icons.flash_on_rounded, color: AppColors.primary),
                  tooltip: 'Toggle Flash',
                ),
                SizedBox(width: 24.w),
                IconButton(
                  onPressed: () => _cameraController.switchCamera(),
                  icon: const Icon(Icons.cameraswitch_rounded, color: AppColors.primary),
                  tooltip: 'Switch Camera',
                ),
              ],
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _showManualInputDialog,
                  icon: const Icon(Icons.paste_rounded, color: Colors.white),
                  label: const Text(
                    'Simulate Scan (Enter QR Data)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

