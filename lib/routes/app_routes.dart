import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/screens/home_screen.dart';
import '../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../features/health_reports/presentation/screens/health_reports_screen.dart';
import '../features/health_reports/presentation/screens/predictive_health_screen.dart';
import '../features/caregiver_access/presentation/screens/caregiver_access_screen.dart';
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
import '../features/profile/presentation/screens/medical_history_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/settings/presentation/screens/privacy_security_screen.dart';
import '../features/profile/presentation/screens/help_center_screen.dart';

// Notifications screens
import '../features/notifications/screens/notifications_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';

// Music screens
import '../features/music/screens/music_home_screen.dart';
import '../features/music/screens/music_player_screen.dart';
import '../features/music/screens/playlist_screen.dart';

final GoRouter goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final tabStr = state.uri.queryParameters['tab'];
        final tab = tabStr != null ? int.tryParse(tabStr) ?? 0 : 0;
        return HomeScreen(initialTab: tab);
      },
    ),
    GoRoute(
      path: '/music',
      builder: (context, state) => const MusicHomeScreen(),
    ),
    GoRoute(
      path: '/music/player',
      builder: (context, state) => const MusicPlayerScreen(),
    ),
    GoRoute(
      path: '/music/playlist',
      builder: (context, state) {
        final playlistName = state.uri.queryParameters['name'] ?? 'Favorites';
        return PlaylistScreen(playlistName: playlistName);
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/ai-assistant',
      builder: (context, state) => const AiAssistantScreen(),
    ),
    GoRoute(
      path: '/health-reports',
      builder: (context, state) => const HealthReportsScreen(),
    ),
    GoRoute(
      path: '/predictive-health',
      builder: (context, state) => const PredictiveHealthScreen(),
    ),
    GoRoute(
      path: '/caregiver-access',
      builder: (context, state) => const CaregiverAccessScreen(),
    ),
    GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
    GoRoute(
      path: '/shop/product-details',
      builder: (context, state) {
        final product = state.extra as Product?;
        final productId = state.uri.queryParameters['id'];
        return ProductDetailsScreen(product: product, productId: productId);
      },
    ),
    GoRoute(
      path: '/shop/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/shop/wishlist',
      builder: (context, state) => const WishlistScreen(),
    ),

    // Profile routes
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/profile/parent-details',
      builder: (context, state) => const ParentDetailsScreen(),
    ),
    GoRoute(
      path: '/profile/baby-details',
      builder: (context, state) => const BabyDetailsScreen(),
    ),
    GoRoute(
      path: '/profile/connected-devices',
      builder: (context, state) => const ConnectedDevicesScreen(),
    ),
    GoRoute(
      path: '/profile/connected-devices/detail',
      builder: (context, state) {
        final id = state.uri.queryParameters['id'] ?? '1';
        return DeviceDetailScreen(deviceId: id);
      },
    ),
    GoRoute(
      path: '/profile/medical-history',
      builder: (context, state) => const MedicalHistoryScreen(),
    ),
    GoRoute(
      path: '/profile/notifications',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/privacy-security',
      builder: (context, state) => const PrivacySecurityScreen(),
    ),
    GoRoute(
      path: '/profile/help',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);
