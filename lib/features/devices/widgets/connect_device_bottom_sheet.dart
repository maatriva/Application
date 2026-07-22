import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maatriva/core/theme/app_colors.dart';

class ConnectDeviceBottomSheet extends StatefulWidget {
  final Function(String deviceType) onDeviceAdded;

  const ConnectDeviceBottomSheet({super.key, required this.onDeviceAdded});

  @override
  State<ConnectDeviceBottomSheet> createState() =>
      _ConnectDeviceBottomSheetState();
}

class _ConnectDeviceBottomSheetState extends State<ConnectDeviceBottomSheet> {
  String _currentStep = 'menu'; // 'menu', 'qr', 'bluetooth', 'manual'
  bool _isConnecting = false;
  double _progress = 0.0;
  String _statusText = '';

  // Bluetooth scanning list
  final List<String> _bluetoothDevices = [
    'Maatriva Sound Soother V2',
    'Maatriva Diaper Wetness Clip',
    'Maatriva Smart Scale Plinth',
    'Maatriva Ambient Temp Beep',
  ];

  void _simulatePairing(String deviceType) async {
    setState(() {
      _isConnecting = true;
      _progress = 0.0;
      _statusText = 'Establishing secure handshake...';
    });

    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _progress = i * 0.2;
        if (i == 2) _statusText = 'Verifying cryptographic signature...';
        if (i == 4) _statusText = 'Synchronizing nursery database...';
      });
    }

    widget.onDeviceAdded(deviceType);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(child: Text('Successfully paired $deviceType!')),
            ],
          ),
          backgroundColor: AppColors.sleepText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pull handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFDCD6E5),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 18.h),

            // Dynamic flow based on step
            if (_isConnecting)
              _buildConnectingProgress()
            else if (_currentStep == 'menu')
              _buildMainMenu()
            else if (_currentStep == 'qr')
              _buildQRScanner()
            else if (_currentStep == 'bluetooth')
              _buildBluetoothScanner()
            else if (_currentStep == 'manual')
              _buildManualSetup(),
          ],
        ),
      ),
    );
  }

  // Step 1: Main options
  Widget _buildMainMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect New Device',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Choose your preferred provisioning mechanism.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 20.h),

        _buildMenuButton(
          title: 'Scan QR Code',
          description: 'Aim camera at QR printed on packaging',
          icon: Icons.qr_code_scanner_rounded,
          color: const Color(0xFF8143D1),
          bg: const Color(0xFFF3EDFA),
          onTap: () => setState(() => _currentStep = 'qr'),
        ),
        _buildMenuButton(
          title: 'Bluetooth Pairing',
          description: 'Discover nearby broadcasting modules',
          icon: Icons.bluetooth_searching_rounded,
          color: const Color(0xFF1866C5),
          bg: const Color(0xFFE5EFFB),
          onTap: () => setState(() => _currentStep = 'bluetooth'),
        ),
        _buildMenuButton(
          title: 'Manual Setup',
          description: 'Type module IP or select category key',
          icon: Icons.tune_rounded,
          color: const Color(0xFF128054),
          bg: const Color(0xFFE2F3EC),
          onTap: () => setState(() => _currentStep = 'manual'),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  // Step 2: QR Scanner simulation
  Widget _buildQRScanner() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              iconSize: 16.sp,
              onPressed: () => setState(() => _currentStep = 'menu'),
            ),
            Text(
              'QR Code Provisioning',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 32.w),
          ],
        ),
        SizedBox(height: 16.h),

        // Mock viewfinder
        Container(
          width: 180.r,
          height: 180.r,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating / Animated laser scan bar
              Positioned(
                top: 50.h,
                left: 10.w,
                right: 10.w,
                child: Container(
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.qr_code_2_rounded,
                size: 90.sp,
                color: AppColors.textPrimary.withOpacity(0.35),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Align QR inside the box to pair instantly.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 20.h),

        ElevatedButton(
          onPressed: () => _simulatePairing('Smart Sound Soother'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(
            'Simulate Successful Scan',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  // Step 3: Bluetooth Discoverer
  Widget _buildBluetoothScanner() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              iconSize: 16.sp,
              onPressed: () => setState(() => _currentStep = 'menu'),
            ),
            Text(
              'Bluetooth Discovery',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 32.w),
          ],
        ),
        SizedBox(height: 16.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12.r,
              height: 12.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Scanning for Maatriva hardware broadcast...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),

        // Discovered Devices list
        Container(
          constraints: BoxConstraints(maxHeight: 200.h),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _bluetoothDevices.length,
            separatorBuilder: (context, index) =>
                Container(height: 1, color: const Color(0xFFEFEAF5)),
            itemBuilder: (context, index) {
              final item = _bluetoothDevices[index];
              return ListTile(
                onTap: () => _simulatePairing(item),
                leading: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5EFFB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bluetooth_rounded,
                    color: Color(0xFF1866C5),
                  ),
                ),
                title: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 18.sp,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  // Step 4: Manual setup choice
  Widget _buildManualSetup() {
    final textController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              iconSize: 16.sp,
              onPressed: () => setState(() => _currentStep = 'menu'),
            ),
            Text(
              'Manual Association',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 32.w),
          ],
        ),
        SizedBox(height: 16.h),

        Text(
          'Select Device Category',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: 'Smart Diaper Sensor',
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 10.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Smart Diaper Sensor',
              child: Text('Smart Diaper Sensor'),
            ),
            DropdownMenuItem(
              value: 'Smart Bottle Warmer',
              child: Text('Smart Bottle Warmer'),
            ),
            DropdownMenuItem(
              value: 'Smart Ambient Soother',
              child: Text('Smart Ambient Soother'),
            ),
          ],
          onChanged: (val) {},
        ),
        SizedBox(height: 16.h),

        Text(
          'Nursery IP / Hostname Address',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: textController..text = '192.168.1.145',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 10.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: 24.h),

        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _simulatePairing('Smart Diaper Sensor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'Register Manually',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  // Interactive pairing progress panel
  Widget _buildConnectingProgress() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 32.r,
              height: 32.r,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 3,
                color: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
              ),
            ),
          ),
          SizedBox(height: 20.h),

          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Keep your phone near the hardware device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFF1EEF5), width: 1.2),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }
}
