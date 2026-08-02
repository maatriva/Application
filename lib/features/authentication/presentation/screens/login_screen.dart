import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/services/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../../../onboarding/providers/onboarding_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.dns_rounded, color: AppColors.primary, size: 24.r),
            SizedBox(width: 8.w),
            Text('Server IP / URL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Base URL:\n${ApiConfig.baseUrl}',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            SizedBox(height: 12.h),
            Text(
              'Enter your server IP address (e.g. http://10.63.127.227:3000):',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'http://10.63.127.227:3000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
              if (context.mounted && dialogCtx.mounted) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                final prefs = ref.read(sharedPreferencesProvider);
                await prefs.setString('custom_base_url', newUrl);
                ApiConfig.setCustomBaseUrl(newUrl);
                if (context.mounted && dialogCtx.mounted) {
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

  void _onLogin() async {
    final isAuthLoading = ref.read(authNotifierProvider).status == AuthStatus.loading;
    final isOnboardingLoading = ref.read(onboardingProvider).isLoading;
    if (_isSubmitting || isAuthLoading || isOnboardingLoading) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      // Hide keyboard
      FocusScope.of(context).unfocus();
      
      try {
        await ref.read(authNotifierProvider.notifier).login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final onboardingState = ref.watch(onboardingProvider);
    final isLoading = _isSubmitting ||
                     authState.status == AuthStatus.loading ||
                     (authState.status == AuthStatus.authenticated && onboardingState.isLoading);

    // Listen for authentication errors and display them in a premium SnackBar
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white, size: 24.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    next.errorMessage!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => _showServerConfigDialog(context),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dns_rounded, size: 14.r, color: AppColors.primary),
                        SizedBox(width: 6.w),
                        Text(
                          'Server IP',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              
              // Celestial Branding Header
              Container(
                width: 76.r,
                height: 76.r,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.softShadow,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.06),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.child_care_rounded,
                  color: AppColors.primary,
                  size: 38.r,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'MAATRIVA',
                style: GoogleFonts.outfit(
                  textStyle: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'AI-POWERED SMART BABY MONITOR',
                style: GoogleFonts.outfit(
                  textStyle: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              
              SizedBox(height: 36.h),

              // Celestial Claymorphism Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.08),
                    width: 1.5,
                  ),
                  boxShadow: AppColors.softShadow,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Sign in to continue monitoring',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Email Field
                      Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required.';
                          }
                          final emailRegExp = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegExp.hasMatch(value.trim())) {
                            return 'Invalid email format.';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.primary.withOpacity(0.7),
                            size: 20.r,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          errorStyle: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Password Field
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !isLoading,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required.';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outlined,
                            color: AppColors.primary.withOpacity(0.7),
                            size: 20.r,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary.withOpacity(0.7),
                              size: 20.r,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          errorStyle: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Forgot Password Button (Disabled)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: null, // Disabled
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                          ),
                          child: Text(
                            'Forgot Password? (Disabled)',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 12.h),

                      // Submit Login Button
                      ElevatedButton(
                        onPressed: isLoading ? null : _onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: Size(double.infinity, 52.h),
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26.r),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Placeholder Social Logins
              Text(
                'or continue with',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Social Login Google Placeholder (Disabled)
                  Container(
                    width: 50.r,
                    height: 50.r,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                    child: Opacity(
                      opacity: 0.4,
                      child: Icon(
                        Icons.g_mobiledata_rounded,
                        color: AppColors.textPrimary,
                        size: 32.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Social Login Apple Placeholder (Disabled)
                  Container(
                    width: 50.r,
                    height: 50.r,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                    child: Opacity(
                      opacity: 0.4,
                      child: Icon(
                        Icons.apple_rounded,
                        color: AppColors.textPrimary,
                        size: 24.r,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Navigate to Register Option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => context.go(AppRoutes.register),
                    child: Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => context.push(AppRoutes.joinSharedBaby),
                icon: Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 18.r),
                label: Text(
                  'Join Shared Baby (Caregiver QR)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13.sp,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
