import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/cupertino_theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/animations.dart';
import 'package:google_fonts/google_fonts.dart';

final trainerDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = SupabaseClientService().client;
  final userId = client.auth.currentUser!.id;

  final members = await client
      .from('trainer_assignments')
      .select('member_id')
      .eq('trainer_id', userId)
      .eq('status', 'active');

  final memberIds = (members as List).map((m) => m['member_id'] as String).toList();
  if (memberIds.isEmpty) {
    return {
      'totalMembers': 0, 'canChat': 0, 'expiringSoon': 0,
      'weekCounts': List.generate(7, (_) => 0),
    };
  }

  final memberProfiles = await client
      .from('profiles')
      .select('id')
      .or(memberIds.map((id) => 'id.eq.$id').join(','));

  final totalMembers = (memberProfiles as List).length;

  final rooms = await client
      .from('chat_rooms')
      .select('id')
      .or('participant_one.eq.$userId,participant_two.eq.$userId');

  final roomMemberIds = <String>{};
  for (final r in (rooms as List)) {
    final p1 = r['participant_one'] as String?;
    final p2 = r['participant_two'] as String?;
    if (p1 != null && p1 != userId) roomMemberIds.add(p1);
    if (p2 != null && p2 != userId) roomMemberIds.add(p2);
  }
  final canChat = roomMemberIds.where((id) => memberIds.contains(id)).length;

  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekCounts = List.generate(7, (i) => 0);

  for (final mid in memberIds) {
    final attendance = await client
        .from('check_ins')
        .select('check_in_time')
        .eq('member_id', mid)
        .gte('check_in_time', weekStart.toIso8601String())
        .lt('check_in_time', weekStart.add(const Duration(days: 7)).toIso8601String());

    for (final a in (attendance as List)) {
      final t = DateTime.parse(a['check_in_time'] as String);
      final day = t.weekday - 1;
      if (day >= 0 && day < 7) weekCounts[day]++;
    }
  }

  final memberships = await client
      .from('memberships')
      .select('member_id, end_date')
      .or(memberIds.map((id) => 'member_id.eq.$id').join(','))
      .eq('status', 'active');

  int expiringSoon = 0;
  final expiringThreshold = now.add(const Duration(days: 7));
  for (final m in (memberships as List)) {
    final end = DateTime.tryParse(m['end_date'] as String? ?? '');
    if (end != null && end.isBefore(expiringThreshold) && end.isAfter(now)) {
      expiringSoon++;
    }
  }

  return {
    'totalMembers': totalMembers,
    'canChat': canChat,
    'expiringSoon': expiringSoon,
    'weekCounts': weekCounts,
  };
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(trainerDashboardProvider);
    final name = SupabaseClientService().client.auth.currentUser?.userMetadata?['full_name'] as String? ?? 'Coach';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard',
                        style: sfText(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary, letterSpacing: 0.38)),
                      Text(name,
                        style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textTertiary)),
                    ],
                  ),
                  const Icon(CupertinoIcons.bell, color: CupertinoAppColors.textTertiary, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: dataAsync.when(
                data: (data) => _DashboardContent(data: data),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: SkeletonBox(height: 70)),
                          SizedBox(width: 8),
                          Expanded(child: SkeletonBox(height: 70)),
                          SizedBox(width: 8),
                          Expanded(child: SkeletonBox(height: 70)),
                        ],
                      ),
                      SizedBox(height: 14),
                      SkeletonBox(width: 180, height: 14),
                      SizedBox(height: 10),
                      SkeletonBox(height: 90),
                    ],
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e', style: sfText(fontSize: 12, fontWeight: FontWeight.w400, color: CupertinoAppColors.textQuaternary))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalMembers = data['totalMembers'] as int;
    final canChat = data['canChat'] as int;
    final expiringSoon = data['expiringSoon'] as int;
    final weekCounts = data['weekCounts'] as List<int>;
    final maxCount = weekCounts.reduce((a, b) => a > b ? a : 1).clamp(1, 100);
    final today = DateTime.now().weekday - 1;
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      physics: const ClampingScrollPhysics(),
      children: [
          Row(
              children: [
                Expanded(child: StaggeredFadeIn(
                  index: 0,
                  child: _StatPill(
                    valueWidget: AnimatedCountUp(target: totalMembers, style: sfText(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoAppColors.purpleLight)),
                    label: 'Members',
                    style: _StatStyle.purple,
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: StaggeredFadeIn(
                  index: 1,
                  child: _StatPill(
                    valueWidget: AnimatedCountUp(target: canChat, style: sfText(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoAppColors.green)),
                    label: 'Can Chat',
                    style: _StatStyle.green,
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: StaggeredFadeIn(
                  index: 2,
                  child: _StatPill(
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedCountUp(target: expiringSoon, style: sfText(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoAppColors.orange)),
                        const SizedBox(width: 4),
                        Icon(
                          expiringSoon > 0 ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down,
                          color: expiringSoon > 0 ? CupertinoAppColors.orange : CupertinoAppColors.green,
                          size: 14,
                        ),
                      ],
                    ),
                    label: 'Exp. Soon',
                    style: _StatStyle.amber,
                  ),
                )),
              ],
            ),
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 3,
            child: Text('Workouts This Week \u2014 All Members',
              style: sfText(fontSize: 17, fontWeight: FontWeight.w500, color: CupertinoAppColors.textPrimary, letterSpacing: -0.41)),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoAppColors.groupedBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CupertinoAppColors.separator.withAlpha(100)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 70,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final count = weekCounts[i];
                    final pct = maxCount > 0 ? count / maxCount : 0.0;
                    final h = (pct * 64).clamp(2.0, 64.0);
                    final isToday = i == today;
                    final isFuture = i > today;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          color: isFuture
                              ? CupertinoAppColors.textQuaternary.withAlpha(30)
                              : isToday
                                  ? CupertinoAppColors.neon
                                  : CupertinoAppColors.purple,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(7, (i) {
                  return Expanded(
                    child: Text(labels[i],
                      textAlign: TextAlign.center,
                      style: sfText(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: i == today ? CupertinoAppColors.neon : CupertinoAppColors.textTertiary,
                        letterSpacing: 0.06,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

enum _StatStyle { purple, green, amber }

class _StatPill extends StatelessWidget {
  final Widget valueWidget;
  final String label;
  final _StatStyle style;

  const _StatPill({required this.valueWidget, required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    switch (style) {
      case _StatStyle.purple:
        bg = CupertinoAppColors.purple.withAlpha(15);
        border = CupertinoAppColors.purple.withAlpha(40);
      case _StatStyle.green:
        bg = CupertinoAppColors.green.withAlpha(15);
        border = CupertinoAppColors.green.withAlpha(40);
      case _StatStyle.amber:
        bg = CupertinoAppColors.orange.withAlpha(15);
        border = CupertinoAppColors.orange.withAlpha(40);
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          valueWidget,
          const SizedBox(height: 2),
          Text(label, style: sfText(fontSize: 11, fontWeight: FontWeight.w500, color: CupertinoAppColors.textTertiary, letterSpacing: 0.06)),
        ],
      ),
    );
  }
}
