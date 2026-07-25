import 'package:equatable/equatable.dart';
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
    state = AuthState.loading();
    bool authenticated = false;
    UserSession? session;
    
    try {
      final loggedIn = await _authRepository.isUserLoggedIn();
      if (loggedIn) {
        final profile = await _profileRepository.getProfile();
        final userId = await _secureStorage.getUserId() ?? '';
        final userRoleStr = await _secureStorage.getUserRole() ?? 'PARENT';
        final userRole = parseRole(userRoleStr.toLowerCase());

        session = UserSession(
          id: userId,
          email: profile.parentEmail,
          role: userRole,
        );
        authenticated = true;
      }
    } catch (e) {
      try {
        await _secureStorage.clearSession();
      } catch (_) {}
    } finally {
      if (mounted) {
        if (authenticated && session != null) {
          state = AuthState.authenticated(session);
        } else {
          state = AuthState.unauthenticated();
        }
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (_isAuthInProgress || state.status == AuthStatus.loading) return;
    if (!mounted) return;

    _isAuthInProgress = true;
    state = AuthState.loading();
    bool success = false;
    UserSession? session;
    String? errMessage;

    try {
      session = await _authRepository.login(email: email, password: password);
      await _profileRepository.getProfile();
      success = true;
    } on ApiException catch (e) {
      errMessage = e.message;
    } catch (e) {
      errMessage = 'Connection failed. Please check your internet.';
    } finally {
      _isAuthInProgress = false;
      if (mounted) {
        if (success && session != null) {
          state = AuthState.authenticated(session);
        } else {
          state = AuthState.error(errMessage ?? 'An unknown error occurred.');
        }
      }
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (_isAuthInProgress || state.status == AuthStatus.loading) return;
    if (!mounted) return;

    _isAuthInProgress = true;
    state = AuthState.loading();
    bool success = false;
    UserSession? session;
    String? errMessage;

    try {
      final names = fullName.trim().split(' ');
      final firstName = names.isNotEmpty ? names.first : '';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      session = await _authRepository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: 'parent',
      );

      await _profileRepository.getProfile();
      success = true;
    } on ApiException catch (e, stack) {
      print('AuthProvider.register ApiException caught: $e');
      print(stack);
      errMessage = e.message;
    } catch (e, stack) {
      print('AuthProvider.register generic exception caught: $e');
      print(stack);
      errMessage = 'Connection failed. Please check your internet. Error: $e';
    } finally {
      _isAuthInProgress = false;
      if (mounted) {
        if (success && session != null) {
          state = AuthState.authenticated(session);
        } else {
          state = AuthState.error(errMessage ?? 'An unknown error occurred.');
        }
      }
    }
  }

  Future<void> logout() async {
    if (!mounted) return;
    state = AuthState.loading();
    try {
      await _authRepository.logout();
    } catch (_) {
    } finally {
      // Invalidate memory states of other logged-in user providers
      try {
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(profileProvider);
        _ref.invalidate(healthReportsProvider);
        _ref.invalidate(deviceProvider);
        _ref.invalidate(onboardingProvider);
      } catch (_) {}

      if (mounted) {
        state = AuthState.unauthenticated();
      }
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
