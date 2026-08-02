import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/services/providers.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../../shared/models/user_session.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../profile/provider/profile_provider.dart';
import '../../../reports/provider/health_reports_provider.dart';
import '../../../devices/providers/device_provider.dart';
import '../../../onboarding/providers/onboarding_provider.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserSession? session;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.authenticated(UserSession session) =>
      AuthState(status: AuthStatus.authenticated, session: session);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);

  @override
  List<Object?> get props => [status, session, errorMessage];
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;
  final ProfileRepository _profileRepository;
  final Ref _ref;
  bool _isAuthInProgress = false;

  AuthNotifier({
    required AuthRepository authRepository,
    required SecureStorageService secureStorage,
    required ProfileRepository profileRepository,
    required Ref ref,
  })  : _authRepository = authRepository,
        _secureStorage = secureStorage,
        _profileRepository = profileRepository,
        _ref = ref,
        super(AuthState.initial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    if (!mounted) return;
    debugPrint('[AUTH] Running checkAuth startup session verification...');
    state = AuthState.loading();
    
    try {
      final loggedIn = await _authRepository.isUserLoggedIn();
      if (loggedIn) {
        final userId = await _secureStorage.getUserId() ?? '';
        final userRoleStr = await _secureStorage.getUserRole() ?? 'PARENT';
        final userRole = parseRole(userRoleStr);

        final session = UserSession(
          id: userId,
          email: '',
          role: userRole,
        );

        debugPrint('[AUTH] User session validated from storage: userId=$userId, role=${userRole.name}. State -> authenticated.');
        await _ref.read(onboardingProvider.notifier).completeOnboarding();
        if (mounted) {
          state = AuthState.authenticated(session);
        }

        _loadProfileInBackground();
      } else {
        debugPrint('[AUTH] No stored user session found. State -> unauthenticated.');
        if (mounted) {
          state = AuthState.unauthenticated();
        }
      }
    } catch (e, stack) {
      debugPrint('[AUTH] Error during checkAuth: $e\n$stack');
      try {
        await _secureStorage.clearSession();
      } catch (_) {}
      if (mounted) {
        state = AuthState.unauthenticated();
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (_isAuthInProgress || state.status == AuthStatus.loading) {
      debugPrint('[AUTH] Login call ignored: auth request already in progress.');
      return;
    }
    if (!mounted) return;

    _isAuthInProgress = true;
    state = AuthState.loading();
    debugPrint('[AUTH] Executing login request for: $email');

    try {
      final session = await _authRepository.login(email: email, password: password);
      final userSession = session.email.isEmpty ? session.copyWith(email: email) : session;
      debugPrint('[AUTH] Login successful! Session issued for userId=${userSession.id}, role=${userSession.role.name}.');
      
      if (mounted) {
        state = AuthState.authenticated(userSession);
        debugPrint('[AUTH] AuthState updated to authenticated. Navigating to Dashboard.');
      }

      // Existing user logging in: bypass onboarding directly to Dashboard
      await _ref.read(onboardingProvider.notifier).completeOnboarding();

      try {
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(profileProvider);
        _ref.invalidate(healthReportsProvider);
        _ref.invalidate(deviceProvider);
      } catch (_) {}

      _loadProfileInBackground();
    } on ApiException catch (e) {
      debugPrint('[AUTH] Login failed with ApiException: ${e.message} (status: ${e.statusCode})');
      if (mounted) {
        state = AuthState.error(e.message.isNotEmpty ? e.message : 'Invalid email or password.');
      }
    } catch (e, stack) {
      debugPrint('[AUTH] Unexpected error during login: $e\n$stack');
      if (mounted) {
        state = AuthState.error('Unable to connect to server. Please check your network connection.');
      }
    } finally {
      _isAuthInProgress = false;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'parent',
  }) async {
    if (_isAuthInProgress || state.status == AuthStatus.loading) {
      debugPrint('[AUTH] Register call ignored: auth request already in progress.');
      return;
    }
    if (!mounted) return;

    _isAuthInProgress = true;
    state = AuthState.loading();
    debugPrint('[AUTH] Executing register request for: $email, role=$role');

    try {
      final names = fullName.trim().split(' ');
      final firstName = names.isNotEmpty ? names.first : '';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final session = await _authRepository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );

      debugPrint('[AUTH] Registration successful! Session issued for userId=${session.id}.');
      if (mounted) {
        state = AuthState.authenticated(session);
        debugPrint('[AUTH] AuthState updated to authenticated. Navigation triggered.');
      }

      try {
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(profileProvider);
        _ref.invalidate(healthReportsProvider);
        _ref.invalidate(deviceProvider);
      } catch (_) {}

      _loadProfileInBackground();
    } on ApiException catch (e) {
      debugPrint('[AUTH] Registration failed with ApiException: ${e.message}');
      if (mounted) {
        state = AuthState.error(e.message.isNotEmpty ? e.message : 'Registration failed. Please try again.');
      }
    } catch (e, stack) {
      debugPrint('[AUTH] Unexpected error during registration: $e\n$stack');
      if (mounted) {
        state = AuthState.error('Unable to connect to server. Please check your network connection.');
      }
    } finally {
      _isAuthInProgress = false;
    }
  }

  void _loadProfileInBackground() {
    debugPrint('[PROFILE] Triggering background profile fetch...');
    _profileRepository.getProfile().then((profile) {
      debugPrint('[PROFILE] Background profile fetch completed successfully: parentName=${profile.parentName}');
    }).catchError((err) {
      debugPrint('[PROFILE] Background profile fetch non-fatal notice: $err');
    });
  }

  Future<void> logout() async {
    debugPrint('[AUTH] Logout initiated by user. Updating state to unauthenticated immediately.');

    // 1. Immediately update auth state to unauthenticated so GoRouter redirects instantly
    state = AuthState.unauthenticated();

    // 2. Invalidate memory providers
    try {
      _ref.invalidate(dashboardProvider);
      _ref.invalidate(profileProvider);
      _ref.invalidate(healthReportsProvider);
      _ref.invalidate(deviceProvider);
      _ref.invalidate(onboardingProvider);
    } catch (_) {}

    // 3. Dispatch network sign-out request and wipe local cache/tokens via repository
    try {
      await _authRepository.logout();
      debugPrint('[AUTH] Network logout request completed successfully.');
    } catch (e) {
      debugPrint('[AUTH] Non-fatal error during background repository logout: $e');
      try {
        await _secureStorage.clearSession();
      } catch (_) {}
    }
  }

  void clearError() {
    if (state.status == AuthStatus.error && mounted) {
      state = AuthState.unauthenticated();
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);

  return AuthNotifier(
    authRepository: authRepository,
    secureStorage: secureStorage,
    profileRepository: profileRepository,
    ref: ref,
  );
});
