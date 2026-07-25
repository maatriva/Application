import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/providers.dart';
import '../../../../domain/repositories/baby_repository.dart';
import '../../../../shared/models/baby_profile.dart';
import '../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/device_provider.dart';

class DevicePairingScreen extends ConsumerStatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  ConsumerState<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends ConsumerState<DevicePairingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  
  List<BabyProfile> _babies = [];
  BabyProfile? _selectedBaby;
  bool _loadingBabies = true;

  // Paired Device Details to show on Success
  String? _pairedDeviceName;
  String? _pairedDeviceId;
  String? _pairedFirmware;
  int? _pairedBattery;
  String? _pairedStatus;

  @override
  void initState() {
    super.initState();
    _loadBabies();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _loadBabies() async {
    try {
      final babyRepo = ref.read(babyRepositoryProvider);
      final list = await babyRepo.getBabies();
      setState(() {
        _babies = list;
        _loadingBabies = false;
        if (_babies.length == 1) {
          _selectedBaby = _babies.first;
        }
      });
    } catch (e) {
      setState(() {
        _loadingBabies = false;
        _errorMessage = 'Failed to load babies: ${e.toString()}';
      });
    }
  }

  Future<void> _pairDevice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBaby == null) {
      setState(() {
        _errorMessage = 'Please select a baby to assign the cradle to.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deviceNotifier = ref.read(deviceProvider.notifier);
      final devId = _deviceIdController.text.trim();

      // Execute pairing
      await deviceNotifier.pairNewDevice(
        deviceId: devId,
        deviceName: 'Maatriva Smart Cradle',
        type: 'Smart Cradle',
        babyId: _selectedBaby!.id,
      );

      // Successfully paired! Load details
      setState(() {
        _isSuccess = true;
        _pairedDeviceName = 'Maatriva Smart Cradle';
        _pairedDeviceId = devId;
        _pairedFirmware = 'v1.0.0';
        _pairedBattery = 100;
        _pairedStatus = 'Online';
      });

      // Refresh dashboard to map new device details
      await ref.read(dashboardProvider.notifier).refresh();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('ApiException:', '').trim();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _simulateQRScan() {
    setState(() {
      _deviceIdController.text = 'MTR-1784793241620';
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Device ID scanned successfully from QR!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
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
          'Pair Smart Cradle',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _loadingBabies
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: EdgeInsets.all(24.r),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isSuccess) ..._buildPairingForm() else _buildSuccessView(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _buildPairingForm() {
    return [
      Text(
        'Connect Your Smart Cradle',
        style: GoogleFonts.outfit(
          fontSize: 24.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      SizedBox(height: 6.h),
      Text(
        'Scan QR code or enter Device ID manually to pair.',
        style: TextStyle(
          fontSize: 12.sp,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: 24.h),

      if (_errorMessage != null) ...[
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 12.sp, color: Colors.red.shade800),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ],

      // Claymorphic QR scanner card
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 1.5),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 140.h,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.06)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 40.r, color: AppColors.primary.withOpacity(0.6)),
                  SizedBox(height: 10.h),
                  Text(
                    'Position QR code inside viewfinder',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.h),
                  TextButton.icon(
                    onPressed: _simulateQRScan,
                    icon: Icon(Icons.camera_alt_outlined, size: 14.r),
                    label: const Text('Scan QR Code'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.sp),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Manual Entry
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Device ID / Serial Number',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _deviceIdController,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              validator: (v) => v == null || v.trim().isEmpty ? 'Device ID is required.' : null,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                hintText: 'e.g. MTR-1784793241620',
                hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary.withOpacity(0.4)),
                prefixIcon: Icon(Icons.fingerprint_rounded, color: AppColors.primary.withOpacity(0.7), size: 18.r),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 20.h),

      // Baby Assignment Section
      Text(
        'Assign to Baby',
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
      ),
      SizedBox(height: 8.h),
      if (_babies.isEmpty)
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: const Text('No baby registered. Please register a baby in profile settings first.'),
        )
      else
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primary.withOpacity(0.08)),
            boxShadow: AppColors.softShadow,
          ),
          child: DropdownButtonFormField<BabyProfile>(
            value: _selectedBaby,
            hint: const Text('Select Baby'),
            decoration: const InputDecoration(border: InputBorder.none),
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            items: _babies.map((b) {
              return DropdownMenuItem<BabyProfile>(
                value: b,
                child: Text(b.name),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedBaby = val;
              });
            },
          ),
        ),
      SizedBox(height: 36.h),

      ElevatedButton(
        onPressed: _isLoading ? null : _pairDevice,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size(double.infinity, 56.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text('Pair Smart Cradle', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
      ),
    ];
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F3EC),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, color: const Color(0xFF128054), size: 48.r),
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          'Device Paired Successfully!',
          style: GoogleFonts.outfit(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          'Your Smart Cradle is now bound to ${_selectedBaby?.name ?? 'your baby'} and actively ingesting telemetry.',
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30.h),

        // Device Details Card
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: AppColors.primary.withOpacity(0.08)),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Details',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Divider(height: 24, color: Color(0xFFEFEAF5)),
              _buildDetailRow('Device Name', _pairedDeviceName ?? 'N/A'),
              _buildDetailRow('Device ID', _pairedDeviceId ?? 'N/A'),
              _buildDetailRow('Firmware Version', _pairedFirmware ?? '1.0.0'),
              _buildDetailRow('Hardware Version', 'V1.0'),
              _buildDetailRow('Battery Status', _pairedBattery != null ? '$_pairedBattery%' : 'Plugged in'),
              _buildDetailRow('Device Status', _pairedStatus ?? 'Online', isStatus: true),
              _buildDetailRow('Last Connected', 'Just now'),
            ],
          ),
        ),
        SizedBox(height: 40.h),

        ElevatedButton(
          onPressed: () => context.go('/'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
          ),
          child: Text('Go to Dashboard', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          if (isStatus)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F3EC),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                value,
                style: TextStyle(fontSize: 10.sp, color: const Color(0xFF128054), fontWeight: FontWeight.bold),
              ),
            )
          else
            Text(value, style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
