import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import '../../provider/profile_provider.dart';

class ParentDetailsScreen extends ConsumerStatefulWidget {
  const ParentDetailsScreen({super.key});

  @override
  ConsumerState<ParentDetailsScreen> createState() =>
      _ParentDetailsScreenState();
}

class _ParentDetailsScreenState extends ConsumerState<ParentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _partnerNameController;
  late TextEditingController _partnerPhoneController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _partnerNameController = TextEditingController(text: profile.partnerName);
    _partnerPhoneController = TextEditingController(text: profile.partnerPhone);
    _emergencyNameController = TextEditingController(
      text: profile.emergencyContactName,
    );
    _emergencyPhoneController = TextEditingController(
      text: profile.emergencyContactPhone,
    );
  }

  @override
  void dispose() {
    _partnerNameController.dispose();
    _partnerPhoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
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
          'Parent & Partner Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Partner Section
                Text(
                  'Partner Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.04),
                      width: 1.5,
                    ),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _partnerNameController,
                        label: 'Partner Name',
                        icon: Icons.person_add_alt_1_rounded,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Partner name required'
                            : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _partnerPhoneController,
                        label: 'Partner Phone',
                        icon: Icons.phone_enabled_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Partner phone required'
                            : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28.h),

                // Emergency Contact Section
                Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.04),
                      width: 1.5,
                    ),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _emergencyNameController,
                        label: 'Contact Name (e.g. Grandma, Uncle)',
                        icon: Icons.star_border_rounded,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Emergency contact name required'
                            : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _emergencyPhoneController,
                        label: 'Emergency Phone Number',
                        icon: Icons.emergency_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Emergency phone required'
                            : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h),

                // Save button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ref
                          .read(profileProvider.notifier)
                          .updatePartnerDetails(
                            partnerName: _partnerNameController.text.trim(),
                            partnerPhone: _partnerPhoneController.text.trim(),
                            emergencyName: _emergencyNameController.text.trim(),
                            emergencyPhone: _emergencyPhoneController.text
                                .trim(),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Partner & Emergency contacts updated!',
                          ),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                      context.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: Text(
                    'Save Information',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20.r),
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
            errorStyle: TextStyle(fontSize: 11.sp, color: Colors.redAccent),
          ),
        ),
      ],
    );
  }
}
