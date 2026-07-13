import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/cupertino_theme.dart';

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final supabase = SupabaseClientService().client;

  final members = await supabase.from('profiles').select('id').eq('role', 'member');
  final trainers = await supabase.from('profiles').select('id').eq('role', 'trainer');
  final activeSessions = await supabase.from('check_ins').select('id').eq('status', 'active');
  final newProfiles = await supabase.from('profiles').select('id').gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String());

  return {
    'memberCount': (members as List).length,
    'trainerCount': (trainers as List).length,
    'activeSessions': (activeSessions as List).length,
    'newThisWeek': (newProfiles as List).length,
  };
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: CupertinoAppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                'Dashboard',
                style: sfText(fontSize: 28, fontWeight: FontWeight.w700, color: CupertinoAppColors.textPrimary),
              ),
            ),
            Expanded(
              child: statsAsync.when(
                data: (stats) => _DashboardGrid(stats: stats),
                loading: () => const Center(child: CupertinoActivityIndicator(radius: 14)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Error: $e',
                      style: sfText(fontSize: 15, color: CupertinoAppColors.red),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  final Map<String, int> stats;

  const _DashboardGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(icon: CupertinoIcons.person_2, label: 'Members', value: stats['memberCount'] ?? 0, color: CupertinoAppColors.purpleLight),
      _StatCard(icon: CupertinoIcons.graph_square_fill, label: 'Trainers', value: stats['trainerCount'] ?? 0, color: CupertinoAppColors.neon),
      _StatCard(icon: CupertinoIcons.bolt_circle_fill, label: 'Active Sessions', value: stats['activeSessions'] ?? 0, color: CupertinoAppColors.greenLight),
      _StatCard(icon: CupertinoIcons.arrow_up_circle_fill, label: 'New This Week', value: stats['newThisWeek'] ?? 0, color: CupertinoAppColors.orange),
    ];

    return LayoutBuilder(
      builder: (_, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => cards[i],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoAppColors.groupedBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CupertinoAppColors.separator.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: sfText(fontSize: 22, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.41),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: sfText(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoAppColors.textTertiary, letterSpacing: -0.08),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
