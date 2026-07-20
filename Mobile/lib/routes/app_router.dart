import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/client_dashboard_screen.dart';
import '../screens/dashboard/mechanic_dashboard_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/privacy_policy_screen.dart';
import '../screens/profile/personal_data_screen.dart';
import '../screens/profile/security_password_screen.dart';
import '../screens/profile/help_center_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/dashboard/secretary_dashboard_screen.dart';

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      if (!authProvider.isInitialized) return null;

      final location = state.uri.path;
      final isAuthRoute = location == '/login' || location == '/register';
      final isClientRoute = location.startsWith('/client');
      final isMechanicRoute = location.startsWith('/mechanic');
      final isAdminRoute = location.startsWith('/admin');
      final isSecretaryRoute = location.startsWith('/secretary');
      final isProfileRoute = location == '/profile';

      if (!authProvider.isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isClientRoute && !authProvider.isClient) {
        return '/login';
      }

      if (isMechanicRoute && !authProvider.isMechanic) {
        return '/login';
      }

      if (isAdminRoute && !authProvider.isAdmin) {
        return '/login';
      }

      if (isSecretaryRoute && !authProvider.isSecretary) {
        return '/login';
      }

      if (isAuthRoute) {
        if (authProvider.isAdmin) return '/admin/dashboard';
        if (authProvider.isClient) return '/client/dashboard';
        if (authProvider.isMechanic) return '/mechanic/dashboard';
        if (authProvider.isSecretary) return '/secretary/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/client/dashboard',
        builder: (context, state) => const ClientDashboardScreen(),
      ),
      GoRoute(
        path: '/client/bookings/:bookingId',
        builder: (context, state) => const ClientDashboardScreen(),
      ),
      GoRoute(
        path: '/client/orders/:orderId',
        builder: (context, state) => const ClientDashboardScreen(),
      ),
      GoRoute(
        path: '/mechanic/dashboard',
        builder: (context, state) => const MechanicDashboardScreen(),
      ),
      GoRoute(
        path: '/mechanic/orders/:orderId',
        builder: (context, state) => const MechanicDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/bookings/:bookingId',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/secretary/dashboard',
        builder: (context, state) => const SecretaryDashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/personal-data',
        builder: (context, state) => const PersonalDataScreen(),
      ),
      GoRoute(
        path: '/profile/security',
        builder: (context, state) => const SecurityPasswordScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            contactId: extra?['contactId'],
            contactName: extra?['contactName'] ?? 'Chat',
          );
        },
      ),
    ],
  );
}
