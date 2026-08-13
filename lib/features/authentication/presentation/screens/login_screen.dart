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

    // Listen for authentication errors and display in SnackBar
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
      backgroundColor: AppColors.background, // Soft Light Aqua Canvas (0xFFEBF7F8)
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Server IP Config Button
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
                          style: GoogleFonts.plusJakartaSans(
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

              SizedBox(height: 6.h),

              // =================================================================
              // 1. BRANDING HEADER (Logo + Title)
              // =================================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52.r,
                    height: 52.r,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.softShadow,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.child_care_rounded,
                      color: AppColors.primary,
                      size: 30.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MAATRIVA',
                        style: GoogleFonts.outfit(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Smart Care. Peaceful Moments.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // =================================================================
              // 2. MAIN CLAYMORPHIC CARD FOR LOGIN FORM
              // =================================================================
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                  boxShadow: AppColors.clayShadow,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Title & Subtitle
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.outfit(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Login to continue caring for your little one. 💜',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Email Field
                      _buildFieldLabel('Email Address'),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        style: GoogleFonts.plusJakartaSans(
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
                        decoration: _buildInputDecoration(
                          hintText: 'Enter your email',
                          icon: Icons.email_outlined,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Password Field
                      _buildFieldLabel('Password'),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !isLoading,
                        style: GoogleFonts.plusJakartaSans(
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
                        decoration: _buildInputDecoration(
                          hintText: 'Enter your password',
                          icon: Icons.lock_outlined,
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
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                              size: 20.r,
                            ),
                          ),
                        ),
                      ),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please contact your administrator to reset password.'),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // =======================================================
                      // 3. LOGIN BUTTON
                      // =======================================================
                      Container(
                        width: double.infinity,
                        height: 52.h,
                        decoration: BoxDecoration(
                          gradient: isLoading ? null : AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(26.r),
                          boxShadow: isLoading
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26.r),
                            ),
                            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          child: isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18.r,
                                      height: 18.r,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      'Logging in...',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Login',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // =================================================================
              // 4. SOCIAL LOGIN / CAREGIVER SCANNER OPTIONS
              // =================================================================
              Text(
                'or continue with',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: 14.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google Social Pill
                  _buildSocialPill(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Google',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Google Sign-In is managed via your account email.')),
                      );
                    },
                  ),
                  SizedBox(width: 12.w),
                  // Apple Social Pill
                  _buildSocialPill(
                    icon: Icons.apple_rounded,
                    label: 'Apple',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Apple Sign-In is managed via your account email.')),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // =================================================================
              // 5. SIGNUP NAVIGATION LINK
              // =================================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading ? null : () => context.go(AppRoutes.register),
                    child: Text(
                      'Create Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 13.h,
      ),
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13.sp,
        color: AppColors.textMuted,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.primary.withValues(alpha: 0.7),
        size: 20.r,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      errorStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11.sp,
        color: Colors.red,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSocialPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1.2,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20.r, color: AppColors.textPrimary),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
