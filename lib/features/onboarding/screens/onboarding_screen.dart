import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/providers.dart';
import '../../profile/provider/profile_provider.dart';
import '../providers/onboarding_provider.dart';
import '../../dashboard/presentation/providers/dashboard_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isActionLoading = false;
  String? _formErrorMessage;

  // Step 1: Parent Profile Controllers
  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _parentNameController;
  final _parentPhoneController = TextEditingController();
  String _relationship = 'Mother'; // Mother, Father, Guardian, Other

  // Step 2: Baby Registration Controllers
  final _babyFormKey = GlobalKey<FormState>();
  final _babyNameController = TextEditingController();
  final _babyDobController = TextEditingController();
  DateTime? _selectedBabyDob;
  String _babyGender = 'Female'; // Female, Male, Other
  final _babyWeightController = TextEditingController();
  final _babyHeightController = TextEditingController();
  String? _babyBloodGroup; // A+, A-, B+, B-, AB+, AB-, O+, O-

  // Step 3: Device Pairing Controllers
  final _deviceFormKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Welcome to Maatriva',
      description:
          'Your premium, AI-powered smart baby monitoring system delivering real-time sleep, biometric, and ambient nursery insights.',
      icon: Icons.baby_changing_station_rounded,
      color: const Color(0xFF6E3DE0),
    ),
    OnboardingSlideData(
      title: 'Real-Time Telemetry',
      description:
          'Track heart rate, body temperature, room temperature, gas levels, and baby movement with absolute precision and safety.',
      icon: Icons.biotech_rounded,
      color: const Color(0xFF8143D1),
    ),
    OnboardingSlideData(
      title: 'AI Pediatric Advisor',
      description:
          'Get concise, expert, reassuring baby care insights and recommendations analyzed directly by the Gemini Pediatric Brain.',
      icon: Icons.psychology_rounded,
      color: const Color(0xFF1866C5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    // Pre-fill name if available from profile state
    _parentNameController = TextEditingController(text: profile.parentName);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _babyNameController.dispose();
    _babyDobController.dispose();
    _babyWeightController.dispose();
    _babyHeightController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  void _onNextSlide() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWelcome();
    }
  }

  Future<void> _completeWelcome() async {
    setState(() {
      _isActionLoading = true;
    });
    await ref.read(onboardingProvider.notifier).completeWelcome();
    setState(() {
      _isActionLoading = false;
    });
  }

  Future<void> _saveParentProfile() async {
    if (_profileFormKey.currentState!.validate()) {
      setState(() {
        _isActionLoading = true;
        _formErrorMessage = null;
      });

      try {
        ref.read(profileProvider.notifier).updateParentProfile(
              name: _parentNameController.text.trim(),
              email: ref.read(profileProvider).parentEmail.isEmpty
                  ? 'parent@example.com'
                  : ref.read(profileProvider).parentEmail,
              phone: _parentPhoneController.text.trim(),
              relationship: _relationship,
            );

        // Transition logic checking status
        await ref.read(onboardingProvider.notifier).checkOnboardingStatus();
      } catch (e) {
        setState(() {
          _formErrorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _saveBabyProfile() async {
    if (_babyFormKey.currentState!.validate()) {
      if (_selectedBabyDob == null) {
        setState(() {
          _formErrorMessage = 'Please select baby\'s date of birth.';
        });
        return;
      }

      setState(() {
        _isActionLoading = true;
        _formErrorMessage = null;
      });

      try {
        final babyRepo = ref.read(babyRepositoryProvider);
        final weight = double.tryParse(_babyWeightController.text.trim());
        final height = double.tryParse(_babyHeightController.text.trim());

        await babyRepo.createBaby(
          name: _babyNameController.text.trim(),
          birthDate: _selectedBabyDob!,
          gender: _babyGender,
          bloodGroup: _babyBloodGroup,
          birthWeight: weight,
          birthHeight: height,
        );

        // Refresh dashboard to load babies list
        await ref.read(dashboardProvider.notifier).refresh();

        // Check onboarding progress
        await ref.read(onboardingProvider.notifier).checkOnboardingStatus();
      } catch (e) {
        setState(() {
          _formErrorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _pairDevice() async {
    if (_deviceFormKey.currentState!.validate()) {
      setState(() {
        _isActionLoading = true;
        _formErrorMessage = null;
      });

      try {
        final deviceRepo = ref.read(deviceRepositoryProvider);
        final babyRepo = ref.read(babyRepositoryProvider);

        // Fetch registered baby ID to associate the device
        final babies = await babyRepo.getBabies();
        if (babies.isEmpty) {
          throw Exception('No baby registered. Complete baby setup first.');
        }
        final babyId = babies.first.id;

        await deviceRepo.pairDevice(
          deviceId: _deviceIdController.text.trim(),
          deviceName: 'Maatriva Smart Cradle',
          type: 'hub',
          babyId: babyId,
        );

        // Refresh dashboard state
        await ref.read(dashboardProvider.notifier).refresh();

        // Complete onboarding
        await ref.read(onboardingProvider.notifier).checkOnboardingStatus();
      } catch (e) {
        setState(() {
          _formErrorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  void _skipDevicePairing() {
    ref.read(onboardingProvider.notifier).skipDevicePairing();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);

    if (onboardingState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    switch (onboardingState.currentStep) {
      case OnboardingStep.welcome:
        return _buildWelcomeSlides();
      case OnboardingStep.profileSetup:
        return _buildProfileSetup();
      case OnboardingStep.babyRegister:
        return _buildBabyRegister();
      case OnboardingStep.devicePairing:
        return _buildDevicePairing();
      case OnboardingStep.completed:
        // Automatically handled by GoRouter redirect, but return placeholder just in case
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
    }
  }

  // --- WELCOME SLIDES WIDGET ---
  Widget _buildWelcomeSlides() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeWelcome,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 130.r,
                          height: 130.r,
                          decoration: BoxDecoration(
                            color: slide.color.withOpacity(0.08),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: slide.color.withOpacity(0.12),
                                blurRadius: 20,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: Icon(slide.icon, size: 56.r, color: slide.color),
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          slide.title,
                          style: AppTypography.displayHeader.copyWith(
                            fontSize: 24.sp,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          slide.description,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_slides.length, (index) {
                      final isSelected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: isSelected ? 20.w : 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      );
                    }),
                  ),
                  ElevatedButton(
                    onPressed: _currentPage == _slides.length - 1 && _isActionLoading
                        ? null
                        : _onNextSlide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 14.h,
                      ),
                    ),
                    child: _isActionLoading
                        ? SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _currentPage == _slides.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 1: PARENT PROFILE SCREEN ---
  Widget _buildProfileSetup() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _profileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                Text(
                  'Parent Profile Setup',
                  style: GoogleFonts.outfit(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Let\'s build your profile to associate with your infant cradle.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 28.h),

                // Error Message block
                if (_formErrorMessage != null) ...[
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
                            _formErrorMessage!,
                            style: TextStyle(fontSize: 12.sp, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],

                // Claymorphic Card container
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                      width: 1.5,
                    ),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Placeholder
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 46.r,
                              backgroundColor: AppColors.primary.withOpacity(0.06),
                              child: Icon(Icons.person_outline_rounded, size: 40.r, color: AppColors.primary),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14.r),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Full Name
                      _buildLabel('Full Name'),
                      TextFormField(
                        controller: _parentNameController,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        validator: (v) => v == null || v.isEmpty ? 'Full name is required.' : null,
                        decoration: _buildInputDecoration(Icons.person_outline, 'Enter your full name'),
                      ),
                      SizedBox(height: 18.h),

                      // Phone Number
                      _buildLabel('Phone Number'),
                      TextFormField(
                        controller: _parentPhoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        validator: (v) => v == null || v.isEmpty ? 'Phone number is required.' : null,
                        decoration: _buildInputDecoration(Icons.phone_outlined, 'Enter phone number'),
                      ),
                      SizedBox(height: 18.h),

                      // Relationship Dropdown
                      _buildLabel('Relationship to Baby'),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _relationship,
                          decoration: const InputDecoration(border: InputBorder.none),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          items: ['Mother', 'Father', 'Guardian', 'Other'].map((role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _relationship = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 36.h),

                // Save Profile Button
                ElevatedButton(
                  onPressed: _isActionLoading ? null : _saveParentProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: _isActionLoading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Continue',
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

  // --- STEP 2: BABY REGISTRATION SCREEN ---
  Widget _buildBabyRegister() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _babyFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                Text(
                  'Register Your Baby',
                  style: GoogleFonts.outfit(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Enter details of the infant to receive tailored pediatric recommendations.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 24.h),

                // Error Message block
                if (_formErrorMessage != null) ...[
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
                            _formErrorMessage!,
                            style: TextStyle(fontSize: 12.sp, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],

                // Claymorphic Registration Card
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                      width: 1.5,
                    ),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 42.r,
                              backgroundColor: AppColors.primary.withOpacity(0.06),
                              child: Icon(Icons.child_care_rounded, size: 40.r, color: AppColors.primary),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 13.r),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Baby Name
                      _buildLabel('Baby\'s Name'),
                      TextFormField(
                        controller: _babyNameController,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        validator: (v) => v == null || v.isEmpty ? 'Baby\'s name is required.' : null,
                        decoration: _buildInputDecoration(Icons.badge_outlined, 'Enter baby\'s name'),
                      ),
                      SizedBox(height: 16.h),

                      // Date of Birth Pick
                      _buildLabel('Date of Birth'),
                      TextFormField(
                        controller: _babyDobController,
                        readOnly: true,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.white,
                                    onSurface: AppColors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (selected != null) {
                            setState(() {
                              _selectedBabyDob = selected;
                              _babyDobController.text =
                                  '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        decoration: _buildInputDecoration(Icons.calendar_month_outlined, 'Select Date of Birth'),
                      ),
                      SizedBox(height: 16.h),

                      // Gender & Blood Group Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Gender'),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _babyGender,
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    items: ['Female', 'Male', 'Other'].map((g) {
                                      return DropdownMenuItem<String>(
                                        value: g,
                                        child: Text(g),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _babyGender = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Blood Group (Optional)'),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _babyBloodGroup,
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    hint: const Text('Select'),
                                    items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((bg) {
                                      return DropdownMenuItem<String>(
                                        value: bg,
                                        child: Text(bg),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _babyBloodGroup = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Weight & Height Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Birth Weight (kg)'),
                                TextFormField(
                                  controller: _babyWeightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                                  decoration: _buildInputDecoration(Icons.monitor_weight_outlined, 'e.g. 3.2'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Birth Height (cm)'),
                                TextFormField(
                                  controller: _babyHeightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                                  decoration: _buildInputDecoration(Icons.height_rounded, 'e.g. 50'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // Submit Baby Info
                ElevatedButton(
                  onPressed: _isActionLoading ? null : _saveBabyProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: _isActionLoading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Register Baby & Continue',
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

  // --- STEP 3: DEVICE PAIRING SCREEN ---
  Widget _buildDevicePairing() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _deviceFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                Text(
                  'Pair Smart Cradle',
                  style: GoogleFonts.outfit(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Pair your Maatriva Smart Cradle to ingest real-time sleep and health telemetry.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 28.h),

                // Error message block
                if (_formErrorMessage != null) ...[
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
                            _formErrorMessage!,
                            style: TextStyle(fontSize: 12.sp, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],

                // Claymorphic Card block
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                      width: 1.5,
                    ),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Camera QR Placeholder visual
                      Center(
                        child: Container(
                          width: double.infinity,
                          height: 170.h,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, size: 48.r, color: AppColors.primary.withOpacity(0.5)),
                              SizedBox(height: 12.h),
                              Text(
                                'Scan QR code on the bottom of device',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              TextButton.icon(
                                onPressed: () {
                                  // Mock scan sets default cradle serial
                                  setState(() {
                                    _deviceIdController.text = 'MTR-1784793241620';
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Mock QR Scan Successful!'),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.photo_camera_back_outlined, size: 16.r),
                                label: const Text('Simulate Scan QR'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Device ID input
                      _buildLabel('Device ID / Serial Number'),
                      TextFormField(
                        controller: _deviceIdController,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        validator: (v) => v == null || v.isEmpty ? 'Device ID is required to pair.' : null,
                        decoration: _buildInputDecoration(Icons.fingerprint_rounded, 'e.g. MTR-XXXXXXXXXXXXX'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 36.h),

                // Pair Device Action button
                ElevatedButton(
                  onPressed: _isActionLoading ? null : _pairDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: _isActionLoading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Pair Device',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                SizedBox(height: 16.h),

                // Skip button
                TextButton(
                  onPressed: _skipDevicePairing,
                  style: TextButton.styleFrom(
                    minimumSize: Size(double.infinity, 44.h),
                  ),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
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

  // --- REUSABLE CARD DECORATION HELPERS ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(IconData icon, String hint) {
    return InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 14.h,
      ),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 20.r),
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
        color: Colors.redAccent,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class OnboardingSlideData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
