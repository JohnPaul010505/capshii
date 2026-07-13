import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/cupertino_theme.dart';

final dashboardStatsProvider = FutureProvider((ref) async {
  final userId = SupabaseClientService().client.auth.currentUser!.id;
  final activeGoal = await SupabaseClientService()
      .client
      .from('goals')
      .select('id')
      .eq('member_id', userId)
      .eq('status', 'active');
  final unreadNotifications = await SupabaseClientService()
      .client
      .from('notifications')
      .select('id')
      .eq('user_id', userId)
      .eq('read', false);
  return {
    'goals': (activeGoal as List).length,
    'unread': (unreadNotifications as List).length,
  };
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoAppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildNavBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _StatRow(
                    icon: CupertinoIcons.flag,
                    label: '${statsAsync.value?['goals'] ?? 0} Active Goals',
                    color: CupertinoAppColors.orange,
                    onTap: () => context.go('/member/goals'),
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    icon: CupertinoIcons.bell,
                    label: '${statsAsync.value?['unread'] ?? 0} Unread Notifications',
                    color: CupertinoAppColors.primaryBlue,
                    onTap: () => context.go('/member/notifications'),
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    icon: CupertinoIcons.fork_knife,
                    label: 'Log Meals',
                    color: CupertinoAppColors.purple,
                    onTap: () => context.go('/member/meals'),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Weekly Progress',
                      style: sfText(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CupertinoAppColors.textPrimary,
                        letterSpacing: -0.36,
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: CupertinoAppColors.groupedBackground,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Your activity chart will appear here.',
                        textAlign: TextAlign.center,
                        style: sfText(
                          fontSize: 15,
                          color: CupertinoAppColors.textTertiary,
                          letterSpacing: -0.24,
                        ),
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

  Widget _buildNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CupertinoAppColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32),
          Expanded(
            child: Text(
              'Dashboard',
              textAlign: TextAlign.center,
              style: sfText(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoAppColors.textPrimary,
                letterSpacing: -0.41,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: CupertinoAppColors.groupedBackground,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: sfText(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: CupertinoAppColors.textPrimary,
                    letterSpacing: -0.41,
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_right, color: CupertinoAppColors.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
