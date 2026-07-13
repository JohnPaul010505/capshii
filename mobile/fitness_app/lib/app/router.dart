import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/providers/auth_provider.dart';
import '../features/auth/pages/login_page.dart';
import '../features/member/home/pages/home_page.dart';
import '../features/member/meals/pages/meal_log_page.dart';
import '../features/member/workout/pages/workout_page.dart';
import '../features/member/progress/pages/progress_page.dart';
import '../features/member/chat/pages/chat_page.dart';
import '../features/member/settings/pages/settings_page.dart';
import '../features/member/measurements/pages/measurements_page.dart';
import '../features/member/goals/pages/goals_page.dart';
import '../features/member/feedback/pages/feedback_page.dart';
import '../features/member/notifications/pages/notifications_page.dart';
import '../features/trainer/dashboard/pages/dashboard_page.dart' as trainer;
import '../features/trainer/progress/pages/progress_list_page.dart';
import '../features/trainer/progress/pages/member_progress_page.dart';
import '../features/trainer/chat/pages/chat_list_page.dart';
import '../features/trainer/chat/pages/chat_room_page.dart';
import '../features/trainer/profile/pages/profile_page.dart' as trainer_profile;
import '../features/shared/checkin/checkin_page.dart';
import '../features/shared/widgets/glass_bottom_nav.dart';
import '../features/shared/widgets/nav_icons.dart';
import '../features/admin/shell/admin_shell.dart';
import '../features/admin/dashboard/pages/dashboard_page.dart' as admin_dashboard;
import '../features/admin/members/pages/admin_members_page.dart' as admin_members;
import '../features/admin/trainers/pages/admin_trainers_page.dart' as admin_trainers;
import '../features/admin/settings/pages/admin_settings_page.dart' as admin_settings;

final _memberShellKey = GlobalKey<NavigatorState>();
final _trainerShellKey = GlobalKey<NavigatorState>();

Page<dynamic> _iosPush(Widget child) => CustomTransitionPage(
  key: ValueKey(child.hashCode),
  child: child,
  transitionsBuilder: (_, animation, __, child) {
    final scale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    );
    final fade = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
    );
  },
  transitionDuration: const Duration(milliseconds: 300),
  reverseTransitionDuration: const Duration(milliseconds: 250),
);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final profile = authState.valueOrNull;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) {
        if (profile?.role == 'trainer') return '/trainer/dashboard';
        if (profile?.role == 'admin') return '/admin/dashboard';
        return '/member/home';
      }
      if (isLoggedIn && profile != null) {
        final loc = state.matchedLocation;
        if (profile.role == 'member' && loc.startsWith('/trainer')) return '/member/home';
        if (profile.role == 'member' && loc.startsWith('/admin')) return '/member/home';
        if (profile.role == 'trainer' && loc.startsWith('/member')) return '/trainer/dashboard';
        if (profile.role == 'trainer' && loc.startsWith('/admin')) return '/trainer/dashboard';
        if (profile.role == 'admin' && (loc.startsWith('/member') || loc.startsWith('/trainer'))) return '/admin/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', pageBuilder: (_, __) => _iosPush(const LoginPage())),
      ShellRoute(
        navigatorKey: _memberShellKey,
        builder: (_, __, child) => MemberShell(child: child),
        routes: [
          GoRoute(path: '/member/home', pageBuilder: (_, __) => _iosPush(const HomePage())),
          GoRoute(path: '/member/meals', pageBuilder: (_, __) => _iosPush(const MealLogPage())),
          GoRoute(path: '/member/workout', pageBuilder: (_, __) => _iosPush(const WorkoutPage())),
          GoRoute(path: '/member/progress', pageBuilder: (_, __) => _iosPush(const ProgressPage())),
          GoRoute(path: '/member/chat', pageBuilder: (_, __) => _iosPush(const ChatPage())),
        ],
      ),
      GoRoute(path: '/member/settings', pageBuilder: (_, __) => _iosPush(const SettingsPage())),
      GoRoute(path: '/member/checkin', pageBuilder: (_, __) => _iosPush(const CheckinPage())),
      GoRoute(path: '/member/measurements', pageBuilder: (_, __) => _iosPush(const MeasurementsPage())),
      GoRoute(path: '/member/goals', pageBuilder: (_, __) => _iosPush(const GoalsPage())),
      GoRoute(path: '/member/feedback', pageBuilder: (_, __) => _iosPush(const FeedbackPage())),
      GoRoute(path: '/member/notifications', pageBuilder: (_, __) => _iosPush(const NotificationsPage())),
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin/dashboard', pageBuilder: (_, __) => _iosPush(const admin_dashboard.DashboardPage())),
          GoRoute(path: '/admin/members', pageBuilder: (_, __) => _iosPush(const admin_members.AdminMembersPage())),
          GoRoute(path: '/admin/trainers', pageBuilder: (_, __) => _iosPush(const admin_trainers.AdminTrainersPage())),
          GoRoute(path: '/admin/settings', pageBuilder: (_, __) => _iosPush(const admin_settings.AdminSettingsPage())),
        ],
      ),
      ShellRoute(
        navigatorKey: _trainerShellKey,
        builder: (_, __, child) => TrainerShell(child: child),
        routes: [
          GoRoute(path: '/trainer/dashboard', pageBuilder: (_, __) => _iosPush(const trainer.DashboardPage())),
          GoRoute(
            path: '/trainer/members',
            pageBuilder: (_, __) => _iosPush(const ProgressListPage()),
            routes: [
              GoRoute(path: ':id', pageBuilder: (_, state) => _iosPush(MemberProgressPage(id: state.pathParameters['id']!))),
            ],
          ),
          GoRoute(path: '/trainer/checkin', pageBuilder: (_, __) => _iosPush(const CheckinPage())),
          GoRoute(path: '/trainer/chat', pageBuilder: (_, __) => _iosPush(const ChatListPage())),
          GoRoute(path: '/trainer/chat/:roomId', pageBuilder: (_, state) => _iosPush(ChatRoomPage(roomId: state.pathParameters['roomId']!))),
          GoRoute(path: '/trainer/profile', pageBuilder: (_, __) => _iosPush(const trainer_profile.ProfilePage())),
        ],
      ),
    ],
  );
});

class MemberShell extends StatelessWidget {
  final Widget child;
  const MemberShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _memberIndex(context),
        onTap: (index) => _memberTap(context, index),
        items: const [
          GlassNavItem(type: NavIconType.home, label: 'Home'),
          GlassNavItem(type: NavIconType.workout, label: 'Workout'),
          GlassNavItem(type: NavIconType.food, label: 'Food'),
          GlassNavItem(type: NavIconType.progress, label: 'Progress'),
          GlassNavItem(type: NavIconType.chat, label: 'Chat'),
        ],
      ),
    );
  }

  int _memberIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/member/workout') return 1;
    if (location == '/member/meals') return 2;
    if (location == '/member/progress') return 3;
    if (location.startsWith('/member/chat')) return 4;
    return 0;
  }

  void _memberTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/member/home');
      case 1: context.go('/member/workout');
      case 2: context.go('/member/meals');
      case 3: context.go('/member/progress');
      case 4: context.go('/member/chat');
    }
  }
}

class TrainerShell extends StatelessWidget {
  final Widget child;
  const TrainerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _trainerIndex(context),
        onTap: (index) => _trainerTap(context, index),
        items: const [
          GlassNavItem(type: NavIconType.dashboard, label: 'Dashboard'),
          GlassNavItem(type: NavIconType.members, label: 'Members'),
          GlassNavItem(type: NavIconType.messages, label: 'Messages'),
          GlassNavItem(type: NavIconType.profile, label: 'Profile'),
        ],
      ),
    );
  }

  int _trainerIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/trainer/members')) return 1;
    if (location.startsWith('/trainer/chat')) return 2;
    if (location.startsWith('/trainer/profile')) return 3;
    return 0;
  }

  void _trainerTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/trainer/dashboard');
      case 1: context.go('/trainer/members');
      case 2: context.go('/trainer/chat');
      case 3: context.go('/trainer/profile');
    }
  }
}
