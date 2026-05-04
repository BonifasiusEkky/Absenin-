import 'package:go_router/go_router.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/attendance/attendance_detail_screen.dart';
import '../../features/attendance/attendance_list_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/camera/face_capture_screen.dart';
import '../../features/camera/checkout_face_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/leave/leave_screen.dart';
import '../../features/assignment/assignment_screen.dart';
import '../../services/session_storage.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    final loc = state.matchedLocation;
    final isPublic = loc == '/splash' || loc == '/onboarding' || loc == '/login';

    StoredSession? session;
    try {
      session = await StoredSession.load();
    } catch (_) {
      session = null;
    }
    final loggedIn = session != null && session.token.isNotEmpty;

    if (!loggedIn && !isPublic) return '/login';
    if (loggedIn && (loc == '/login' || loc == '/onboarding')) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/home', builder: (_, __) => const MainShell()),
    GoRoute(path: '/attendance', builder: (_, __) => const AttendanceListScreen()),
    GoRoute(
      path: '/attendance/detail/:date',
      builder: (_, state) => AttendanceDetailScreen(dateIso: state.pathParameters['date']!),
    ),
    GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
    GoRoute(path: '/camera/face', builder: (_, __) => const FaceCaptureScreen()),
  GoRoute(path: '/camera/checkout', builder: (_, __) => const CheckoutFaceScreen()),
    GoRoute(path: '/leave', builder: (_, __) => const LeaveScreen()),
    GoRoute(path: '/assignment', builder: (_, __) => const AssignmentScreen()),
  ],
);
