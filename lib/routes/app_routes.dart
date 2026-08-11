import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/screens/home_screen.dart';
import '../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../features/reports/presentation/screens/health_reports_screen.dart';
import '../features/reports/presentation/screens/predictive_health_screen.dart';
import '../features/dashboard/presentation/screens/telemetry_history_screen.dart';
import '../features/caregivers/presentation/screens/caregiver_access_screen.dart';
import '../features/caregivers/presentation/screens/accept_invite_screen.dart';
import '../features/caregivers/presentation/screens/join_shared_baby_screen.dart';
import '../features/shop/presentation/screens/shop_screen.dart';
import '../features/shop/presentation/screens/product_details_screen.dart';
import '../features/shop/presentation/screens/cart_screen.dart';
import '../features/shop/presentation/screens/wishlist_screen.dart';
import '../features/shop/domain/product.dart';

// Profile screens
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/parent_details_screen.dart';
import '../features/baby/presentation/screens/baby_details_screen.dart';
import '../features/devices/screens/connected_devices_screen.dart';
import '../features/devices/screens/device_detail_screen.dart';
import '../features/devices/screens/device_pairing_screen.dart';
import '../features/profile/presentation/screens/medical_history_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/settings/presentation/screens/privacy_security_screen.dart';
import '../features/profile/presentation/screens/help_center_screen.dart';

// Notifications screens
import '../features/notifications/screens/notifications_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/onboarding/providers/onboarding_provider.dart';

// Music screens
import '../features/music/screens/music_home_screen.dart';
import '../features/music/screens/music_player_screen.dart';
import '../features/music/screens/playlist_screen.dart';

// Auth screens & provider
import '../features/authentication/presentation/providers/auth_provider.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/register_screen.dart';
import '../features/authentication/presentation/screens/splash_screen.dart';
import '../shared/models/user_session.dart';

/// Centralized route registry paths definition
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String music = '/music';
  static const String musicPlayer = '/music/player';
  static const String musicPlaylist = '/music/playlist';
  static const String onboarding = '/onboarding';
  static const String aiAssistant = '/ai-assistant';
  static const String healthReports = '/health-reports';
  static const String predictiveHealth = '/predictive-health';
  static const String telemetryHistory = '/telemetry-history';
  static const String caregiverAccess = '/caregiver-access';
  static const String caregiverAcceptInvite = '/accept-invite';
  static const String joinSharedBaby = '/join-shared-baby';
  static const String shop = '/shop';
  static const String shopProductDetails = '/shop/product-details';
  static const String shopCart = '/shop/cart';
  static const String shopWishlist = '/shop/wishlist';

  // Profile sub-routes
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String parentDetails = '/profile/parent-details';
  static const String babyDetails = '/profile/baby-details';
  static const String connectedDevices = '/profile/connected-devices';
  static const String connectedDeviceDetail = '/profile/connected-devices/detail';
  static const String devicePairing = '/profile/connected-devices/pair';
  static const String medicalHistory = '/profile/medical-history';
  static const String settingsNotifications = '/profile/notifications';
  static const String settingsPrivacy = '/profile/privacy-security';
  static const String helpCenter = '/profile/help';
  static const String notifications = '/notifications';
}

/// A simple notifier to bridge state changes to GoRouter's refreshListenable.
class RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier();
  
  ref.listen(authNotifierProvider, (_, __) {
    refreshNotifier.notify();
  });

  ref.listen(onboardingProvider, (_, __) {
    refreshNotifier.notify();
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final onboarding = ref.read(onboardingProvider);

      final isLoggingInOrRegistering =
          state.matchedLocation == AppRoutes.login ||
              state.matchedLocation == AppRoutes.register;

      // While verifying tokens on startup, hold user on splash
      if (auth.status == AuthStatus.initial ||
          (auth.status == AuthStatus.loading && state.matchedLocation == AppRoutes.splash)) {
        return null;
      }

      // Guest redirection
      if (auth.status == AuthStatus.unauthenticated) {
        if (isLoggingInOrRegistering) return null;
        return AppRoutes.login;
      }

      // Authenticated redirection
      if (auth.status == AuthStatus.authenticated) {
        if (onboarding.isLoading) {
          return null;
        }

        final isGoingToOnboarding = state.matchedLocation == AppRoutes.onboarding;
        final isGoingToJoinSharedBaby = state.matchedLocation == AppRoutes.joinSharedBaby;

        final isCaregiver = auth.session?.role == UserRole.caregiver;

        // Caregiver role route restrictions: block health, shop, ai, and caregiver management screens
        if (isCaregiver) {
          final loc = state.matchedLocation;
          final isRestrictedRoute = loc == AppRoutes.healthReports ||
              loc == AppRoutes.predictiveHealth ||
              loc == AppRoutes.aiAssistant ||
              loc == AppRoutes.caregiverAccess ||
              loc == AppRoutes.parentDetails ||
              loc.startsWith('/shop');

          if (isRestrictedRoute) {
            return AppRoutes.home;
          }
        }

        if (!onboarding.isCompleted && !isCaregiver) {
          if (!isGoingToOnboarding && !isGoingToJoinSharedBaby) {
            return AppRoutes.onboarding;
          }
          return null;
        } else {
          // Role-based login redirection verification
          if (isLoggingInOrRegistering ||
              state.matchedLocation == AppRoutes.splash ||
              isGoingToOnboarding) {
            if (isCaregiver) {
              final hasActivePerm = auth.session?.hasActiveCaregiverPermission ?? false;
              if (hasActivePerm) {
                return AppRoutes.home;
              }
              return AppRoutes.joinSharedBaby;
            }
            // Parent account: open baby dashboard directly
            return AppRoutes.home;
          }
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final tab = tabStr != null ? int.tryParse(tabStr) ?? 0 : 0;
          return HomeScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: AppRoutes.music,
        builder: (context, state) => const MusicHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.musicPlayer,
        builder: (context, state) => const MusicPlayerScreen(),
      ),
      GoRoute(
        path: AppRoutes.musicPlaylist,
        builder: (context, state) {
          final playlistName = state.uri.queryParameters['name'] ?? 'Favorites';
          return PlaylistScreen(playlistName: playlistName);
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: AppRoutes.healthReports,
        builder: (context, state) => const HealthReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.predictiveHealth,
        builder: (context, state) => const PredictiveHealthScreen(),
      ),
      GoRoute(
        path: AppRoutes.telemetryHistory,
        builder: (context, state) {
          final sensorType = state.uri.queryParameters['type'] ?? 'heart_rate';
          return TelemetryHistoryScreen(sensorType: sensorType);
        },
      ),
      GoRoute(
        path: AppRoutes.caregiverAccess,
        builder: (context, state) => const CaregiverAccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.caregiverAcceptInvite,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return AcceptInviteScreen(token: token);
        },
      ),
      GoRoute(
        path: AppRoutes.joinSharedBaby,
        builder: (context, state) => const JoinSharedBabyScreen(),
      ),
      GoRoute(
        path: AppRoutes.shop,
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: AppRoutes.shopProductDetails,
        builder: (context, state) {
          final product = state.extra as Product?;
          final productId = state.uri.queryParameters['id'];
          return ProductDetailsScreen(product: product, productId: productId);
        },
      ),
      GoRoute(
        path: AppRoutes.shopCart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.shopWishlist,
        builder: (context, state) => const WishlistScreen(),
      ),

      // Profile routes
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentDetails,
        builder: (context, state) => const ParentDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.babyDetails,
        builder: (context, state) => const BabyDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.connectedDevices,
        builder: (context, state) => const ConnectedDevicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.devicePairing,
        builder: (context, state) => const DevicePairingScreen(),
      ),
      GoRoute(
        path: AppRoutes.connectedDeviceDetail,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '1';
          return DeviceDetailScreen(deviceId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.medicalHistory,
        builder: (context, state) => const MedicalHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsNotifications,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsPrivacy,
        builder: (context, state) => const PrivacySecurityScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpCenter,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
