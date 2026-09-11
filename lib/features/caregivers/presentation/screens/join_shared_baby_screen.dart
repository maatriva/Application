import 'dart:convert';
import 'package:flutter/foundation.dart';
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

    // A QR scanned before login is retained locally. Once authentication routes
    // the caregiver back here, resume the exact invitation instead of asking
    // them to scan a second time.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumePendingQrJoin());
  }

  Future<void> _resumePendingQrJoin() async {
    final auth = ref.read(authNotifierProvider);
    if (auth.status != AuthStatus.authenticated) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final pendingQr = prefs.getString('pending_qr_join_data');
    if (pendingQr == null || pendingQr.isEmpty) return;

    await _processQRData(pendingQr);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _manualController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.dns_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text('Server IP / URL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Base URL:\n${ApiConfig.baseUrl}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter your parent/backend IP address (e.g. http://192.168.1.5:3000):',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'http://192.168.1.5:3000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = ref.read(sharedPreferencesProvider);
              await prefs.remove('custom_base_url');
              ApiConfig.setCustomBaseUrl(null);
              if (mounted && dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Server URL reset to default LAN IP.')),
                );
              }
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                final prefs = ref.read(sharedPreferencesProvider);
                await prefs.setString('custom_base_url', newUrl);
                ApiConfig.setCustomBaseUrl(newUrl);
                if (mounted && dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server URL set to ${ApiConfig.baseUrl}')),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

      if (data['isUsed'] == true || data['claimed'] == true || data['used'] == true) {
        throw const FormatException('This QR code has already been used by another caretaker. Each QR code works for one person only.');
      }

      final expiresAtStr = data['expiresAt'] as String?;
      if (expiresAtStr != null) {
        final expiresAt = DateTime.tryParse(expiresAtStr)?.toUtc();
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt)) {
          throw const FormatException('QR Code has expired. Please ask the parent for a new QR code.');
        }
      }

      final resolvedServer = ApiConfig.resolveServerUrl(server);
      print('[DEBUG] Resolved server URL for client: $resolvedServer');

      final authState = ref.read(authNotifierProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      final secureStorage = ref.read(secureStorageServiceProvider);
      final accessToken = await secureStorage.getAccessToken();

      if (authState.status != AuthStatus.authenticated || accessToken == null || accessToken.trim().isEmpty) {
        await prefs.setString('pending_qr_join_data', jsonString);
        print('[DEBUG] Caregiver not logged in or missing access token. Saved QR join data. Navigating to login...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Authentication required. Invitation saved! Please log in to complete caregiver authorization.'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
          context.go('/login');
        }
        return;
      }

      final candidateServers = <String>{
        ApiConfig.baseUrl,
        if (ApiConfig.customBaseUrl != null && ApiConfig.customBaseUrl!.isNotEmpty) ApiConfig.customBaseUrl!,
        resolvedServer,
        if (defaultTargetPlatform == TargetPlatform.android) 'http://10.0.2.2:3000',
        'http://localhost:3000',
        ApiConfig.prodBaseUrl,
        ApiConfig.stagingBaseUrl,
      }.where((s) => s.trim().isNotEmpty).toList();

      print('[DEBUG] Candidate servers for invitation accept: $candidateServers');

      dynamic response;
      Object? lastError;
      String? workingServer;

      for (final candidateUrl in candidateServers) {
        try {
          print('[DEBUG] Attempting POST /caregivers/accept on: $candidateUrl');
          ref.read(apiClientProvider).setBaseUrl(candidateUrl);
          response = await ref.read(apiClientProvider).post(
            '/caregivers/accept',
            body: {'token': token},
          );
          workingServer = candidateUrl;
          print('[DEBUG] Accept SUCCESS on candidate server: $workingServer response: $response');
          ApiConfig.setCustomBaseUrl(workingServer);
          break;
        } catch (candidateErr) {
          print('[DEBUG] Candidate server $candidateUrl failed: $candidateErr');
          lastError = candidateErr;
        }
      }

      if (workingServer == null) {
        print('[DEBUG] All candidate servers failed. Rethrowing last error: $lastError');
        throw lastError ?? Exception('Could not reach any backend server.');
      }

      await prefs.remove('pending_qr_join_data');

      // Cache active caregiver granted session persistently so re-logins retain dashboard access during valid window
      try {
        final cacheService = ref.read(cacheServiceProvider);
        await cacheService.clearCaregiverGrantedSession();

        final Map<String, dynamic>? resMap = (response is Map) ? Map<String, dynamic>.from(response) : null;
        final caregiverAccessMap = (resMap?['caregiverAccess'] as Map<String, dynamic>?) ??
            (resMap?['data'] as Map<String, dynamic>?);
        final String? expiresAtStr = caregiverAccessMap?['expiresAt'] as String? ?? resMap?['expiresAt'] as String?;

        if (expiresAtStr != null) {
          final sessionData = {
            'server': workingServer,
            'token': token,
            'babyId': babyId,
            'expiresAt': expiresAtStr,
            'permissions': caregiverAccessMap?['permissions'] ?? data['permissions'] ?? {},
            'createdAt': DateTime.now().toIso8601String(),
            'baby': caregiverAccessMap?['baby'] ?? {
              'id': babyId,
              'name': 'Baby',
              'dateOfBirth': '2024-01-01',
              'gender': 'female',
            },
          };
          await cacheService.cacheCaregiverGrantedSession(sessionData);
          print('[DEBUG] Caregiver granted session cached persistently until: $expiresAtStr');
        }
      } catch (cacheErr) {
        print('[DEBUG] Failed to cache caregiver granted session: $cacheErr');
      }

      // Refresh auth state with active caregiver permission status from backend
      try {
        await ref.read(authNotifierProvider.notifier).verifyCaregiverActivePermissions(null, true);
      } catch (_) {}

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

      bool isAuthError = e.toString().contains('Access token required') ||
          e.toString().contains('401') ||
          e.toString().contains('Unauthorized') ||
          e.toString().contains('jwt') ||
          e.toString().contains('token');

      if (isAuthError) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString('pending_qr_join_data', jsonString);
      }

      bool isNetworkErr = e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('connectionError') ||
          e.toString().contains('500') ||
          e.toString().contains('502') ||
          e.toString().contains('503');

      String errMsg = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      final lowerErr = errMsg.toLowerCase();
      if (lowerErr.contains('used') || lowerErr.contains('invalid token')) {
        errMsg = 'Invitation Already Used.\n\nThis caregiver invitation has already been accepted or is no longer valid. Ask the parent for a new invitation.';
      } else if (lowerErr.contains('active caregiver') || lowerErr.contains('limit')) {
        errMsg = 'An Active Caregiver Already Exists.\n\nOnly one caregiver can have active access at a time. The parent must revoke existing access before adding a new caregiver.';
      } else if (isAuthError) {
        errMsg = 'Caregiver login is required to accept access.\n\nYour scanned invitation has been saved. Please log in to complete access.';
      } else if (e is FormatException) {
        errMsg = 'Invalid QR structure: ${e.message}\n\nPlease scan a valid MAATRIVA invite.';
      } else if (isNetworkErr) {
        errMsg = 'Backend server is offline or unreachable.\n\nMake sure the backend server is running on host PC (port 3000) and both devices are on the same Wi-Fi.\n\nIf your parent/host server IP has changed, tap "Set Server IP" below.';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(
                  isAuthError ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
                  color: isAuthError ? AppColors.primary : Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  isAuthError ? 'Login Required' : 'Scan Failed',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(child: Text(errMsg)),
            actions: [
              if (isNetworkErr)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showServerConfigDialog();
                  },
                  icon: const Icon(Icons.dns_rounded, size: 18),
                  label: const Text('Set Server IP'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  isAuthError ? 'Cancel' : 'Try Again',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              if (isAuthError)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Login First', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;

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
          onPressed: () {
            if (!isAuthenticated) {
              context.go('/login');
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_rounded, color: AppColors.primary),
            tooltip: 'Configure Server IP',
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text(
                isAuthenticated ? 'Scan Parent\'s QR Code' : 'Authorization Required',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                isAuthenticated
                    ? 'Point camera at the QR code displayed on the parent\'s screen.'
                    : 'Unauthorized persons cannot scan QR codes. Please log in or authorize your account first to scan.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            if (!isAuthenticated) ...[
              // Block scanner for unauthorized users
              Center(
                child: Container(
                  width: 300.r,
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: AppColors.softShadow,
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_person_rounded,
                          size: 48.r,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Please Authorize First',
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'You must be logged in and authorized before scanning the parent\'s QR code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                        label: const Text('Login First', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 48.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
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
                                      color: Colors.redAccent.withValues(alpha: 0.8),
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
                            color: Colors.black.withValues(alpha: 0.6),
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
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
