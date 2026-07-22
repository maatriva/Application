import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:maatriva/core/theme/app_colors.dart';
import 'package:maatriva/features/profile/provider/profile_provider.dart';

class BabyDetailsScreen extends ConsumerStatefulWidget {
  const BabyDetailsScreen({super.key});

  @override
  ConsumerState<BabyDetailsScreen> createState() => _BabyDetailsScreenState();
}

class _BabyDetailsScreenState extends ConsumerState<BabyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late double _weight;
  late double _height;
  late String _gender;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.babyName);
    _dobController = TextEditingController(text: profile.babyDob);
    _weight = profile.babyWeight;
    _height = profile.babyHeight;
    _gender = profile.babyGender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Baby's Profile Details",
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Baby Avatar Section
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3.r,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54.r,
                        backgroundImage: NetworkImage(profile.babyAvatar),
                        backgroundColor: AppColors.primaryLight,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5.r),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 16.r,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),

                // Card wrapping fields
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baby Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Baby Name',
                        icon: Icons.child_care_rounded,
                        validator: (value) => value == null || value.isEmpty
                            ? "Please enter your baby's name"
                            : null,
                      ),
                      SizedBox(height: 20.h),

                      // Date of Birth
                      _buildTextField(
                        controller: _dobController,
                        label: 'Date of Birth',
                        icon: Icons.calendar_month_outlined,
                        validator: (value) => value == null || value.isEmpty
                            ? "Please enter birth date"
                            : null,
                      ),
                      SizedBox(height: 20.h),

                      // Gender Selector
                      Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGenderButton(
                              'Female',
                              Icons.female_rounded,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildGenderButton(
                              'Male',
                              Icons.male_rounded,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // Weight Counter
                      _buildMetricStepper(
                        label: 'Current Weight',
                        value: _weight,
                        unit: 'kg',
                        onIncrement: () => setState(
                          () => _weight = double.parse(
                            (_weight + 0.1).toStringAsFixed(1),
                          ),
                        ),
                        onDecrement: () {
                          if (_weight > 1.0) {
                            setState(
                              () => _weight = double.parse(
                                (_weight - 0.1).toStringAsFixed(1),
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: 20.h),

                      // Height Counter
                      _buildMetricStepper(
                        label: 'Current Height',
                        value: _height,
                        unit: 'cm',
                        onIncrement: () => setState(
                          () => _height = double.parse(
                            (_height + 0.5).toStringAsFixed(1),
                          ),
                        ),
                        onDecrement: () {
                          if (_height > 10.0) {
                            setState(
                              () => _height = double.parse(
                                (_height - 0.5).toStringAsFixed(1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 36.h),

                // Save button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ref
                          .read(profileProvider.notifier)
                          .updateBabyDetails(
                            name: _nameController.text.trim(),
                            dob: _dobController.text.trim(),
                            gender: _gender,
                            weight: _weight,
                            height: _height,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "${_nameController.text.trim()}'s profile updated successfully!",
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
                    'Save Baby Profile',
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

  Widget _buildGenderButton(String gender, IconData icon) {
    final isSelected = _gender == gender;
    final color = gender == 'Female' ? Colors.pink : Colors.blue;

    return GestureDetector(
      onTap: () => setState(() => _gender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 20.r,
            ),
            SizedBox(width: 8.w),
            Text(
              gender,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricStepper({
    required String label,
    required double value,
    required String unit,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
            SizedBox(height: 4.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildStepButton(Icons.remove_rounded, onDecrement),
            SizedBox(width: 12.w),
            _buildStepButton(Icons.add_rounded, onIncrement),
          ],
        ),
      ],
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.08)),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18.r),
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
