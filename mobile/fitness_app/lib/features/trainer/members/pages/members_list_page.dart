import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/models/profile.dart';
import 'package:shared/services/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';

final assignedMembersProvider = FutureProvider<List<Profile>>((ref) async {
  final client = SupabaseClientService().client;
  final userId = client.auth.currentUser!.id;
  final response = await client
      .from('trainer_assignments')
      .select('profiles!trainer_assignments_member_id_fkey(*)')
      .eq('trainer_id', userId)
      .eq('status', 'active');
  return (response as List)
      .map((e) => Profile.fromJson(e['profiles'] as Map<String, dynamic>))
      .toList();
});

class MembersListPage extends ConsumerWidget {
  const MembersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(assignedMembersProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text('My Members',
                style: sfText(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary, letterSpacing: 0.38)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.person_2, color: CupertinoAppColors.textTertiary, size: 48),
                          SizedBox(height: 12),
                          Text('No assigned members yet', style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textQuaternary, letterSpacing: -0.08)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => Container(
                      height: 0.5,
                      color: CupertinoAppColors.separator.withAlpha(100),
                      margin: const EdgeInsets.only(left: 60),
                    ),
                    itemBuilder: (_, i) {
                      final member = members[i];
                      return GestureDetector(
                        onTap: () => context.push('/trainer/members/${member.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: CupertinoAppColors.cardElevated,
                                ),
                                alignment: Alignment.center,
                                child: Text(member.fullName[0], style: sfText(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member.fullName, style: sfText(fontSize: 15, fontWeight: FontWeight.w500, color: CupertinoAppColors.textPrimary, letterSpacing: -0.24)),
                                    Text(member.email, style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textTertiary, letterSpacing: -0.08)),
                                  ],
                                ),
                              ),
                              const Icon(CupertinoIcons.chevron_forward, color: CupertinoAppColors.textTertiary, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator(radius: 14, color: CupertinoAppColors.primaryBlue)),
                error: (e, _) => Center(child: Text('Error: $e', style: sfText(fontSize: 12, fontWeight: FontWeight.w400, color: CupertinoAppColors.textQuaternary))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
