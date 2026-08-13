import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../../../onboarding/providers/onboarding_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String _selectedRole = 'parent'; // 'parent' or 'caregiver'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    final isAuthLoading = ref.read(authNotifierProvider).status == AuthStatus.loading;
    final isOnboardingLoading = ref.read(onboardingProvider).isLoading;
    if (_isSubmitting || isAuthLoading || isOnboardingLoading) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      FocusScope.of(context).unfocus();

      try {
        await ref.read(authNotifierProvider.notifier).register(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
              role: _selectedRole,
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
      backgroundColor: AppColors.background, // Light Aqua Canvas (0xFFEBF7F8)
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 8.h),

              // =================================================================
              // 1. BRANDING HEADER (Logo + MAATRIVA)
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
              // 2. MAIN CLAYMORPHIC CARD FOR CREATE ACCOUNT FORM
              // =================================================================
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
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
                        'Create Your Account',
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Create your Maatriva account and start caring smarter.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Full Name Field
                      _buildFieldLabel('Full Name'),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        enabled: !isLoading,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required.';
                          }
                          return null;
                        },
                        decoration: _buildInputDecoration(
                          hintText: 'Your full name',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),

                      SizedBox(height: 14.h),

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
                          hintText: 'Your email address',
                          icon: Icons.email_outlined,
                        ),
                      ),

                      SizedBox(height: 14.h),

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
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters.';
                          }
                          return null;
                        },
                        decoration: _buildInputDecoration(
                          hintText: 'Password (min 8 characters)',
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

                      SizedBox(height: 14.h),

                      // Confirm Password Field
                      _buildFieldLabel('Confirm Password'),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        enabled: !isLoading,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                        decoration: _buildInputDecoration(
                          hintText: 'Confirm password',
                          icon: Icons.lock_reset_rounded,
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            child: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                              size: 20.r,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // =======================================================
                      // 3. PROMINENT ACCOUNT TYPE SELECTOR ("I am signing up as")
                      // =======================================================
                      Text(
                        'I am signing up as',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      Row(
                        children: [
                          // Parent Card
                          Expanded(
                            child: _buildRoleCard(
                              roleKey: 'parent',
                              title: 'Parent',
                              emoji: '👨‍👩‍👧',
                              description: 'Manage your baby\'s care & devices',
                              isSelected: _selectedRole == 'parent',
                              onTap: isLoading ? null : () => setState(() => _selectedRole = 'parent'),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Caregiver Card
                          Expanded(
                            child: _buildRoleCard(
                              roleKey: 'caregiver',
                              title: 'Caregiver',
                              emoji: '🤝',
                              description: 'Access a baby\'s care by invitation',
                              isSelected: _selectedRole == 'caregiver',
                              onTap: isLoading ? null : () => setState(() => _selectedRole = 'caregiver'),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // =======================================================
                      // 4. SIGN UP BUTTON
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
                          onPressed: isLoading ? null : _onRegister,
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
                                      'Creating account...',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Create Account',
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
              // 5. LOGIN NAVIGATION LINK
              // =================================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading ? null : () => context.go(AppRoutes.login),
                    child: Text(
                      'Login',
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

  Widget _buildRoleCard({
    required String roleKey,
    required String title,
    required String emoji,
    required String description,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppColors.softShadow,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: 24.sp),
                ),
                SizedBox(height: 6.h),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    height: 1.2,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(3.r),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 10.r,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
