import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
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
import '../../../music/providers/music_provider.dart';
import '../../../caregivers/provider/caregiver_access_provider.dart';

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
        final userEmail = await _secureStorage.getUserEmail() ?? '';
        final userRole = parseRole(userRoleStr);

        final session = UserSession(
          id: userId,
          email: userEmail,
          role: userRole,
        );

        bool hasActiveCaregiverPerm = false;
        if (userRole == UserRole.caregiver) {
          hasActiveCaregiverPerm = await verifyCaregiverActivePermissions(session);
        }

        final finalSession = session.copyWith(hasActiveCaregiverPermission: hasActiveCaregiverPerm);
        debugPrint('[AUTH] User session validated from storage: userId=$userId, role=${userRole.name}, hasActivePerm=$hasActiveCaregiverPerm. State -> authenticated.');
        await _ref.read(onboardingProvider.notifier).completeOnboarding();
        if (mounted) {
          state = AuthState.authenticated(finalSession);
        }

        if (userRole == UserRole.caregiver) {
          _startCaregiverRevocationCheckTimer();
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
      
      bool hasActiveCaregiverPerm = false;
      if (userSession.role == UserRole.caregiver) {
        hasActiveCaregiverPerm = await verifyCaregiverActivePermissions(userSession);
      }

      final finalSession = userSession.copyWith(hasActiveCaregiverPermission: hasActiveCaregiverPerm);

      try {
        final cache = _ref.read(cacheServiceProvider);
        final existingGrantedSession = cache.getCaregiverGrantedSession();
        await cache.clearCache();
        
        // Preserve active caregiver session if time is remaining
        if (existingGrantedSession != null) {
          final expiresAtStr = existingGrantedSession['expiresAt'] as String?;
          if (expiresAtStr != null) {
            final expiresAt = DateTime.tryParse(expiresAtStr);
            if (expiresAt != null && DateTime.now().isBefore(expiresAt)) {
              await cache.cacheCaregiverGrantedSession(existingGrantedSession);
              debugPrint('[AUTH] Preserved valid caregiver granted session during login (expiresAt: $expiresAtStr)');
            }
          } else {
            await cache.cacheCaregiverGrantedSession(existingGrantedSession);
          }
        }

        _ref.invalidate(dashboardProvider);
        _ref.invalidate(profileProvider);
        _ref.invalidate(healthReportsProvider);
        _ref.invalidate(deviceProvider);
        _ref.invalidate(musicProvider);
        _ref.invalidate(caregiverAccessProvider);
      } catch (_) {}

      // Existing user logging in: bypass onboarding directly to Dashboard
      await _ref.read(onboardingProvider.notifier).completeOnboarding();

      if (mounted) {
        state = AuthState.authenticated(finalSession);
        debugPrint('[AUTH] AuthState updated to authenticated (hasActiveCaregiverPermission=$hasActiveCaregiverPerm). Navigating to Dashboard.');
      }

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
        final cache = _ref.read(cacheServiceProvider);
        await cache.clearCache();
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(profileProvider);
        _ref.invalidate(healthReportsProvider);
        _ref.invalidate(deviceProvider);
        _ref.invalidate(musicProvider);
        _ref.invalidate(caregiverAccessProvider);
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

  DateTime? _lastCaregiverCheckTime;
  bool? _lastCaregiverCheckResult;
  bool _isCheckingCaregiverPerms = false;

  Future<bool> verifyCaregiverActivePermissions([UserSession? sessionParam, bool force = false]) async {
    final currentRole = sessionParam?.role ?? state.session?.role;
    if (currentRole != UserRole.caregiver) return true;

    final now = DateTime.now();
    if (!force &&
        _lastCaregiverCheckTime != null &&
        _lastCaregiverCheckResult != null &&
        now.difference(_lastCaregiverCheckTime!).inSeconds < 5) {
      debugPrint('[Caregiver] Throttling active permissions check (last checked ${now.difference(_lastCaregiverCheckTime!).inSeconds}s ago). Returning cached result: $_lastCaregiverCheckResult.');
      return _lastCaregiverCheckResult!;
    }

    if (_isCheckingCaregiverPerms) {
      debugPrint('[Caregiver] Active permissions check already in progress. Waiting...');
      return _lastCaregiverCheckResult ?? false;
    }

    _isCheckingCaregiverPerms = true;
    debugPrint('[Caregiver] Checking active permissions...');
    try {
      final caregiverRepo = _ref.read(caregiverRepositoryProvider);
      final accessRes = await caregiverRepo.getCaregiverAccess();

      final cache = _ref.read(cacheServiceProvider);
      final cachedSession = cache.getCaregiverGrantedSession();
      bool isCachedValid = false;
      if (cachedSession != null) {
        final expiresAtStr = cachedSession['expiresAt'] as String?;
        if (expiresAtStr != null) {
          final expiresAt = DateTime.tryParse(expiresAtStr);
          if (expiresAt != null && DateTime.now().isBefore(expiresAt)) {
            isCachedValid = true;
          }
        } else {
          isCachedValid = true;
        }
      }

      bool hasActive = false;
      if (accessRes != null) {
        // Server responded — server status ALWAYS overrides cached session!
        final serverHasAccess = accessRes['hasAccess'] == true;
        final serverStatus = (accessRes['status'] as String?) ??
            (accessRes['data']?['status'] as String?);
        final isRevoked = serverStatus == 'disabled' || serverStatus == 'revoked';

        hasActive = serverHasAccess && !isRevoked;
      } else {
        // Server unreachable / offline fallback — check if cached session has time remaining
        hasActive = isCachedValid;
      }

      _lastCaregiverCheckTime = DateTime.now();
      _lastCaregiverCheckResult = hasActive;

      if (hasActive) {
        debugPrint('[Caregiver] Permission found with remaining time! Restoring access.');
        final babyId = accessRes?['babyId'] as String? ??
            (accessRes?['data']?['babyId'] as String?) ??
            (accessRes?['data']?['baby']?['id'] as String?) ??
            cachedSession?['babyId'] as String?;
        final expiresAt = accessRes?['expiresAt'] as String? ??
            (accessRes?['data']?['expiresAt'] as String?) ??
            cachedSession?['expiresAt'] as String?;
        final permsMap = (accessRes?['data']?['permissions'] as Map<String, dynamic>?) ??
            (accessRes?['permissions'] as Map<String, dynamic>?) ??
            cachedSession?['permissions'] as Map<String, dynamic>?;
        final babyData = (accessRes?['data']?['baby'] as Map<String, dynamic>?) ??
            cachedSession?['baby'] as Map<String, dynamic>? ?? {
          'id': babyId ?? 'shared_baby_01',
          'name': accessRes?['data']?['babyName'] ?? cachedSession?['babyName'] ?? 'Shared Baby',
          'dateOfBirth': '2024-01-01',
          'gender': 'female',
        };

        if (expiresAt != null) {
          await cache.cacheCaregiverGrantedSession({
            'babyId': babyId ?? 'shared_baby_01',
            'babyName': babyData['name'] ?? 'Shared Baby',
            'permissions': permsMap ?? {'live_monitoring': true},
            'expiresAt': expiresAt,
            'baby': babyData,
          });
        }

        if (mounted && state.session != null && state.session!.hasActiveCaregiverPermission != true) {
          state = AuthState.authenticated(
            state.session!.copyWith(hasActiveCaregiverPermission: true),
          );
        }
        debugPrint('[Caregiver] Opening dashboard');
        return true;
      } else {
        debugPrint('[Caregiver] Caregiver permission inactive or no active assignment. Keeping session authenticated with hasActiveCaregiverPermission=false.');
        final cache = _ref.read(cacheServiceProvider);
        await cache.clearCaregiverGrantedSession();
        if (mounted && state.session != null && state.session!.hasActiveCaregiverPermission != false) {
          state = AuthState.authenticated(
            state.session!.copyWith(hasActiveCaregiverPermission: false),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('[Caregiver] Permission verification error: $e');
      if (mounted && state.session != null && state.session!.hasActiveCaregiverPermission != false) {
        state = AuthState.authenticated(
          state.session!.copyWith(hasActiveCaregiverPermission: false),
        );
      }
      return false;
    } finally {
      _isCheckingCaregiverPerms = false;
    }
  }

  Future<void> logout() async {
    debugPrint('[AUTH] Logout initiated by user. Updating state to unauthenticated immediately.');

    // 1. Immediately update auth state to unauthenticated so GoRouter redirects instantly
    state = AuthState.unauthenticated();

    // 2. Disconnect WebSocket and clear local cache & memory providers
    try {
      final ws = _ref.read(webSocketServiceProvider);
      await ws.disconnect();

      final cache = _ref.read(cacheServiceProvider);
      await cache.clearCache();

      _ref.invalidate(dashboardProvider);
      _ref.invalidate(profileProvider);
      _ref.invalidate(healthReportsProvider);
      _ref.invalidate(deviceProvider);
      _ref.invalidate(onboardingProvider);
      _ref.read(musicProvider.notifier).clearSessionMusicData();
      _ref.invalidate(musicProvider);
      _ref.invalidate(caregiverAccessProvider);
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

  Timer? _caregiverPermissionTimer;

  void _startCaregiverRevocationCheckTimer() {
    _caregiverPermissionTimer?.cancel();
    if (AppConfig.isTesting) return;
    _caregiverPermissionTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      if (state.session?.role == UserRole.caregiver && state.session?.hasActiveCaregiverPermission == true) {
        final hasActive = await verifyCaregiverActivePermissions();
        if (!hasActive && mounted) {
          debugPrint('[CaregiverRevocation] Parent revoked access! Invalidation triggered.');
          final cache = _ref.read(cacheServiceProvider);
          await cache.clearCaregiverGrantedSession();
          await cache.sharedPreferences.remove('maatriva_cache_selected_baby');
          await cache.sharedPreferences.remove('maatriva_cache_selected_baby_id');
          await cache.sharedPreferences.remove('maatriva_cache_selected_baby_name');
          _ref.invalidate(dashboardProvider);
          if (mounted && state.session != null) {
            state = AuthState.authenticated(
              state.session!.copyWith(hasActiveCaregiverPermission: false),
            );
          }
        }
      }
    });
  }

  void clearError() {
    if (state.status == AuthStatus.error && mounted) {
      state = AuthState.unauthenticated();
    }
  }

  @override
  void dispose() {
    _caregiverPermissionTimer?.cancel();
    super.dispose();
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
