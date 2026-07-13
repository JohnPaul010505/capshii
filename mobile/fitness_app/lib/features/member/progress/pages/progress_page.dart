import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/animations.dart';

final progressDataProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userId = SupabaseClientService().client.auth.currentUser!.id;
  final client = SupabaseClientService().client;
  final now = DateTime.now();

  final weekStart = now.subtract(Duration(days: now.weekday - 1));

  final weekAttendance = await client
      .from('check_ins')
      .select('check_in_time')
      .eq('member_id', userId)
      .gte('check_in_time', weekStart.toIso8601String())
      .lt('check_in_time', weekStart.add(const Duration(days: 7)).toIso8601String());

  final weekList = weekAttendance as List;
  final weekCounts = List.generate(7, (i) => 0);
  for (final a in weekList) {
    final t = DateTime.parse(a['check_in_time'] as String);
    final day = t.weekday - 1;
    if (day >= 0 && day < 7) weekCounts[day]++;
  }

  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0).day;

  final monthAttendance = await client
      .from('check_ins')
      .select('check_in_time')
      .eq('member_id', userId)
      .gte('check_in_time', monthStart.toIso8601String())
      .lt('check_in_time', DateTime(now.year, now.month + 1, 1).toIso8601String());

  final monthList = monthAttendance as List;
  final monthCounts = List.generate(monthEnd, (i) => 0);
  for (final a in monthList) {
    final t = DateTime.parse(a['check_in_time'] as String);
    final day = t.day - 1;
    if (day >= 0 && day < monthEnd) monthCounts[day]++;
  }

  final totalWorkouts = monthCounts.reduce((a, b) => a + b);
  final activeDays = monthCounts.where((c) => c > 0).length;

  return {
    'weekCounts': weekCounts,
    'monthCounts': monthCounts,
    'maxWeek': weekCounts.reduce((a, b) => a > b ? a : 1).clamp(1, 100),
    'maxMonth': monthCounts.reduce((a, b) => a > b ? a : 1).clamp(1, 100),
    'totalWorkouts': totalWorkouts,
    'activeDays': activeDays,
    'monthLabel': DateFormat('MMMM yyyy').format(now),
  };
});

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(progressDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: dataAsync.when(
          data: (data) => _ProgressContent(data: data),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 14),
                SkeletonBox(width: 120, height: 20),
                SizedBox(height: 14),
                SkeletonBox(height: 100),
                SizedBox(height: 14),
                SkeletonBox(width: 180, height: 16),
                SizedBox(height: 8),
                SkeletonBox(height: 100),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: SkeletonBox(height: 70)),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonBox(height: 70)),
                  ],
                ),
              ],
            ),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: Color(0xFF636366))),
          ),
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ProgressContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final weekCounts = data['weekCounts'] as List<int>;
    final monthCounts = data['monthCounts'] as List<int>;
    final maxWeek = data['maxWeek'] as int;
    final maxMonth = data['maxMonth'] as int;
    final totalWorkouts = data['totalWorkouts'] as int;
    final activeDays = data['activeDays'] as int;
    final monthLabel = data['monthLabel'] as String;
    final today = DateTime.now();

    final weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayWeekday = today.weekday - 1;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      physics: const ClampingScrollPhysics(),
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progress', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                Text(monthLabel, style: const TextStyle(
                  fontSize: 12, color: Color(0xFF8E8E93),
                )),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFBF5AF2).withAlpha(20),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFBF5AF2).withAlpha(40)),
              ),
              child: const Icon(CupertinoIcons.calendar, color: Color(0xFFD6A5FF), size: 18),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('This Week \u2014 Workouts per Day', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF38383A).withAlpha(100)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 70,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final count = weekCounts[i];
                    final pct = maxWeek > 0 ? count / maxWeek : 0.0;
                    final h = (pct * 64).clamp(2.0, 64.0);
                    final isToday = i == todayWeekday;
                    final isFuture = i > todayWeekday;
                    return StaggeredFadeIn(
                      index: i,
                      delay: const Duration(milliseconds: 20),
                      offset: const Offset(0, 8),
                      child: Container(
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          color: isFuture
                              ? const Color(0xFF8E8E93).withAlpha(30)
                              : isToday
                                  ? const Color(0xFF64D2FF)
                                  : const Color(0xFF0A84FF),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(7, (i) {
                  final isToday = i == todayWeekday;
                  return Expanded(
                    child: Text(weekLabels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10, color: isToday ? const Color(0xFF64D2FF) : const Color(0xFF8E8E93),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('This Month \u2014 Daily Workouts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF38383A).withAlpha(100)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 70,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(monthCounts.length, (i) {
                    final count = monthCounts[i];
                    final pct = maxMonth > 0 ? count / maxMonth : 0.0;
                    final h = (pct * 64).clamp(2.0, 64.0);
                    final isToday = i == today.day - 1;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          color: isToday
                              ? const Color(0xFF64D2FF)
                              : count > 0
                                  ? const Color(0xFF0A84FF)
                                  : const Color(0xFF38383A),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),
              Text('Bar height = workouts per day of month',
                style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SummaryCard(
              valueWidget: AnimatedCountUp(target: totalWorkouts, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFD6A5FF))),
              label: 'Workouts this month',
            ),
            const SizedBox(width: 8),
            _SummaryCard(
              valueWidget: AnimatedCountUp(target: activeDays, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF64D2FF))),
              label: 'Active days',
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Widget valueWidget;
  final String label;

  const _SummaryCard({required this.valueWidget, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressableCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            valueWidget,
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(
              fontSize: 10, color: Color(0xFF8E8E93),
            )),
          ],
        ),
      ),
    );
  }
}
