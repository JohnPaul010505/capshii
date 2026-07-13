import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/providers/auth_provider.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/animations.dart';

final homeDataProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userId = SupabaseClientService().client.auth.currentUser!.id;
  final client = SupabaseClientService().client;

  final profile = ref.watch(authProvider).valueOrNull;
  final today = DateTime.now();
  final weekStart = today.subtract(Duration(days: today.weekday - 1));

  final attendance = await client
      .from('check_ins')
      .select('check_in_time')
      .eq('member_id', userId)
      .gte('check_in_time', weekStart.toIso8601String())
      .lt('check_in_time', weekStart.add(const Duration(days: 7)).toIso8601String());

  final attendanceList = attendance as List;
  final weekCounts = List.generate(7, (i) => 0);
  for (final a in attendanceList) {
    final t = DateTime.parse(a['check_in_time'] as String);
    final day = t.weekday - 1;
    if (day >= 0 && day < 7) weekCounts[day]++;
  }

  final measurements = await client
      .from('body_measurements')
      .select('weight_kg, height_cm')
      .eq('member_id', userId)
      .order('measured_at', ascending: false)
      .limit(1);

  Map<String, dynamic>? latestMeasurement;
  if ((measurements as List).isNotEmpty) {
    latestMeasurement = measurements[0] as Map<String, dynamic>;
  }

  final goals = await client
      .from('goals')
      .select('title')
      .eq('member_id', userId)
      .eq('status', 'active')
      .limit(1);

  final activeGoal = (goals as List).isNotEmpty ? goals[0]['title'] as String? : null;

  final assignment = await client
      .from('trainer_assignments')
      .select('trainer_id')
      .eq('member_id', userId)
      .eq('status', 'active')
      .limit(1);

  Map<String, dynamic>? trainerProfile;
  if ((assignment as List).isNotEmpty) {
    final trainerId = assignment[0]['trainer_id'] as String;
    final trainerResp = await client
        .from('profiles')
        .select('id, full_name, avatar_url')
        .eq('id', trainerId)
        .single();
    trainerProfile = trainerResp as Map<String, dynamic>;
  }

  final membershipResp = await client
      .from('memberships')
      .select('plan_name, end_date, status')
      .eq('member_id', userId)
      .eq('status', 'active')
      .limit(1);

  Map<String, dynamic>? membership;
  if ((membershipResp as List).isNotEmpty) {
    membership = membershipResp[0] as Map<String, dynamic>;
  }

  return {
    'profile': profile,
    'weekCounts': weekCounts,
    'latestMeasurement': latestMeasurement,
    'activeGoal': activeGoal,
    'trainer': trainerProfile,
    'membership': membership,
  };
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(homeDataProvider);
    final profile = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: dataAsync.when(
          data: (data) => HomeContent(data: data, profile: profile),
          loading: () => const _LoadingState(),
          error: (e, _) => _ErrorState(message: e.toString()),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const HomeSkeleton();
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.cloud_download, color: Color(0xFF8E8E93), size: 48),
            const SizedBox(height: 12),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final dynamic profile;

  const HomeContent({super.key, required this.data, this.profile});

  @override
  Widget build(BuildContext context) {
    final weekCounts = data['weekCounts'] as List<int>;
    final latestMeasurement = data['latestMeasurement'] as Map<String, dynamic>?;
    final activeGoal = data['activeGoal'] as String?;
    final trainer = data['trainer'] as Map<String, dynamic>?;
    final membership = data['membership'] as Map<String, dynamic>?;
    final name = profile?.fullName ?? 'there';
    final firstName = name.split(' ').first;
    final initials = name.isNotEmpty ? name.split(' ').map((n) => n[0]).take(2).join() : '?';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    final maxCount = weekCounts.reduce((a, b) => a > b ? a : 1).clamp(1, 100);

    final weight = latestMeasurement?['weight_kg'];
    final height = latestMeasurement?['height_cm'];
    final offset = membership != null ? 1 : 0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      physics: const ClampingScrollPhysics(),
      children: [
        const SizedBox(height: 14),
        _GreetingRow(
          greeting: greeting,
          firstName: firstName,
          initials: initials,
          onAvatarTap: () => context.push('/member/settings'),
        ),
        const SizedBox(height: 12),
        if (membership != null)
          StaggeredFadeIn(index: 0, child: _MembershipCard(membership: membership)),
        if (membership != null) const SizedBox(height: 8),
        StaggeredFadeIn(index: offset, child: _WeekChart(weekCounts: weekCounts, maxCount: maxCount)),
        const SizedBox(height: 8),
        StaggeredFadeIn(index: 1 + offset, child: _StatRow(weight: weight, height: height, activeGoal: activeGoal)),
        const SizedBox(height: 8),
        if (trainer != null) ...[
          StaggeredFadeIn(index: 2 + offset, child: _TrainerCard(trainer: trainer)),
          const SizedBox(height: 8),
        ],
        StaggeredFadeIn(index: 3 + offset, child: _TodayProgress(
          onTapWorkout: () => context.go('/member/workout'),
        )),
        const SizedBox(height: 8),
        StaggeredFadeIn(index: 4 + offset, child: _QuickLogRow(
          onLogWorkout: () => context.go('/member/workout'),
          onLogMeal: () => context.go('/member/meals'),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _GreetingRow extends StatelessWidget {
  final String greeting;
  final String firstName;
  final String initials;
  final VoidCallback onAvatarTap;

  const _GreetingRow({
    required this.greeting,
    required this.firstName,
    required this.initials,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AnimatedPulseDot(),
                const SizedBox(width: 5),
                Text(greeting, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 2),
            Text(firstName, style: Theme.of(context).textTheme.displaySmall?.copyWith(letterSpacing: 0)),
          ],
        ),
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFBF5AF2), Color(0xFFD6A5FF)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(initials, style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
            )),
          ),
        ),
      ],
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final Map<String, dynamic> membership;

  const _MembershipCard({required this.membership});

  @override
  Widget build(BuildContext context) {
    final plan = membership['plan_name'] as String? ?? 'Basic';
    final endDate = membership['end_date'] as String?;
    final status = membership['status'] as String? ?? 'active';
    final formattedDate = endDate != null && endDate.length >= 10
        ? endDate.substring(0, 10)
        : 'N/A';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38383A).withAlpha(100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MEMBERSHIP', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8E8E93), letterSpacing: 0)),
                const SizedBox(height: 3),
                Text(plan, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
                const SizedBox(height: 2),
                Text('Valid until $formattedDate', style: const TextStyle(
                  fontSize: 11, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: status == 'active' ? const Color(0xFF30D158).withAlpha(20) : const Color(0xFFFF9500).withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: status == 'active' ? const Color(0xFF30D158).withAlpha(50) : const Color(0xFFFF9500).withAlpha(50),
              ),
            ),
            child: Text(
              status == 'active' ? 'ACTIVE' : status.toUpperCase(),
              style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: status == 'active' ? const Color(0xFF30D158) : const Color(0xFFFF9500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatefulWidget {
  final List<int> weekCounts;
  final int maxCount;

  const _WeekChart({required this.weekCounts, required this.maxCount});

  @override
  State<_WeekChart> createState() => _WeekChartState();
}

class _WeekChartState extends State<_WeekChart> {
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38383A).withAlpha(100)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This Week',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                  const SizedBox(height: 1),
                  if (_selectedDay != null)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: 1.0,
                      child: Text(
                        '${labels[_selectedDay!]}: ${widget.weekCounts[_selectedDay!]} workout${widget.weekCounts[_selectedDay!] == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFFD6A5FF), fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    const Text('Tap a bar for details',
                      style: TextStyle(fontSize: 10, color: Color(0xFF8E8E93))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFBF5AF2).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBF5AF2).withAlpha(40)),
                ),
                child: const Text('Goal: 5',
                  style: TextStyle(fontSize: 10, color: Color(0xFFD6A5FF), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final count = widget.weekCounts[i];
                final pct = widget.maxCount > 0 ? (count / widget.maxCount) : 0.0;
                final barHeight = (pct * 52).clamp(2.0, 52.0);
                final isToday = i == today;
                final isFuture = i > today;
                final isSelected = i == _selectedDay;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = _selectedDay == i ? null : i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: isSelected ? (barHeight + 6).clamp(2.0, 58.0) : barHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        color: isFuture
                            ? const Color(0xFF8E8E93).withAlpha(30)
                            : isToday
                                ? const Color(0xFF64D2FF)
                                : const Color(0xFF0A84FF),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: List.generate(7, (i) {
              final isToday = i == today;
              return Expanded(
                child: Text(labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w500,
                    color: isToday ? const Color(0xFF64D2FF) : const Color(0xFF8E8E93),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final dynamic weight;
  final dynamic height;
  final String? activeGoal;

  const _StatRow({this.weight, this.height, this.activeGoal});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: CupertinoIcons.info_circle,
          iconBg: const Color(0xFFBF5AF2).withAlpha(25),
          iconColor: const Color(0xFFD6A5FF),
          valueWidget: weight != null
              ? AnimatedCountUp(target: (weight is int ? weight : (weight as double).round()), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF)))
              : const Text('--', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
          label: 'kg \u00b7 Weight',
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: CupertinoIcons.gear,
          iconBg: const Color(0xFF0A84FF).withAlpha(25),
          iconColor: const Color(0xFF0A84FF),
          valueWidget: height != null
              ? AnimatedCountUp(target: (height is int ? height : (height as double).round()), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF)))
              : const Text('--', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
          label: 'cm \u00b7 Height',
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: CupertinoIcons.flag,
          iconBg: const Color(0xFF30D158).withAlpha(25),
          iconColor: const Color(0xFF30D158),
          valueWidget: Text(activeGoal?.split(' ').first ?? '--', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
          label: 'Goal',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Widget valueWidget;
  final String label;

  const _StatCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.valueWidget, required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressableCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                valueWidget,
                Text(label, style: const TextStyle(
                  fontSize: 9, color: Color(0xFF636366),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  final Map<String, dynamic> trainer;

  const _TrainerCard({required this.trainer});

  @override
  Widget build(BuildContext context) {
    final name = trainer['full_name'] as String? ?? 'Your Trainer';
    final initials = name.split(' ').map((n) => n[0]).take(2).join();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38383A).withAlpha(100)),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFBF5AF2), Color(0xFFD6A5FF)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(initials, style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
                    )),
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 11, height: 11,
                      decoration: const BoxDecoration(
                        color: Color(0xFF30D158),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF),
                    )),
                    const SizedBox(height: 1),
                    const Text('Your Trainer', style: TextStyle(
                      fontSize: 11, color: Color(0xFF8E8E93),
                    )),
                    const SizedBox(height: 3),
                    const Row(
                      children: [_StarRow()],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/member/chat'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A84FF),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: const Text('Message', style: TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Tap to send a message to your trainer',
            child: GestureDetector(
              onTap: () => context.go('/member/chat'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0A84FF).withAlpha(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.chat_bubble_2_fill, color: Color(0xFF64B5FF), size: 13),
                    const SizedBox(width: 5),
                    Text('Ask a question', style: const TextStyle(
                      fontSize: 11, color: Color(0xFF64B5FF), fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < 4 ? CupertinoIcons.star_fill : CupertinoIcons.star_lefthalf_fill,
          color: const Color(0xFFFF9500), size: 10,
        );
      }),
    );
  }
}

class _TodayProgress extends StatelessWidget {
  final VoidCallback onTapWorkout;

  const _TodayProgress({required this.onTapWorkout});

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTapWorkout,
      padding: const EdgeInsets.all(14),
      color: const Color(0xFF2C2C2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.arrow_up_right, color: Color(0xFFD6A5FF), size: 13),
              const SizedBox(width: 5),
              Text("Today's Progress", style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          _ProgressBarRow(
            icon: CupertinoIcons.flame,
            iconColor: const Color(0xFFFF453A),
            label: 'Calories Burned',
            value: '0 / 500 kcal',
            progress: 0.0,
            barColor: const Color(0xFFFF453A),
          ),
          const SizedBox(height: 13),
          _ProgressBarRow(
            icon: CupertinoIcons.clock,
            iconColor: const Color(0xFFBF5AF2),
            label: 'Workout Time',
            value: '0 / 60 min',
            progress: 0.0,
            barColor: const Color(0xFFBF5AF2),
          ),
        ],
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final double progress;
  final Color barColor;

  const _ProgressBarRow({
    required this.icon, required this.iconColor, required this.label,
    required this.value, required this.progress, required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: iconColor),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(
                  fontSize: 11, color: Color(0xFF636366),
                )),
              ],
            ),
            Text(value, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: barColor,
            )),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF38383A),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickLogRow extends StatelessWidget {
  final VoidCallback onLogWorkout;
  final VoidCallback onLogMeal;

  const _QuickLogRow({required this.onLogWorkout, required this.onLogMeal});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickCard(
            icon: CupertinoIcons.person,
            title: 'Log Workout',
            subtitle: 'Track your exercise',
            onTap: onLogWorkout,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickCard(
            icon: CupertinoIcons.gear,
            title: 'Log Meal',
            subtitle: 'Track your nutrition',
            onTap: onLogMeal,
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
  });

  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, __) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: GestureDetector(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse(),
            onTapCancel: () => _controller.reverse(),
            onTap: widget.onTap,
            child: Semantics(
              label: '${widget.title} — ${widget.subtitle}',
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF).withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0A84FF).withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A84FF),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.title, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF),
                    )),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: const TextStyle(
                      fontSize: 10, color: Color(0xFF8E8E93),
                    )),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
